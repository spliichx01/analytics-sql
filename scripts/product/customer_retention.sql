/*
===============================================================================
Customer Retention Analysis
===============================================================================
Script Purpose:
    This script analyzes customer loyalty by calculating the average number of 
    days between orders for each customer. It helps businesses understand:
    - How frequently each customer places orders.
    - Which customers are highly engaged (frequent buyers).
    - Which customers may be at risk due to long gaps between purchases.

Usage Notes:
    - Customers with only one order will have NULL gaps; these are handled 
      using COALESCE to ensure they rank lowest (least frequent).
    - Results can be used for segmentation, churn analysis, or loyalty campaigns.
===============================================================================
*/

Select 
	CustomerID,
	AVG(DaysUntillNextOrder) AvgNextOrder,
	 RANK() Over (Order by Coalesce( AVG(DaysUntillNextOrder),99999999))RankAvg
from(
	Select 
	OrderID,
	CustomerID, 
	OrderDate CurrentDate,
	LEAD(OrderDate) over(partition by CustomerID order by OrderDate) NextDate,
	DATEDIFF(DAY,OrderDate ,LEAD(OrderDate) over(partition by CustomerID order by OrderDate)) DaysUntillNextOrder 
from  Sales. Orders)t
group by CustomerID