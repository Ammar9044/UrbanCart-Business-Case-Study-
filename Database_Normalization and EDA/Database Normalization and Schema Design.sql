-- Create database
CREATE DATABASE urbancart_analysis;

-- Create customers table
CREATE TABLE customers (
    cust_id INT PRIMARY KEY,
    dob DATE,
    gender ENUM('M', 'F'),
    city_code INT
);

-- Create product_category table
CREATE TABLE product_category (
    prod_cat_code INT PRIMARY KEY,
    prod_cat VARCHAR(100),
    prod_sub_cat_code INT,
    prod_subcat VARCHAR(50)
);

-- Create transactions table
CREATE TABLE transactions (
    transaction_id BIGINT,
    cust_id INT,
    tran_date DATE,
    prod_subcat_code INT,
    prod_cat_code INT,
    Qty INT,  -- Allows negative values
    rate DECIMAL(10,2),
    Tax DECIMAL(10,2),
    total_amt DECIMAL(10,2),  -- Allows negative values
    Store_type VARCHAR(100),
    transaction_type ENUM('Sale', 'Return')
);

-- Find duplicate transactions based on ID and date
SELECT transaction_id, tran_date, COUNT(*) 
FROM transactions
GROUP BY 1, 2
HAVING COUNT(*) > 1;

-- Add composite primary key to prevent duplicates
ALTER TABLE transactions
ADD PRIMARY KEY (transaction_id, tran_date);

-- Add foreign key: transactions → customers
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_customer
FOREIGN KEY (cust_id)
REFERENCES customers(cust_id);

-- Add foreign key: transactions → product_category (category level)
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_prodcat
FOREIGN KEY (prod_cat_code)
REFERENCES product_category(prod_cat_code);

-- Delete orphan records where customer does not exist
DELETE FROM transactions
WHERE cust_id NOT IN (
    SELECT cust_id FROM customers
);

-- Add foreign key: transactions → product_category (subcategory level)
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_prod_sub_cat
FOREIGN KEY (prod_subcat_code)
REFERENCES product_category(prod_sub_cat_code);

-- Changing Column Names fopr Consistency 
Alter Table transactions
Change Qty qty int,
Change Tax tax decimal(10,2),
Change Store_type store_type varchar(100);

