/*
===============================================================================
Month-over-Month (MoM) Sales Trend Analysis
===============================================================================
Script Purpose:
    This script calculates the month-over-month (MoM) change in total sales.
    It helps businesses monitor sales performance over time by:
    - Showing the difference in sales between consecutive months.
    - Calculating the percentage change to highlight growth or decline.

Usage Notes:
    - Assumes the dataset covers at least two months of sales data.
    - Uses LAG() to access the previous month's sales.
    - Be cautious of division by zero when previous month's sales are zero.
===============================================================================
*/

SELECT *, 
    CurrentM - previousM AS MoM_change,
    ROUND(CAST((CurrentM - previousM) AS FLOAT) / previousM * 100, 1) AS MOM_percentage
FROM (
    SELECT
        MONTH(OrderDate) AS OrderMonth,
        SUM(Sales) AS CurrentM,
        LAG(SUM(Sales)) OVER (ORDER BY MONTH(OrderDate)) AS previousM
    FROM Sales.Orders
    GROUP BY MONTH(OrderDate)
) t