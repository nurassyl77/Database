-- 1. customers кестесі
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL CHECK (iin ~ '^\d{12}$'),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(255) UNIQUE,
    status VARCHAR(10) NOT NULL CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt NUMERIC(18, 2) NOT NULL DEFAULT 500000.00
);

-- 2. accounts кестесі
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    account_number CHAR(20) UNIQUE NOT NULL,
    currency CHAR(3) NOT NULL CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance NUMERIC(18, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0.00),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITHOUT TIME ZONE
);

-- 3. exchange_rates кестесі
CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate NUMERIC(10, 6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITHOUT TIME ZONE
);

CREATE UNIQUE INDEX idx_unique_active_rate ON exchange_rates (from_currency, to_currency)
WHERE valid_to IS NULL;

-- 4. transactions кестесі
CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    from_account_id INTEGER REFERENCES accounts(account_id),
    to_account_id INTEGER REFERENCES accounts(account_id),
    amount NUMERIC(18, 2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL,
    exchange_rate NUMERIC(10, 6),
    amount_kzt NUMERIC(18, 2),
    type VARCHAR(15) NOT NULL CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(15) NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITHOUT TIME ZONE,
    description VARCHAR(255)
);

-- 5. audit_log кестесі (JSONB қолданылған)
CREATE TABLE audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'TRANSFER_FAIL')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    changed_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('010101100001', 'Әли Қазақбаев', '77011234567', 'ali.k@email.kz', 'active', 1000000.00),
('020202100002', 'Мәдина Сәлімқызы', '77779876543', 'madina.s@email.kz', 'active', 500000.00),
('030303100003', 'Айдос Нұрланұлы', '77055432109', 'aidos.n@email.kz', 'blocked', 500000.00),
('040404100004', 'Самал Ержанқызы', '77001112233', 'samal.e@email.kz', 'active', 2000000.00);

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ10722S000001234567', 'KZT', 5000000.00),
(1, 'KZ10722S000001234568', 'USD', 10000.00),
(2, 'KZ10722S000002234567', 'KZT', 50000.00),
(2, 'KZ10722S000002234568', 'EUR', 500.00),
(4, 'KZ10722S000004234567', 'KZT', 15000000.00);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_to) VALUES
('USD', 'KZT', 460.00, NULL),
('EUR', 'KZT', 500.00, NULL),
('RUB', 'KZT', 5.00, NULL),
('KZT', 'USD', 0.00217, NULL);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, description, completed_at) VALUES
(1, 2, 50000.00, 'KZT', 50000.00, 'transfer', 'completed', 'Кешегі аударым', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(1, 4, 100000.00, 'KZT', 100000.00, 'transfer', 'completed', 'Бүгінгі 1-ші аударым', CURRENT_TIMESTAMP - INTERVAL '1 hour');

INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by) VALUES
('customers', 1, 'INSERT', '{"status": "active"}', 'sysadmin');

-- ТАПСЫРМА 1: process_transfer сақталған процедурасы
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_account_number CHAR(20),
    p_to_account_number CHAR(20),
    p_amount NUMERIC(18, 2),
    p_currency CHAR(3),
    p_description VARCHAR(255),
    p_ip_address INET DEFAULT '127.0.0.1'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_acc accounts%ROWTYPE;
    v_to_acc accounts%ROWTYPE;
    v_exchange_rate NUMERIC(10, 6) := 1.0;
    v_amount_kzt NUMERIC(18, 2);
    v_transfer_id BIGINT;
    v_daily_spent NUMERIC(18, 2);
    v_error_message VARCHAR(255);
    v_error_code CHAR(5) := '50000';
BEGIN
    -- 1. Транзакцияны бастау және бастапқы аударымды тіркеу
    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, description, type, status)
    VALUES (NULL, NULL, p_amount, p_currency, p_description, 'transfer', 'pending')
    RETURNING transaction_id INTO v_transfer_id;

    SAVEPOINT sp_transfer_validation;

    -- 2. Шоттарды SELECT ... FOR UPDATE арқылы құлыптау және тексеру
    BEGIN
        SELECT * INTO v_from_acc FROM accounts WHERE account_number = p_from_account_number AND is_active = TRUE FOR UPDATE;
        SELECT * INTO v_to_acc FROM accounts WHERE account_number = p_to_account_number AND is_active = TRUE FOR UPDATE;

        IF NOT FOUND THEN
            IF v_from_acc IS NULL THEN
                v_error_message := 'Source account not found or inactive.';
                v_error_code := 'A0001';
                RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
            ELSIF v_to_acc IS NULL THEN
                v_error_message := 'Destination account not found or inactive.';
                v_error_code := 'A0002';
                RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
            END IF;
        END IF;
    END;

    -- 3. Клиент статусын тексеру
    IF (SELECT status FROM customers WHERE customer_id = v_from_acc.customer_id) <> 'active' THEN
        v_error_message := 'Sender customer is not active (blocked or frozen).';
        v_error_code := 'C0001';
        RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
    END IF;

    -- 4. Валюта айырбастау курсын анықтау
    IF v_from_acc.currency <> p_currency THEN
        v_error_message := 'Transfer currency must match sender account currency.';
        v_error_code := 'V0001';
        RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
    END IF;

    IF v_from_acc.currency <> v_to_acc.currency THEN
        SELECT rate INTO v_exchange_rate FROM exchange_rates
        WHERE from_currency = v_from_acc.currency AND to_currency = v_to_acc.currency AND valid_to IS NULL;

        IF NOT FOUND THEN
            v_error_message := 'Exchange rate not found for ' || v_from_acc.currency || ' to ' || v_to_acc.currency;
            v_error_code := 'V0002';
            RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
        END IF;
    END IF;

    -- 5. KZT-ге аударылған соманы есептеу (Лимитті тексеру үшін)
    IF v_from_acc.currency = 'KZT' THEN
        v_amount_kzt := p_amount;
    ELSE
        SELECT rate INTO v_exchange_rate FROM exchange_rates
        WHERE from_currency = v_from_acc.currency AND to_currency = 'KZT' AND valid_to IS NULL;
        IF NOT FOUND THEN
            v_error_message := 'Exchange rate to KZT not found for daily limit check.';
            v_error_code := 'V0003';
            RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
        END IF;
        v_amount_kzt := p_amount * v_exchange_rate;
    END IF;

    -- 6. Күнделікті лимитті тексеру
    SELECT COALESCE(SUM(amount_kzt), 0) INTO v_daily_spent
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    WHERE a.customer_id = v_from_acc.customer_id
      AND t.status = 'completed'
      AND t.created_at::DATE = CURRENT_DATE;

    IF v_daily_spent + v_amount_kzt > (SELECT daily_limit_kzt FROM customers WHERE customer_id = v_from_acc.customer_id) THEN
        v_error_message := 'Daily transaction limit exceeded for customer.';
        v_error_code := 'L0001';
        RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
    END IF;

    -- 7. Қалдықты тексеру
    IF v_from_acc.balance < p_amount THEN
        v_error_message := 'Insufficient balance in source account.';
        v_error_code := 'B0001';
        RAISE EXCEPTION USING MESSAGE = v_error_message, SQLSTATE = v_error_code;
    END IF;

    -- 8. Баланстарды жаңарту
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_acc.account_id;
    UPDATE accounts SET balance = balance + (p_amount * v_exchange_rate) WHERE account_id = v_to_acc.account_id;

    -- 9. Транзакция жазбасын жаңарту
    UPDATE transactions SET
        from_account_id = v_from_acc.account_id,
        to_account_id = v_to_acc.account_id,
        exchange_rate = v_exchange_rate,
        amount_kzt = v_amount_kzt,
        status = 'completed',
        completed_at = CURRENT_TIMESTAMP
    WHERE transaction_id = v_transfer_id;

    -- 10. Аудит Журналына енгізу
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, ip_address)
    VALUES ('transactions', v_transfer_id, 'INSERT', jsonb_build_object('status', 'completed'), CURRENT_USER, p_ip_address);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_transfer_validation;
        GET STACKED DIAGNOSTICS
            v_error_message = MESSAGE_TEXT,
            v_error_code = RETURNED_SQLSTATE;
        UPDATE transactions SET status = 'failed', completed_at = CURRENT_TIMESTAMP, description = p_description || ' (FAILED: ' || v_error_message || ')'
        WHERE transaction_id = v_transfer_id;
        INSERT INTO audit_log (table_name, record_id, action, old_values, changed_by, ip_address)
        VALUES ('transactions', v_transfer_id, 'TRANSFER_FAIL', jsonb_build_object('error_code', v_error_code, 'message', v_error_message), CURRENT_USER, p_ip_address);
        RAISE EXCEPTION '[Code: %] Transfer failed: %', v_error_code, v_error_message;
        COMMIT;
END;
$$;

CREATE OR REPLACE VIEW customer_balance_summary AS
WITH customer_total AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.daily_limit_kzt,
        a.account_number,
        a.currency,
        a.balance,
        -- KZT-ге айырбастау
        a.balance * COALESCE((
            SELECT rate
            FROM exchange_rates
            WHERE from_currency = a.currency AND to_currency = 'KZT' AND valid_to IS NULL
        ), 1) AS balance_kzt
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
),
daily_spent AS (
    SELECT
        c.customer_id,
        COALESCE(SUM(t.amount_kzt), 0) AS total_spent_today
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.from_account_id
        AND t.status = 'completed'
        AND t.created_at::DATE = CURRENT_DATE
    GROUP BY c.customer_id
)
SELECT
    ct.full_name,
    ct.account_number,
    ct.currency,
    ct.balance,
    ct.balance_kzt,
    SUM(ct.balance_kzt) OVER (PARTITION BY ct.customer_id) AS total_balance_kzt,
    ds.total_spent_today,
    (ds.total_spent_today / ct.daily_limit_kzt) * 100 AS limit_utilization_percent,
    RANK() OVER (ORDER BY SUM(ct.balance_kzt) OVER (PARTITION BY ct.customer_id) DESC) AS total_balance_rank
FROM customer_total ct
JOIN daily_spent ds ON ct.customer_id = ds.customer_id;

CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily_agg AS (
    SELECT
        t.created_at::DATE AS transaction_date,
        t.type,
        COUNT(*) AS transaction_count,
        SUM(t.amount_kzt) AS total_volume_kzt,
        AVG(t.amount_kzt) AS average_amount_kzt
    FROM transactions t
    WHERE t.status = 'completed' AND t.amount_kzt IS NOT NULL
    GROUP BY 1, 2
)
SELECT
    da.transaction_date,
    da.type,
    da.transaction_count,
    da.total_volume_kzt,
    da.average_amount_kzt,
    SUM(da.total_volume_kzt) OVER (ORDER BY da.transaction_date, da.type) AS running_total_kzt,
    LAG(da.total_volume_kzt, 1, 0) OVER (PARTITION BY da.type ORDER BY da.transaction_date) AS previous_day_volume,
    (da.total_volume_kzt - LAG(da.total_volume_kzt, 1, 0) OVER (PARTITION BY da.type ORDER BY da.transaction_date)) / NULLIF(LAG(da.total_volume_kzt, 1, 0) OVER (PARTITION BY da.type ORDER BY da.transaction_date), 0) * 100 AS day_over_day_growth_percent
FROM daily_agg da
ORDER BY transaction_date, type;

CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
WITH high_value AS (
    -- 5,000,000 KZT-ден асатын аударымдарды белгілеу
    SELECT
        transaction_id,
        'High_Value_Transfer' AS flag_reason,
        created_at,
        from_account_id,
        to_account_id
    FROM transactions
    WHERE amount_kzt > 5000000.00 AND status = 'completed' AND type = 'transfer'
),
high_frequency AS (
    SELECT
        t1.transaction_id,
        'High_Frequency_Hourly' AS flag_reason,
        t1.created_at,
        t1.from_account_id,
        t1.to_account_id
    FROM transactions t1
    JOIN accounts a ON t1.from_account_id = a.account_id
    WHERE t1.status = 'completed' AND EXISTS (
        SELECT 1
        FROM transactions t2
        JOIN accounts a2 ON t2.from_account_id = a2.account_id
        WHERE a2.customer_id = a.customer_id
          AND t2.status = 'completed'
          AND t2.created_at BETWEEN t1.created_at - INTERVAL '1 hour' AND t1.created_at + INTERVAL '1 hour'
        GROUP BY a2.customer_id
        HAVING COUNT(*) > 10
    )
),
rapid_sequence AS (
    SELECT
        t.transaction_id,
        'Rapid_Sequential_Transfer' AS flag_reason,
        t.created_at,
        t.from_account_id,
        t.to_account_id
    FROM transactions t
    WHERE t.status = 'completed' AND EXISTS (
        SELECT 1
        FROM transactions t_prev
        WHERE t_prev.from_account_id = t.from_account_id
          AND t_prev.transaction_id < t.transaction_id
          AND t.created_at - t_prev.created_at < INTERVAL '1 minute'
        LIMIT 1
    )
)
SELECT * FROM high_value
UNION ALL
SELECT * FROM high_frequency
UNION ALL
SELECT * FROM rapid_sequence;

-- ТАПСЫРМА 4: process_salary_batch сақталған процедурасы
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number CHAR(20),
    p_payments JSONB,
    p_ip_address INET DEFAULT '127.0.0.1'
)
RETURNS TABLE (successful_count INTEGER, failed_count INTEGER, failed_details JSONB)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_acc accounts%ROWTYPE;
    v_total_batch_amount NUMERIC(18, 2) := 0.0;
    v_payment JSONB;
    v_receiver_iin CHAR(12);
    v_amount NUMERIC(18, 2);
    v_description VARCHAR(255);
    v_receiver_acc accounts%ROWTYPE;
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_failed_details JSONB[] := ARRAY[]::JSONB[];
    v_current_tx_id BIGINT;
    v_lock_id BIGINT;
    v_sql_state TEXT;
    v_error_message TEXT;
    v_payment_id INTEGER := 0;
BEGIN
    -- 0. Кеңесші құлыптауды орнату
    v_lock_id := hashtext(p_company_account_number);
    IF NOT pg_try_advisory_xact_lock(v_lock_id) THEN
        RAISE EXCEPTION 'Batch process for company % is already running.', p_company_account_number;
    END IF;

    -- 1. Компания шотын алу және құлыптау
    SELECT * INTO v_company_acc FROM accounts WHERE account_number = p_company_account_number AND is_active = TRUE AND currency = 'KZT' FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Company account not found, inactive, or not KZT.';
    END IF;

    -- 2. Жалпы соманы есептеу
    SELECT COALESCE(SUM((elem->>'amount')::NUMERIC), 0) INTO v_total_batch_amount
    FROM jsonb_array_elements(p_payments) AS elem;

    -- 3. Жалпы пакет сомасын тексеру
    IF v_company_acc.balance < v_total_batch_amount THEN
        RAISE EXCEPTION 'Insufficient balance in company account. Total needed: %', v_total_batch_amount;
    END IF;

    -- 4. Әрбір төлемді өңдеу
    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        v_payment_id := v_payment_id + 1;
        v_receiver_iin := v_payment->>'iin';
        v_amount := (v_payment->>'amount')::NUMERIC;
        v_description := v_payment->>'description';
        v_current_tx_id := NULL;

        BEGIN
            -- Пакеттік төлемдер бір транзакцияда өңделеді, бірақ жеке SAVEPOINT қолданады
            SAVEPOINT sp_payment;

            -- Төлемді қабылдаушыны табу
            SELECT a.* INTO v_receiver_acc
            FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            WHERE c.iin = v_receiver_iin AND a.currency = 'KZT' AND a.is_active = TRUE
            LIMIT 1 FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Receiver IIN % account not found or inactive (must be KZT).', v_receiver_iin;
            END IF;

            -- Транзакцияны енгізу
            INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, description, completed_at)
            VALUES (v_company_acc.account_id, v_receiver_acc.account_id, v_amount, 'KZT', v_amount, 'transfer', 'completed', v_description || ' (Salary Batch)', CURRENT_TIMESTAMP)
            RETURNING transaction_id INTO v_current_tx_id;

            -- Баланстарды жаңарту
            UPDATE accounts SET balance = balance - v_amount WHERE account_id = v_company_acc.account_id;
            UPDATE accounts SET balance = balance + v_amount WHERE account_id = v_receiver_acc.account_id;

            v_success_count := v_success_count + 1;

            -- Аудит Журналына енгізу
            INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, ip_address)
            VALUES ('transactions', v_current_tx_id, 'INSERT', jsonb_build_object('status', 'completed', 'iin', v_receiver_iin), CURRENT_USER, p_ip_address);

        EXCEPTION
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    v_sql_state = RETURNED_SQLSTATE,
                    v_error_message = MESSAGE_TEXT;

                -- Қате болған жағдайда, жеке төлемді кері қайтару
                ROLLBACK TO sp_payment;

                -- Сәтсіздіктер тізімін толтыру
                v_failed_details := array_append(v_failed_details, jsonb_build_object(
                    'iin', v_receiver_iin,
                    'amount', v_amount,
                    'error_code', v_sql_state,
                    'message', v_error_message
                ));
                v_failed_count := v_failed_count + 1;

                -- Аудит Журналына енгізу (Сәтсіз әрекет)
                INSERT INTO audit_log (table_name, record_id, action, old_values, changed_by, ip_address)
                VALUES ('salary_batch', v_payment_id, 'TRANSFER_FAIL', jsonb_build_object('iin', v_receiver_iin, 'error', v_error_message), CURRENT_USER, p_ip_address);
        END;
    END LOOP;

    -- 5. Жалақы пакетінің қорытынды есебі
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, ip_address)
    VALUES ('salary_batch', NULL, 'UPDATE', jsonb_build_object('company_account', p_company_account_number, 'success', v_success_count, 'failed', v_failed_count), CURRENT_USER, p_ip_address);

    RETURN QUERY SELECT v_success_count, v_failed_count, to_jsonb(v_failed_details);
    COMMIT;
END;
$$;

CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
    t.created_at::DATE AS batch_date,
    c.full_name AS company_name,
    COUNT(t.transaction_id) AS total_payments,
    SUM(t.amount) AS total_amount_kzt
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.description LIKE '%(Salary Batch)%'
GROUP BY 1, 2
ORDER BY 1 DESC
WITH DATA;

-- Материалдандырылған көріністі жаңарту процедурасы
CREATE OR REPLACE PROCEDURE refresh_salary_batch_summary()
LANGUAGE sql
AS $$
    REFRESH MATERIALIZED VIEW salary_batch_summary;
$$;