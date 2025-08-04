/*
===============================================================================
Product Sales Extremes Analysis
===============================================================================
Script Purpose:
    This script analyzes the range of sales performance per product by:
    - Identifying the lowest and highest sales values for each product.
    - Calculating the difference between each sale and the lowest sale 
      (i.e., movement from minimum toward the maximum).
    
    It is useful for understanding product performance spread, pricing behavior,
    and sales consistency over time or across transactions.

Usage Notes:
    - Ensure the Sales data is clean and numeric.
    - The query uses window functions (FIRST_VALUE, LAST_VALUE) to detect
      extremes per product.
    - "LowestToExtrame" shows how far a sale is from the product’s minimum sale.
===============================================================================
*/
SELECT 
	ProductID,
	Sales,
	FIRST_VALUE(Sales) OVER (PARTITION BY ProductID ORDER BY Sales) AS LowestSale,
	LAST_VALUE(Sales) OVER (
		PARTITION BY ProductID 
		ORDER BY Sales
		ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
	) AS HighestSale,
	Sales - FIRST_VALUE(Sales) OVER (PARTITION BY ProductID ORDER BY Sales) AS LowestToExtrame
FROM Sales.Orders
