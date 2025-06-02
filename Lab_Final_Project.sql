Create Database Final_Project;
USE Final_Project;

SELECT TOP 100 * FROM dbo.Stg_Sales;

-- Dimension Tables 01
CREATE TABLE DimCustomer (
    Customer_Key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID INT,
    Gender VARCHAR(10),
    Age INT
);

-- Loading Customers
INSERT INTO DimCustomer (Customer_ID, Gender, Age)
SELECT DISTINCT Customer_ID, Gender, Age
FROM Stg_Sales;

-- Customer_ID from INT to VARCHAR
ALTER TABLE DimCustomer
ALTER COLUMN Customer_ID VARCHAR(50);

-- Dimension Table 02
CREATE TABLE DimProduct (
    Product_Key INT IDENTITY(1,1) PRIMARY KEY,
    Product_Category VARCHAR(100)
);

INSERT INTO DimProduct (Product_Category)
SELECT DISTINCT Product_Category
FROM Stg_Sales;

-- Dimension Table 03
CREATE TABLE DimDate (
    Date_Key INT IDENTITY(1,1) PRIMARY KEY,
    Full_Date DATE,
    Day INT,
    Month INT,
    Year INT,
    Day_Name VARCHAR(10),
    Month_Name VARCHAR(10)
);

INSERT INTO DimDate (Full_Date, Day, Month, Year, Day_Name, Month_Name)
SELECT DISTINCT 
    CAST([Date] AS DATE),
    DAY([Date]),
    MONTH([Date]),
    YEAR([Date]),
    DATENAME(WEEKDAY, [Date]),
    DATENAME(MONTH, [Date])
FROM Stg_Sales;

-- Fact Table
CREATE TABLE FactSales (
    Sales_ID INT IDENTITY(1,1) PRIMARY KEY,
    Transaction_ID INT,
    Date_Key INT,
    Customer_Key INT,
    Product_Key INT,
    Quantity INT,
    Price_per_Unit DECIMAL(10,2),
    Total_Amount DECIMAL(10,2)
);

-- Loading Data into Fact Table
INSERT INTO FactSales (Transaction_ID, Date_Key, Customer_Key, Product_Key, Quantity, Price_per_Unit, Total_Amount)
SELECT 
    s.Transaction_ID,
    d.Date_Key,
    c.Customer_Key,
    p.Product_Key,
    s.Quantity,
    s.Price_per_Unit,
    s.Total_Amount
FROM Stg_Sales s
JOIN DimCustomer c ON s.Customer_ID = c.Customer_ID AND s.Age = c.Age AND s.Gender = c.Gender
JOIN DimProduct p ON s.Product_Category = p.Product_Category
JOIN DimDate d ON CAST(s.[Date] AS DATE) = d.Full_Date;

-- Data Quality Checks
-- Checking for Duplicates in Dimension Tables
-- For DimCustomer
SELECT Customer_ID, COUNT(*)
FROM DimCustomer
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

-- For DimProduct
SELECT Product_Category, COUNT(*)
FROM DimProduct
GROUP BY Product_Category
HAVING COUNT(*) > 1;

-- For DimDate
SELECT Date_Key, COUNT(*)
FROM DimDate
GROUP BY Date_Key
HAVING COUNT(*) > 1;

-- Checking for Nulls in Fact Sales
SELECT * 
FROM FactSales
WHERE Customer_Key IS NULL 
   OR Product_Key IS NULL 
   OR Date_Key IS NULL;

-- Checking for Consistent Foreign Key Relationships
SELECT fs.Customer_Key
FROM FactSales fs
LEFT JOIN DimCustomer dc ON fs.Customer_Key = dc.Customer_Key
WHERE dc.Customer_Key IS NULL;

-- Performance Optimization
-- Indexing
-- Creating Indexes on Foreign Keys
-- CREATE INDEX idx_FactSales_CustomerKey ON FactSales (Customer_Key);
CREATE INDEX idx_FactSales_ProductKey ON FactSales (Product_Key);
CREATE INDEX idx_FactSales_DateKey ON FactSales (Date_Key);

-- Creating Indexes on High Cardinality Column
CREATE INDEX idx_DimCustomer_CustomerID ON DimCustomer (Customer_ID);

-- Partitioning
-- Partitioning by Date
-- Creating Partition Function on Date
CREATE PARTITION FUNCTION pfSalesByDate (DATE)
AS RANGE RIGHT FOR VALUES 
('2021-12-31', '2022-12-31', '2023-12-31');

-- Creating a Partition Scheme
CREATE PARTITION SCHEME psSalesByDate
AS PARTITION pfSalesByDate
TO ([PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY]);

-- Creating Partitioned FactSales Table
CREATE TABLE FactSales_Partitioned (
    FactSales_Key INT NOT NULL,
    Customer_Key INT,
    Product_Key INT,
    Date DATE NOT NULL,
    Quantity INT,
    Total_Amount DECIMAL(18,2),
    PRIMARY KEY (FactSales_Key, Date)
) ON psSalesByDate(Date);

-- MetaData Table
--  Creating MMetadata Table
CREATE TABLE DW_Metadata (
    Table_Name NVARCHAR(128),
    Column_Name NVARCHAR(128),
    Data_Type NVARCHAR(128),
    Column_Value_Count INT,  -- This column will store the count of non-null values
    Created_Date DATETIME DEFAULT GETDATE(),
    Last_Modified_Date DATETIME DEFAULT GETDATE()
);

-- Creating a Stored Procedure to Populate Metadata
CREATE PROCEDURE Populate_DWMetadata
AS
BEGIN
    DECLARE @tableName NVARCHAR(128);
    DECLARE @columnName NVARCHAR(128);
    DECLARE @dataType NVARCHAR(128);
    DECLARE @sql NVARCHAR(MAX);
    
    -- Cursor to loop through all user tables in the database
    DECLARE table_cursor CURSOR FOR
    SELECT t.name
    FROM sys.tables t
    WHERE t.is_ms_shipped = 0;  -- Exclude system tables

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @tableName;

    -- Loop through each table
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Cursor to loop through columns of the current table
        DECLARE column_cursor CURSOR FOR
        SELECT c.name, ty.name
        FROM sys.columns c
        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE c.object_id = OBJECT_ID(@tableName);

        OPEN column_cursor;
        FETCH NEXT FROM column_cursor INTO @columnName, @dataType;

        -- Loop through each column of the current table
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Insert the table and column metadata into the DW_Metadata table
            INSERT INTO DW_Metadata (Table_Name, Column_Name, Data_Type, Column_Value_Count)
            VALUES (@tableName, @columnName, @dataType, 0);

            -- Update the Column_Value_Count to count non-null values
            SET @sql = 'UPDATE DW_Metadata
                        SET Column_Value_Count = (SELECT COUNT(*) FROM ' + @tableName + ' WHERE ' + @columnName + ' IS NOT NULL)
                        WHERE Table_Name = ''' + @tableName + ''' AND Column_Name = ''' + @columnName + '''';
            EXEC sp_executesql @sql;

            FETCH NEXT FROM column_cursor INTO @columnName, @dataType;
        END

        -- Cleanup the column_cursor
        CLOSE column_cursor;
        DEALLOCATE column_cursor;

        FETCH NEXT FROM table_cursor INTO @tableName;
    END

    -- Cleanup the table_cursor
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
END


-- Executing the Stored Procedure to Populate the Metadata
EXEC Populate_DWMetadata;

SELECT * FROM DW_Metadata;

-- Data Anomolies Detection
-- Find outliers in Total_Amount
WITH SalesStats AS (
    SELECT AVG(Total_Amount) AS Mean, STDEV(Total_Amount) AS StdDev
    FROM FactSales
)
SELECT * 
FROM FactSales, SalesStats
WHERE ABS(FactSales.Total_Amount - SalesStats.Mean) > 3 * SalesStats.StdDev;


-- Data Visualization
--  Total Sales by Product Category
SELECT 
    p.Product_Category,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimProduct p ON f.Product_Key = p.Product_Key
GROUP BY 
    p.Product_Category
ORDER BY 
    Total_Sales DESC;


-- Total Sales by Customer
SELECT 
    c.Customer_ID,
    c.Gender,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimCustomer c ON f.Customer_Key = c.Customer_Key
GROUP BY 
    c.Customer_ID, c.Gender
ORDER BY 
    Total_Sales DESC;

--  Monthly Sales Trend
SELECT 
    d.Month, 
    d.Year,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimDate d ON f.Date_Key = d.Date_Key
GROUP BY 
    d.Month, d.Year
ORDER BY 
    d.Year, d.Month;

-- Average Sales per Transaction
SELECT 
    COUNT(f.Transaction_ID) AS Number_of_Transactions,
    SUM(f.Total_Amount) / COUNT(f.Transaction_ID) AS Average_Sales_Per_Transaction
FROM 
    FactSales f;

-- Sales and Quantity Sold by Date
SELECT 
    d.Full_Date,
    SUM(f.Total_Amount) AS Total_Sales,
    SUM(f.Quantity) AS Total_Quantity_Sold
FROM 
    FactSales f
JOIN 
    DimDate d ON f.Date_Key = d.Date_Key
GROUP BY 
    d.Full_Date
ORDER BY 
    d.Full_Date;


-- Top Customers by Total Sales
SELECT TOP 10
    c.Customer_ID,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimCustomer c ON f.Customer_Key = c.Customer_Key
GROUP BY 
    c.Customer_ID
ORDER BY 
    Total_Sales DESC;


-- Sales Distribution by Gender
SELECT 
    c.Gender,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimCustomer c ON f.Customer_Key = c.Customer_Key
GROUP BY 
    c.Gender
ORDER BY 
    Total_Sales DESC;

--  Sales by Age Group
SELECT 
    CASE 
        WHEN c.Age < 20 THEN 'Under 20'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS Age_Group,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimCustomer c ON f.Customer_Key = c.Customer_Key
GROUP BY 
    CASE 
        WHEN c.Age < 20 THEN 'Under 20'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END
ORDER BY 
    Total_Sales DESC;


-- Sales by Product Category Over Time (Month-wise Trend)
SELECT 
    d.Month,
    p.Product_Category,
    SUM(f.Total_Amount) AS Monthly_Sales
FROM 
    FactSales f
JOIN 
    DimDate d ON f.Date_Key = d.Date_Key
JOIN 
    DimProduct p ON f.Product_Key = p.Product_Key
GROUP BY 
    d.Month, p.Product_Category
ORDER BY 
    d.Month, Monthly_Sales DESC;


-- Best Day of Week for Sales
SELECT 
    d.Day_Name,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimDate d ON f.Date_Key = d.Date_Key
GROUP BY 
    d.Day_Name
ORDER BY 
    Total_Sales DESC;

-- Sales by Day and Month Name 
SELECT 
    d.Month_Name,
    d.Day_Name,
    SUM(f.Total_Amount) AS Total_Sales
FROM 
    FactSales f
JOIN 
    DimDate d ON f.Date_Key = d.Date_Key
GROUP BY 
    d.Month_Name, d.Day_Name
ORDER BY 
    d.Month_Name, d.Day_Name;




-- Explanation
-- Extracted data by loading the dataset into the staging table (Stg_Sales).
-- Transformed data by creating dimension tables (DimCustomer, DimProduct, DimDate) and populating them with distinct values from your staging table.
-- Loaded the data into the fact table (FactSales) by joining the staging data with the dimension tables to generate the required surrogate keys.

-- Data Quality Checks
-- Before jumping into optimization, it's essential to ensure that your data is clean, valid, and consistent. This will help you avoid issues later on when querying the data.

-- Check for Duplicates in Dimension Tables
-- You can check if any duplicate Customer_ID, Product_ID, or Date exists in your dimension tables.
-- If any duplicates are found, you'll need to clean them by removing or merging the duplicates.

-- Check for NULL Values in Fact Table
-- You should ensure that no NULL values are present in your foreign keys (e.g., Customer_Key, Product_Key, Date_Key) in the fact table.

-- Check for Consistent Foreign Key Relationships
-- This query will return any Customer_Key values in FactSales that do not have corresponding records in DimCustomer. You can perform similar checks for Product_Key and Date_Key.

