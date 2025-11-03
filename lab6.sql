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
--PART 2

--step 2.1
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;

--step 2.2
--a
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;
--b
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

--step 2.3
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;


--PART 3

--step 3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

--step 3.2
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

--step 3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

--step 3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;


--PART 4

--step 4.1
SELECT e.emp_name,
       e.dept_id AS emp_dept,
       d.dept_id AS dept_dept,
       d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

--step 4.2
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

--step 4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

--step 4.4
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


--PART 5

--step 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

--step 5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

--step 5.3
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;


--PART 6

--step 6.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
-- NULL on left = departments without employees, NULL on right = employees without departments.

--step 6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

--step 6.3
SELECT
  CASE
    WHEN e.emp_id IS NULL THEN 'Department without employees'
    WHEN d.dept_id IS NULL THEN 'Employee without department'
    ELSE 'Matched'
  END AS record_status,
  e.emp_name,
  d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

--PART 7

--step 7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

--step 7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- In Query1, all employees appear; in Query2, only those in Building A.

--PART 8

SELECT d.dept_name, e.emp_name, e.salary, p.project_name, p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id IN (1,2,4,5);
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;

SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

--Lab Questions
-- 1) Difference between INNER and LEFT JOIN: INNER returns only matching rows, LEFT returns all from the left.
-- 2) Use CROSS JOIN to generate combinations (e.g., employee × project schedules).
-- 3) ON vs WHERE matters for outer joins because WHERE filters after joining.
-- 4) SELECT COUNT(*) FROM table1 CROSS JOIN table2 → N×M rows.
-- 5) NATURAL JOIN uses all columns with same names.
-- 6) Risks: NATURAL JOIN may break if schema changes.
-- 7) LEFT JOIN equivalent to RIGHT JOIN by swapping table order.
-- 8) Use FULL JOIN when you need all records from both tables.

--Additional Challenges
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
UNION
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM departments d
RIGHT JOIN employees e ON d.dept_id = e.dept_id;

SELECT DISTINCT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN (
  SELECT dept_id FROM projects WHERE dept_id IS NOT NULL GROUP BY dept_id HAVING COUNT(*) > 1
) p2 ON d.dept_id = p2.dept_id;

SELECT e.emp_name AS employee, m.emp_name AS manager, mm.emp_name AS manager_of_manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
LEFT JOIN employees mm ON m.manager_id = mm.emp_id;

SELECT a.emp_name AS emp1, b.emp_name AS emp2, a.dept_id
FROM employees a
JOIN employees b ON a.dept_id = b.dept_id AND a.emp_id < b.emp_id;