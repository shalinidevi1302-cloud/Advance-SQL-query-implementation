-- =====================================================================
-- DBMS - ADVANCED SQL QUERY SYSTEM
-- Project Title: Musical Instruments E-Commerce Management System
-- Database: Oracle (SQL*Plus)
--
-- Tables used:
--   Customer(CustomerID, CustomerName, Email, Mobile, Age, City)
--   Product(Product_ID, Product_Name, Brand, Category, Price, Stock, Description)
--   Orders(Order_ID, Customer_ID, Order_Date, Order_Status, Total_Amount)
--   Order_Details(Detail_ID, Order_ID, Product_ID, Quantity, Subtotal, Unit_Price)
--
-- Run in SQL*Plus with:  @DBMS_Advanced_SQL_Queries.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- OUTPUT FORMATTING
-- ---------------------------------------------------------------------
SET LINESIZE 150
SET PAGESIZE 50
COLUMN CustomerName        FORMAT A15
COLUMN Product_Name        FORMAT A25
COLUMN Total_Purchase      FORMAT 999999
COLUMN Average_Order_Value FORMAT 99999.99
COLUMN Average_Price       FORMAT 99999.99

-- ---------------------------------------------------------------------
-- PREREQUISITES (run only if not already done)
-- Uncomment the lines you need.
-- ---------------------------------------------------------------------

-- Extra customers so that Orders and Customer match:
-- INSERT INTO Customer VALUES (207,'Rahul','rahul@gmail.com','9012345678',24,'Bangalore');
-- INSERT INTO Customer VALUES (208,'Priya','priya@gmail.com','9087654321',25,'Hyderabad');
-- INSERT INTO Customer VALUES (209,'Vikram','vikram@gmail.com','9345678123',26,'Mumbai');

-- Link Orders to the Customer IDs (only if Orders still has IDs 1 to 8):
-- UPDATE Orders SET Customer_ID = Customer_ID + 201;
-- ALTER TABLE Orders ADD FOREIGN KEY (Customer_ID) REFERENCES Customer(CustomerID);

-- Order_Details table (needed for sections 5 and 7):
-- CREATE TABLE Order_Details (
--     Detail_ID  NUMBER PRIMARY KEY,
--     Order_ID   NUMBER,
--     Product_ID NUMBER,
--     Quantity   NUMBER,
--     Subtotal   NUMBER(10,2),
--     Unit_Price NUMBER(10,2)
-- );
-- INSERT INTO Order_Details VALUES (1,1001,101,1,12500,12500);
-- INSERT INTO Order_Details VALUES (2,1002,102,1,45000,45000);
-- INSERT INTO Order_Details VALUES (3,1003,104,1,9500,9500);
-- INSERT INTO Order_Details VALUES (4,1004,103,1,38000,38000);
-- INSERT INTO Order_Details VALUES (5,1005,107,1,28000,28000);
-- INSERT INTO Order_Details VALUES (6,1006,106,1,42000,42000);
-- INSERT INTO Order_Details VALUES (7,1007,108,1,14500,14500);
-- INSERT INTO Order_Details VALUES (8,1008,110,1,22000,22000);
-- INSERT INTO Order_Details VALUES (9,1009,112,1,5500,5500);
-- INSERT INTO Order_Details VALUES (10,1010,111,1,6500,6500);
-- COMMIT;

-- If Order_Details already exists WITHOUT Unit_Price:
-- ALTER TABLE Order_Details ADD (Unit_Price NUMBER(10,2));
-- UPDATE Order_Details SET Unit_Price = Subtotal / Quantity;
-- COMMIT;

-- Optional: save everything shown on screen to a file
-- SPOOL advanced_sql_output.txt


-- =====================================================================
-- 1. SUBQUERIES AND NESTED QUERIES
-- =====================================================================

-- Example: Find orders whose amount is greater than the average order amount.
-- Inner query : SELECT AVG(Total_Amount) FROM Orders;
-- Outer query : displays orders with Total_Amount above that average.
SELECT Order_ID, Customer_ID, Total_Amount
FROM Orders
WHERE Total_Amount >
      (SELECT AVG(Total_Amount)
       FROM Orders);


-- =====================================================================
-- 2. FIND PRODUCTS ABOVE AVERAGE PRICE
-- =====================================================================

SELECT
    Product_ID,
    Product_Name,
    Price
FROM Product
WHERE Price >
      (SELECT AVG(Price)
       FROM Product);


-- ---------------------------------------------------------------------
-- 2.1 Products Below Average Price
-- ---------------------------------------------------------------------

SELECT
    Product_ID,
    Product_Name,
    Price
FROM Product
WHERE Price <
      (SELECT AVG(Price)
       FROM Product);


-- =====================================================================
-- 3. IDENTIFY CUSTOMERS WITH MAXIMUM PURCHASES
-- =====================================================================

-- Step 1: Calculate customer-wise purchase
SELECT
    Customer_ID,
    SUM(Total_Amount) AS Total_Purchase
FROM Orders
GROUP BY Customer_ID;

-- Step 2: Find the maximum purchase
SELECT MAX(Total_Purchase)
FROM
(
    SELECT
        Customer_ID,
        SUM(Total_Amount) AS Total_Purchase
    FROM Orders
    GROUP BY Customer_ID
);

-- ---------------------------------------------------------------------
-- 3.1 Display customer details with maximum purchase
-- ---------------------------------------------------------------------
SELECT
    c.CustomerID,
    c.CustomerName,
    SUM(o.Total_Amount) AS Total_Purchase
FROM Customer c
JOIN Orders o
    ON c.CustomerID = o.Customer_ID
GROUP BY
    c.CustomerID,
    c.CustomerName
HAVING SUM(o.Total_Amount) = (
    SELECT MAX(Total_Purchase)
    FROM (
        SELECT SUM(Total_Amount) AS Total_Purchase
        FROM Orders
        GROUP BY Customer_ID
    ));


-- =====================================================================
-- 4. COMPLEX BUSINESS QUERIES
-- =====================================================================

-- ---------------------------------------------------------------------
-- 4.1 Customers who placed orders above the average order value
-- ---------------------------------------------------------------------
SELECT
    c.CustomerID,
    c.CustomerName,
    o.Order_ID,
    o.Total_Amount
FROM Customer c
JOIN Orders o
    ON c.CustomerID = o.Customer_ID
WHERE o.Total_Amount >
(
    SELECT AVG(Total_Amount)
    FROM Orders
)
ORDER BY o.Total_Amount DESC;


-- =====================================================================
-- 5. FIND PRODUCTS WHOSE SALES ARE ABOVE AVERAGE
-- (total sales of each product are calculated from Order_Details)
-- =====================================================================

SELECT
    p.Product_ID,
    p.Product_Name,
    SUM(od.Subtotal) AS Total_Sales
FROM Product p
JOIN Order_Details od
    ON p.Product_ID = od.Product_ID
GROUP BY
    p.Product_ID,
    p.Product_Name
HAVING SUM(od.Subtotal) > (
    SELECT AVG(Product_Sales)
    FROM (
        SELECT SUM(Subtotal) AS Product_Sales
        FROM Order_Details
        GROUP BY Product_ID
    ))
ORDER BY Total_Sales DESC;


-- =====================================================================
-- 6. CUSTOMER PURCHASE REPORT
-- Contains: Customer ID, Customer Name, Number of orders,
--           Total purchase amount, Average order value
-- =====================================================================

SELECT
    c.CustomerID,
    c.CustomerName,
    COUNT(o.Order_ID)   AS Total_Orders,
    SUM(o.Total_Amount) AS Total_Purchase,
    AVG(o.Total_Amount) AS Average_Order_Value
FROM Customer c
JOIN Orders o
    ON c.CustomerID = o.Customer_ID
GROUP BY
    c.CustomerID,
    c.CustomerName
ORDER BY Total_Purchase DESC;


-- =====================================================================
-- 7. ADVANCED SALES REPORTS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 7.1 Product sales report (combines Product and Order_Details)
-- Products with no sales do not appear because of the JOIN.
-- ---------------------------------------------------------------------
SELECT
    p.Product_ID,
    p.Product_Name,
    COUNT(od.Order_ID)  AS Number_of_Orders,
    SUM(od.Quantity)    AS Total_Quantity_Sold,
    SUM(od.Subtotal)    AS Total_Sales,
    AVG(od.Unit_Price)  AS Average_Price
FROM Product p
JOIN Order_Details od
    ON p.Product_ID = od.Product_ID
GROUP BY
    p.Product_ID,
    p.Product_Name
ORDER BY Total_Sales DESC;

-- ---------------------------------------------------------------------
-- 7.2 Customer segmentation report (Gold / Silver / Bronze / Inactive)
-- ---------------------------------------------------------------------
SELECT c.CustomerID, c.CustomerName,
       NVL(SUM(o.Total_Amount),0) AS Total_Spent,
       CASE WHEN SUM(o.Total_Amount) >= 40000 THEN 'Gold'
            WHEN SUM(o.Total_Amount) >= 15000 THEN 'Silver'
            WHEN SUM(o.Total_Amount) > 0      THEN 'Bronze'
            ELSE 'Inactive' END AS Segment
FROM Customer c
LEFT JOIN Orders o ON c.CustomerID = o.Customer_ID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY Total_Spent DESC;

-- SPOOL OFF
-- =====================================================================
-- END OF SCRIPT
-- =====================================================================
