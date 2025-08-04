/*
===============================================================================
Inventory Projection Query (Recursive CTE Version)
===============================================================================

Description:
-----------
This query supports an inventory management system using a SQL Server database
with two key tables: `Products` and `Orders`.

- Products table includes:
    - ID_PRODUCT
    - name
    - current_inventory
    - turnover_rate

- Orders table includes:
    - ID_ORDER
    - ID_PRODUCT
    - delivery_date
    - amount

Objective:
----------
Project daily inventory levels for each product over the next 365 days using
a recursive Common Table Expression (CTE). This approach models inventory
sequentially, where each day’s inventory level depends on the previous day’s
inventory, adjusted for:

1. Daily turnover rate (fixed inventory depletion)
2. Scheduled deliveries (restocking events)
3. Inventory must never fall below zero — if it reaches 0, it stays at 0
   until a delivery occurs that raises it above zero again.

Expected Output:
----------------
- ID_PRODUCT
- InventoryDate
- ProjectedInventory

Behavior:
---------
- Start from each product’s `current_inventory`
- For each day:
    - Subtract the turnover rate
    - Add any deliveries scheduled for that day
    - Prevent inventory from going negative (if < 0, reset to 0)
- Continue this logic recursively for 365 days

*/

USE InventoryDB;
GO

-- Create actual table in the database
CREATE TABLE Products (
    ID_PRODUCT INT PRIMARY KEY IDENTITY(1, 1),
    name NVARCHAR(255),
    current_inventory INT,
    turnover_rate INT
);

CREATE TABLE Orders (
    ID_ORDER INT PRIMARY KEY IDENTITY(1, 1),
    ID_PRODUCT INT,
    delivery_date DATE,
    amount INT
);

-- Insert tables
INSERT INTO Products (name, current_inventory, turnover_rate)
VALUES
    ('Product A', 100, 5),
    ('Product B', 200, 3),
    ('Product C', 150, 4),
    ('Product D', 50, 6),
    ('Product E', 300, 2),
    ('Product F', 75, 4),
    ('Product G', 250, 3),
    ('Product H', 120, 5),
    ('Product I', 40, 7),
    ('Product J', 180, 4);

INSERT INTO Orders (ID_PRODUCT, delivery_date, amount)
VALUES
    (1, '2023-09-15', 50),
    (2, '2023-09-16', 100),
    (3, '2023-09-17', 75),
    (4, '2023-09-18', 30),
    (5, '2023-09-19', 150),
    (6, '2023-09-20', 80),
    (7, '2023-09-21', 60),
    (8, '2023-09-22', 90),
    (9, '2023-09-23', 120),
    (10, '2023-09-24', 40),
    (1, '2023-09-25', 55),
    (2, '2023-09-26', 85),
    (3, '2023-09-27', 70),
    (4, '2023-09-28', 45),
    (5, '2023-09-29', 110),
    (6, '2023-09-30', 65),
    (7, '2023-10-01', 95),
    (8, '2023-10-02', 75),
    (9, '2023-10-03', 125),
    (10, '2023-10-04', 50);



USE InventoryDB;
GO

-- Step 1: Generate a calendar of 365 dates
WITH Calendar AS (
    SELECT 
        CAST(GETDATE() AS DATE) AS InventoryDate,
        1 AS DayNumber
    UNION ALL
    SELECT 
        DATEADD(DAY, 1, InventoryDate),
        DayNumber + 1
    FROM Calendar
    WHERE DayNumber < 365
),

-- Step 2: Get delivery amounts grouped by product and date
Deliveries AS (
    SELECT 
        ID_PRODUCT,
        delivery_date,
        SUM(amount) AS DeliveryAmount
    FROM Orders
    GROUP BY ID_PRODUCT, delivery_date
),

-- Step 3: Prepare base data to reference in recursion
ProductCalendar AS (
    SELECT 
        p.ID_PRODUCT,
        p.name,
        p.current_inventory,
        p.turnover_rate,
        c.InventoryDate
    FROM Products p
    CROSS JOIN Calendar c
),

-- Step 4: Recursive inventory projection
InventoryRecursive AS (
    -- Anchor query: first day (starting inventory)
    SELECT 
        pc.ID_PRODUCT,
        pc.name,
        pc.InventoryDate,
        pc.turnover_rate,
        CAST(pc.current_inventory + ISNULL(d.DeliveryAmount, 0) AS INT) AS ProjectedInventory
    FROM ProductCalendar pc
    LEFT JOIN Deliveries d
        ON pc.ID_PRODUCT = d.ID_PRODUCT
        AND pc.InventoryDate = (SELECT MIN(InventoryDate) FROM Calendar)
    WHERE pc.InventoryDate = (SELECT MIN(InventoryDate) FROM Calendar)

    UNION ALL

    -- Recursive query: day-by-day projection (NO OUTER JOIN HERE)
    SELECT 
        pc.ID_PRODUCT,
        pc.name,
        pc.InventoryDate,
        pc.turnover_rate,
        CAST(
            CASE 
                WHEN ir.ProjectedInventory - pc.turnover_rate + ISNULL(
                    (SELECT DeliveryAmount 
                     FROM Deliveries d 
                     WHERE d.ID_PRODUCT = pc.ID_PRODUCT 
                       AND d.delivery_date = pc.InventoryDate), 0
                ) < 0 
                THEN 0
                ELSE ir.ProjectedInventory - pc.turnover_rate + ISNULL(
                    (SELECT DeliveryAmount 
                     FROM Deliveries d 
                     WHERE d.ID_PRODUCT = pc.ID_PRODUCT 
                       AND d.delivery_date = pc.InventoryDate), 0
                )
            END AS INT
        ) AS ProjectedInventory
    FROM InventoryRecursive ir
    INNER JOIN ProductCalendar pc
        ON ir.ID_PRODUCT = pc.ID_PRODUCT
        AND pc.InventoryDate = DATEADD(DAY, 1, ir.InventoryDate)
)

-- Final output
SELECT 
    ID_PRODUCT,
    name AS ProductName,
    InventoryDate,
    ProjectedInventory
FROM InventoryRecursive
ORDER BY ID_PRODUCT, InventoryDate
OPTION (MAXRECURSION 365);
