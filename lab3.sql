CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

INSERT INTO employees (first_name, last_name, department)
VALUES
    ('Айгүл', 'Сәтбаева', 'IT'),
    ('Қанат', 'Жүнісов', 'HR'),
    ('Алия', 'Қасымова', 'Finance');

INSERT INTO employees (first_name, last_name, department, hire_date, salary, status)
VALUES
    ('Мәди', 'Оралбай', 'Marketing', '2024-01-15', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget)
VALUES
    ('IT', 500000),
    ('HR', 200000),
    ('Finance', 300000),
    ('Marketing', 150000);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Нұрлан', 'Сағатов', 'Sales', 50000 * 1.1, CURRENT_DATE);

CREATE TEMPORARY TABLE temp_employees AS
SELECT * FROM employees WHERE 1 = 0;

INSERT INTO temp_employees
SELECT * FROM employees WHERE department = 'IT';

UPDATE employees
SET salary = salary * 1.10
WHERE salary IS NOT NULL;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
AND hire_date < '2020-01-01';

UPDATE employees
SET department =
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END
WHERE salary IS NOT NULL;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (
    SELECT AVG(salary) * 1.20
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE dept_name IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'IT';

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
AND hire_date > '2023-01-01'
AND department IS NULL;

DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT dept_id
    FROM departments d
    WHERE EXISTS (
        SELECT 1
        FROM employees e
        WHERE e.department = d.dept_name
    )
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, salary, department, hire_date)
VALUES ('Нұрбол', 'Қалиев', NULL, NULL, CURRENT_DATE);

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
OR department IS NULL;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Айгерім', 'Тәжібаева', 'IT', 55000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Аслан', 'Жақыпов', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees
    WHERE first_name = 'Аслан' AND last_name = 'Жақыпов'
);

UPDATE employees
SET salary = CASE
    WHEN department IN (
        SELECT dept_name FROM departments WHERE budget > 100000
    ) THEN salary * 1.10
    ELSE salary * 1.05
    END
WHERE salary IS NOT NULL;

INSERT INTO employees (first_name, last_name, department, salary) VALUES
    ('Дина', 'Оразбаева', 'HR', 45000),
    ('Ерлан', 'Сапарбеков', 'IT', 65000),
    ('Гүлназ', 'Исаева', 'Finance', 55000),
    ('Бауыржан', 'Кенжеев', 'Marketing', 48000),
    ('Сания', 'Мұратқызы', 'IT', 62000);

UPDATE employees
SET salary = salary * 1.10
WHERE first_name IN ('Дина', 'Ерлан', 'Гүлназ', 'Бауыржан', 'Сания')
AND last_name IN ('Оразбаева', 'Сапарбеков', 'Исаева', 'Кенжеев', 'Мұратқызы');

CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE 1 = 0;

INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
AND start_date < CURRENT_DATE
AND (end_date IS NULL OR end_date > CURRENT_DATE);