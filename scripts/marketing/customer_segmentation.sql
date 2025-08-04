/*
===============================================================================
Customer Segmentation and Ranking Query
===============================================================================

Problem Statement:
------------------
This query aims to analyze customer purchase behavior using data from sales orders. Specifically, it:

1. Calculates the total sales amount for each customer.
2. Identifies the most recent order date per customer.
3. Ranks customers based on their total sales, from highest to lowest.
4. Segments customers into categories ('High', 'Medium', 'Low') based on predefined total sales thresholds.

The purpose is to provide actionable insights into customer value, enabling targeted marketing, personalized engagement, and strategic decision-making.

Expected Output:
----------------
- CustomerID
- Customer Name (FirstName, LastName)
- Total Sales
- Last Order Date
- Customer Rank by Sales
- Customer Segment (High, Medium, Low)

*/WITH CTE_Total_Sale AS
(
    SELECT 
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
),

CTE_last_Date AS
(
    SELECT 
        CustomerID,
        MAX(OrderDate) AS LastDate
    FROM Sales.Orders
    GROUP BY CustomerID
),

CTE_Customer_Rank AS
(
    SELECT 
        CustomerID,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS CustomerRank
    FROM CTE_Total_Sale
),

Segment_Customers AS
(
    SELECT
        CustomerID,
        CASE
            WHEN TotalSales > 100 THEN 'High'
            WHEN TotalSales > 50 THEN 'Medium'
            ELSE 'Low'
        END AS CustomerSegment
    FROM CTE_Total_Sale
)

SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    ts.TotalSales,
    ld.LastDate,
    cr.CustomerRank,
    sc.CustomerSegment
FROM Sales.Customers c
LEFT JOIN CTE_Total_Sale ts ON c.CustomerID = ts.CustomerID
LEFT JOIN CTE_last_Date ld ON c.CustomerID = ld.CustomerID
LEFT JOIN CTE_Customer_Rank cr ON c.CustomerID = cr.CustomerID
LEFT JOIN Segment_Customers sc ON c.CustomerID = sc.CustomerID
ORDER BY cr.CustomerRank;
/* Step 1: Calculate total sales per customer */
WITH CTE_Total_Sale AS
(
    SELECT 
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
),

/* Step 2: Find the last order date for each customer */
CTE_last_Date AS
(
    SELECT 
        CustomerID,
        MAX(OrderDate) AS LastDate
    FROM Sales.Orders
    GROUP BY CustomerID
),

/* Step 3: Rank customers based on total sales in descending order */
CTE_Customer_Rank AS
(
    SELECT 
        CustomerID,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS CustomerRank
    FROM CTE_Total_Sale
),

/* Step 4: Segment customers into categories based on total sales */
Segment_Customers AS
(
    SELECT
        CustomerID,
        CASE
            WHEN TotalSales > 100 THEN 'High'
            WHEN TotalSales > 50 THEN 'Medium'
            ELSE 'Low'
        END AS CustomerSegment
    FROM CTE_Total_Sale
)

/* Final step: Combine all customer info and computed metrics */
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    ts.TotalSales,
    ld.LastDate,
    cr.CustomerRank,
    sc.CustomerSegment
FROM Sales.Customers c
LEFT JOIN CTE_Total_Sale ts ON c.CustomerID = ts.CustomerID
LEFT JOIN CTE_last_Date ld ON c.CustomerID = ld.CustomerID
LEFT JOIN CTE_Customer_Rank cr ON c.CustomerID = cr.CustomerID
LEFT JOIN Segment_Customers sc ON c.CustomerID = sc.CustomerID
ORDER BY cr.CustomerRank;