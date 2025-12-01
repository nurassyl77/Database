BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
COMMIT;

BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

BEGIN;

-- Check balance
SELECT balance INTO temp_balance FROM accounts WHERE name = 'Bob';

IF temp_balance >= 200 THEN
    UPDATE accounts SET balance = balance - 200 WHERE name = 'Bob';
    UPDATE accounts SET balance = balance + 200 WHERE name = 'Wally';
    COMMIT;
ELSE
    ROLLBACK;
END IF;

BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Tea', 1.50);
SAVEPOINT s1;

UPDATE products SET price = 2.00 WHERE product = 'Tea';
SAVEPOINT s2;

DELETE FROM products WHERE product = 'Tea';

ROLLBACK TO s1;

COMMIT;
