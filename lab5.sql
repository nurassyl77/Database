CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO employees VALUES (1, 'John', 'Doe', 25, 50000);
INSERT INTO employees VALUES (2, 'Jane', 'Smith', 30, 60000);
INSERT INTO employees VALUES (3, 'Bob', 'Young', 17, 40000);
INSERT INTO employees VALUES (4, 'Alice', 'Brown', 40, -1000);

INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Mouse', 50, 40);
INSERT INTO products_catalog VALUES (3, 'Keyboard', -100, 80);
INSERT INTO products_catalog VALUES (4, 'Monitor', 500, 600);
INSERT INTO products_catalog VALUES (5, 'Webcam', 80, 0);

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO customers VALUES (1, 'john@email.com', '+123456789', '2024-01-15');
INSERT INTO customers VALUES (2, 'jane@email.com', NULL, '2024-01-16');

INSERT INTO customers VALUES (NULL, 'bob@email.com', '+987654321', '2024-01-17');
INSERT INTO customers VALUES (3, NULL, '+111111111', '2024-01-18');
INSERT INTO customers VALUES (4, 'alice@email.com', '+222222222', NULL);
INSERT INTO customers VALUES (5, 'charlie@email.com', NULL, '2024-01-19');

INSERT INTO inventory VALUES (1, 'Laptop', 10, 999.99, '2024-01-15 10:00:00');
INSERT INTO inventory VALUES (2, 'Mouse', 25, 29.99, '2024-01-15 11:30:00');

INSERT INTO inventory VALUES (NULL, 'Keyboard', 15, 79.99, '2024-01-15 12:00:00');
INSERT INTO inventory VALUES (3, NULL, 8, 199.99, '2024-01-15 13:00:00');
INSERT INTO inventory VALUES (4, 'Monitor', NULL, 299.99, '2024-01-15 14:00:00');
INSERT INTO inventory VALUES (5, 'Webcam', 30, NULL, '2024-01-15 15:00:00');
INSERT INTO inventory VALUES (6, 'Tablet', 12, 399.99, NULL);
INSERT INTO inventory VALUES (7, 'Printer', -5, 149.99, '2024-01-15 16:00:00');
INSERT INTO inventory VALUES (8, 'Scanner', 20, 0, '2024-01-15 17:00:00');

CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- Drop and recreate with named constraints
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

INSERT INTO users VALUES (1, 'john_doe', 'john@email.com', '2024-01-15 10:00:00');
INSERT INTO users VALUES (2, 'jane_smith', 'jane@email.com', '2024-01-16 11:00:00');

INSERT INTO users VALUES (3, 'john_doe', 'bob@email.com', '2024-01-17 12:00:00');

INSERT INTO users VALUES (4, 'bob_brown', 'john@email.com', '2024-01-18 13:00:00');

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (1, 'IT', 'New York');
INSERT INTO departments VALUES (2, 'HR', 'Boston');
INSERT INTO departments VALUES (3, 'Finance', 'Chicago');

INSERT INTO departments VALUES (1, 'Marketing', 'LA');

INSERT INTO departments VALUES (NULL, 'Sales', 'Miami');

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Alice Brown', 1, '2023-01-15');
INSERT INTO employees_dept VALUES (2, 'Bob Wilson', 2, '2023-02-20');

INSERT INTO employees_dept VALUES (3, 'Charlie Green', 99, '2023-03-10');

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

-- Insert sample data
INSERT INTO authors VALUES
(1, 'J.K. Rowling', 'UK'),
(2, 'George Orwell', 'UK'),
(3, 'Agatha Christie', 'UK');

INSERT INTO publishers VALUES
(1, 'Penguin Books', 'London'),
(2, 'HarperCollins', 'New York'),
(3, 'Simon & Schuster', 'New York');

INSERT INTO books VALUES
(1, 'Harry Potter', 1, 1, 1997, '978-0439708180'),
(2, '1984', 2, 2, 1949, '978-0451524935'),
(3, 'Murder on the Orient Express', 3, 3, 1934, '978-0062693662');

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk VALUES (1, 'Laptop', 1), (2, 'Novel', 2);
INSERT INTO orders VALUES (1, '2024-01-15'), (2, '2024-01-16');
INSERT INTO order_items VALUES (1, 1, 1, 2), (2, 1, 2, 1), (3, 2, 1, 1);

DELETE FROM categories WHERE category_id = 1;

SELECT * FROM order_items WHERE order_id = 1;
DELETE FROM orders WHERE order_id = 1;
SELECT * FROM order_items WHERE order_id = 1;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products ON DELETE RESTRICT,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES
(1, 'John Smith', 'john.smith@email.com', '+1234567890', '2024-01-01'),
(2, 'Emma Johnson', 'emma.j@email.com', '+1234567891', '2024-01-02'),
(3, 'Michael Brown', 'm.brown@email.com', '+1234567892', '2024-01-03'),
(4, 'Sarah Davis', 'sarah.d@email.com', '+1234567893', '2024-01-04'),
(5, 'David Wilson', 'dwilson@email.com', '+1234567894', '2024-01-05');

INSERT INTO products VALUES
(1, 'Laptop', 'High-performance laptop', 999.99, 50),
(2, 'Smartphone', 'Latest smartphone model', 699.99, 100),
(3, 'Headphones', 'Wireless noise-cancelling', 199.99, 75),
(4, 'Tablet', '10-inch tablet', 399.99, 30),
(5, 'Smartwatch', 'Fitness tracking watch', 249.99, 60);

INSERT INTO orders VALUES
(1, 1, '2024-01-10', 1199.98, 'delivered'),
(2, 2, '2024-01-11', 699.99, 'processing'),
(3, 3, '2024-01-12', 449.98, 'shipped'),
(4, 4, '2024-01-13', 849.98, 'pending'),
(5, 5, '2024-01-14', 199.99, 'cancelled');

INSERT INTO order_details VALUES
(1, 1, 1, 1, 999.99),
(2, 1, 3, 1, 199.99),
(3, 2, 2, 1, 699.99),
(4, 3, 4, 1, 399.99),
(5, 3, 5, 1, 249.99),
(6, 4, 1, 1, 999.99),
(7, 4, 2, 1, 699.99),
(8, 5, 3, 1, 199.99);

INSERT INTO customers VALUES (6, 'Test User', 'john.smith@email.com', '+9999999999', '2024-01-15');

INSERT INTO products VALUES (6, 'Test Product', 'Desc', -10, 5);

INSERT INTO orders VALUES (6, 1, '2024-01-15', 100, 'invalid_status');

INSERT INTO orders VALUES (7, 99, '2024-01-15', 100, 'pending');

SELECT COUNT(*) FROM order_details WHERE order_id = 1;
DELETE FROM orders WHERE order_id = 1;
SELECT COUNT(*) FROM order_details WHERE order_id = 1;

DELETE FROM customers WHERE customer_id = 2;
INSERT INTO customers VALUES (NULL, 'Test', 'test@email.com', '+1111111111', '2024-01-15');