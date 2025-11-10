DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;

--PART 1

--step 1.1
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);
CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);

--step 1.2
INSERT INTO employees(emp_id, emp_name, dept_id, salary) VALUES
                                                               (1,'John Smith', 101, 50000),
                                                               (2, 'John Doe', 102, 60000),
                                                               (3,'Mike Johnson', 101, 55000),
                                                               (4, 'Sarah Williams', 103, 65000),
                                                               (5, 'Tom Brown', NULL, 45000);
INSERT INTO departments(dept_id, dept_name, location) VALUES
                                                               (101,'IT', 'Bulding A'),
                                                               (102, 'HR', 'Bulding B'),
                                                               (103,'Finance', 'Bulding C'),
                                                               (104, 'Marketing', 'Bulding D');
INSERT INTO projects(project_id, project_name, dept_id, budget) VALUES
                                                               (1,'Website Redesign', 101, 100000),
                                                               (2, 'Employee Training', 10, 50000),
                                                               (3,'Budget Analysis', 103, 75000),
                                                               (4, 'Cloud Migration', 101, 150000),
                                                               (5,'AI Research', NULL, 200000);

--task 2.1
CREATE VIEW employee_details AS;
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM
    employee e
JOIN
        departaments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

--task 2.2
CREATE OR REPLACE VIEW dept_statistics AS
       SELECT
           d.dept_name,
           COUNT(e.emp_id) AS employee_count,
           AVG(e.salary) AS avg_salary,
           MAX(e.salary) AS max_salary,
           MIN(e.salary) AS min_salary
       FROM departaments d
       LEFT JOIN employees e ON d.dept_id = e.dept_id
       GROUP BY d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

--task 2.3
CREATE OR REPLACE VIEW project_overview AS
       SELECT
           p.project_name,
           p.budget,
           d.dept_name,
           d.location,
           COUNT(e,emp_id) AS team_size
       FROM projects p
    JOIN departaments d ON p.dept_id = d.dept_id
    LEFT JOIN employees e ON d.dept_id = e.dept_id
    GROUP BY p.project_name, p.budget, d.dept_name, d.location;

SELECT * FROM projects_overview;

--task 2.4
CREATE VIEW high_earners AS
SELECT e.salary, e.emp_name, d.dept_name
FROM employees e
    JOIN departments d on e.dept_id = d.dept_id
WHERE e.salary >50000;

--task 3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
        END AS salary_grade
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id;

--task 3.2
ALTER VIEW high_earners
RENAME TO top_performers;

SELECT * FROM top_performers;

--task 3.3
CREATE VIEW temp_view AS
    SELECT e.salary
    FROM employees e
    WHERE e.salary <50000;
DROP VIEW temp_view;

--task 4.1
CREATE VIEW employee_salaries AS
SELECT e.emp_id,e.emp_name,e.dept_id, e.salary
FROM employees e;

--task 4.2

UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';
--task 4.3
 INSERT INTO employee_salaries(emp_id, emp_name, dept_id, salary) VALUES
(6,'Alice Johnson',102,58000);

--task 4.4
CREATE VIEW it_employees AS
SELECT
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees
WHERE dept_id = 101
        WITH LOCAL CHECK OPTION;

--task 5.1
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,d.dept_name,
       COUNT(e.emp_id) AS total_employees,
       COALESCE(SUM(e.salary),0) AS total_salaries,
       COUNT(p.project_id) AS total_projects,
       COALESCE(SUM(p.budget),0) AS total_budget
FROM departments d
LEFT JOIN employees e on d.dept_id = e.dept_id
LEFT JOIN projects p on d.dept_id = p.dept_id
GROUP BY d.dept_id,d.dept_name
WITH DATA ;
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

--task 5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);
SELECT * FROM dept_summary_mv ORDER BY dept_id;
REFRESH MATERIALIZED VIEW dept_summary_mv;
SELECT * FROM dept_summary_mv ORDER BY dept_id;

--task 5.3
CREATE UNIQUE INDEX idx_dept_summary_mv_id
    ON dept_summary_mv (dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

--task 5.4
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS employee_count
FROM projects p
         LEFT JOIN departments d ON p.dept_id = d.dept_id
         LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_name, p.budget, d.dept_name
WITH NO DATA;

REFRESH MATERIALIZED VIEW project_stats_mv;
SELECT * FROM project_stats_mv;

--task 6.1
CREATE ROLE analyst;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user WITH password 'report456';

--task 6.2
CREATE ROLE db_creator LOGIN PASSWORD 'creator789' CREATEDB ;
CREATE ROLE user_manager LOGIN PASSWORD 'manager101' CREATEROLE ;
CREATE ROLE admin_user LOGIN PASSWORD 'admin999' SUPERUSER ;
--task 6.3
GRANT SELECT ON employees, departments, projects TO analyst;

GRANT ALL PRIVILEGES ON employee_details TO data_viewer;

GRANT SELECT, INSERT ON employees TO report_user;
--task 6.4
-- 1. Create group roles
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

-- 2. Create individual users
CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';

-- 3. Assign users to groups
GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

-- 4. Give privileges
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

--task 6.5
REVOKE UPDATE ON employees FROM hr_team;

REVOKE hr_team FROM hr_user2;

REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

--task 6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';

ALTER ROLE user_manager WITH SUPERUSER;

ALTER ROLE analyst WITH PASSWORD NULL;

ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

--task 7.1
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public to read_only;
CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';
GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

--task 7.2
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

--task 7.3
-- 1. Создаём временную роль
CREATE ROLE temp_owner LOGIN;

-- 2. Создаём таблицу
CREATE TABLE temp_table (id INT);

-- 3. Передаём таблицу temp_owner
ALTER TABLE temp_table OWNER TO temp_owner;

-- 4. Переназначаем все объекты postgres
REASSIGN OWNED BY temp_owner TO postgres;

-- 5. Удаляем объекты и роль
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

--task 7.4
-- 1. HR view
CREATE VIEW hr_employee_view AS
SELECT * FROM employees WHERE dept_id = 102;

-- 2. Доступ только HR
GRANT SELECT ON hr_employee_view TO hr_team;

-- 3. Finance view
CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary FROM employees;

-- 4. Доступ только Finance
GRANT SELECT ON finance_employee_view TO finance_team;

--task 8.1
CREATE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    COUNT(DISTINCT p.project_id) AS project_count,
    SUM(p.budget) AS total_budget,
    ROUND(
            COALESCE(SUM(p.budget) / NULLIF(COUNT(DISTINCT e.emp_id), 0), 0),
            2
    ) AS budget_per_employee
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
         LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name, d.location;

--task 8.2
-- 1. Add column if it doesn't exist
ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 2. Create the audit view
CREATE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
        END AS approval_status
FROM projects p
         JOIN departments d ON p.dept_id = d.dept_id;

--task 8.3
-- 1. Create base roles
CREATE ROLE viewer_role;
CREATE ROLE entry_role;
CREATE ROLE analyst_role;
CREATE ROLE manager_role;

-- 2. Grant inheritance (role hierarchy)
GRANT viewer_role TO entry_role;
GRANT entry_role TO analyst_role;
GRANT analyst_role TO manager_role;

-- 3. Grant privileges
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT INSERT ON employees, projects TO entry_role;
GRANT UPDATE ON employees, projects TO analyst_role;
GRANT DELETE ON employees, projects TO manager_role;

-- 4. Create users
CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';

-- 5. Assign users to roles
GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;