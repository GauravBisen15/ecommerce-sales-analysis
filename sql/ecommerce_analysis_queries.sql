-- =====================================================================
-- E-Commerce Sales Analysis — SQL Script
-- Author: Gaurav Bisen
-- Description: Schema + business analysis queries for the e-commerce
--              dataset generated in notebooks/Ecommerce_Sales_Analysis.ipynb
-- Database   : MySQL 8.0+
-- =====================================================================


-- =====================================================================
-- 1. DATABASE SETUP
-- =====================================================================

CREATE DATABASE ecommerce_analysis;
USE ecommerce_analysis;


-- =====================================================================
-- 2. SCHEMA
-- Tables mirror the CSV files produced by the Python data-generation
-- notebook: dataset/customers.csv, dataset/products.csv,
-- dataset/orders.csv, dataset/order_details.csv
-- =====================================================================

CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    phone         VARCHAR(20),
    city          VARCHAR(50),
    state         VARCHAR(50),
    signup_date   DATE NOT NULL
);

CREATE TABLE products (
    product_id     INT PRIMARY KEY,
    product_name   VARCHAR(150) NOT NULL,
    category       VARCHAR(50) NOT NULL,
    price          DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL,
    rating         DECIMAL(2,1)
);

CREATE TABLE orders (
    order_id       INT PRIMARY KEY,
    customer_id    INT NOT NULL,
    order_date     DATE NOT NULL,
    order_status   ENUM('Pending','Confirmed','Shipped','Delivered','Cancelled','Returned') NOT NULL,
    total_amount   DECIMAL(10,2) NOT NULL,
    payment_status ENUM('Pending','Paid','Failed','Refunded') NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_details (
    detail_id    INT PRIMARY KEY,
    order_id     INT NOT NULL,
    product_id   INT NOT NULL,
    quantity     INT NOT NULL,
    discount     INT NOT NULL,          -- discount percentage (0-30)
    sales_amount DECIMAL(12,2) NOT NULL, -- final line amount after discount
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- =====================================================================
-- 3. LOAD DATA (run this section only if importing the generated CSVs)
-- Update the file paths to match your local machine, and make sure
-- local_infile is enabled on your MySQL server/client.
-- =====================================================================

-- LOAD DATA LOCAL INFILE 'dataset/customers.csv'
-- INTO TABLE customers
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- LOAD DATA LOCAL INFILE 'dataset/products.csv'
-- INTO TABLE products
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- LOAD DATA LOCAL INFILE 'dataset/orders.csv'
-- INTO TABLE orders
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- LOAD DATA LOCAL INFILE 'dataset/order_details.csv'
-- INTO TABLE order_details
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;


-- =====================================================================
-- 4. SANITY CHECKS
-- =====================================================================

SHOW TABLES;

SELECT * FROM customers LIMIT 5;

SELECT COUNT(*) AS total_customers FROM customers;
SELECT COUNT(*) AS total_products  FROM products;
SELECT COUNT(*) AS total_orders    FROM orders;
SELECT COUNT(*) AS total_order_lines FROM order_details;


-- =====================================================================
-- 5. BUSINESS ANALYSIS QUERIES
-- =====================================================================

-- 5.1 Total revenue generated across all orders
SELECT SUM(sales_amount) AS total_revenue
FROM order_details;

-- 5.2 Average order value (AOV)
SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT order_id, SUM(sales_amount) AS order_total
    FROM order_details
    GROUP BY order_id
) AS order_totals;

-- 5.3 Top 10 products by revenue
SELECT
    p.product_name,
    SUM(od.sales_amount) AS total_revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 5.4 Top 10 products by units sold
SELECT
    p.product_name,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 10;

-- 5.5 Top 10 customers by total spend
SELECT
    o.customer_id,
    c.customer_name,
    SUM(od.sales_amount) AS total_spent
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- 5.6 Revenue by category
SELECT
    p.category,
    SUM(od.sales_amount) AS total_revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 5.7 Monthly sales trend
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
    SUM(od.sales_amount) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY sales_month
ORDER BY sales_month;

-- 5.8 Order status distribution
SELECT
    order_status,
    COUNT(*) AS number_of_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_orders
FROM orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- 5.9 Payment status analysis
SELECT
    payment_status,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY payment_status
ORDER BY number_of_orders DESC;

-- 5.10 Most popular category by units sold
SELECT
    p.category,
    SUM(od.quantity) AS total_units_sold
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY total_units_sold DESC;

-- 5.11 Customers who signed up but never placed an order
SELECT c.customer_id, c.customer_name, c.signup_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;