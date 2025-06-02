# Sales_Data_Warehouse_and_Power-BI_Analysis
# Project Title: 
Sales Data Warehouse and Power BI Dashboard Analysis 

# Project Overview: 
The primary objective of this project is to design and implement a data warehouse using SQL 
Server and visualize insights through an interactive Power BI dashboard. Data warehousing 
involves gathering data from various sources, transforming it into a suitable format, and storing 
it in a structured database designed for analytical querying and reporting. 
In this project, we aimed to: 

• Organize transactional sales data using dimensional modeling. 

• Create a reliable, optimized data warehouse schema with appropriate dimension and 
fact tables. 

• Ensure data quality, integrity, and performance optimization. 

• Extract insightful metrics and KPIs from the data. 

• Build an interactive Power BI dashboard for business decision-making support. 

# Dataset Description: 
We worked with a sales dataset containing transactional records, including information such as: 

• Customer details (ID, gender, age) 

• Product categories 

• Sales dates 

• Quantities and total amounts of transactions 

This dataset was initially in a staging table within SQL Server. 

# Data Warehouse Implementation Steps: 
## Dataset Import into SQL Server 
The first step involved importing the provided dataset into SQL Server to create a staging table. 
The staging table serves as a temporary storage area where raw data is initially loaded and 
reviewed before transforming it into a clean, structured data warehouse schema. 
### Why: 
This allows us to inspect, clean, and transform the data appropriately before integrating it into a 
warehouse environment. 
## Creation of Data Warehouse Schema 
We structured our data warehouse using a star schema model. This model consists of a central 
fact table containing measurable, quantitative data (facts) and connected dimension tables 
containing descriptive attributes related to those facts. 
### Dimension Tables Created: 
• DimCustomer: Stores customer information (ID, gender, age).

• DimProduct: Stores product category names. 

• DimDate: Contains various date components (date, day, month, year, day name, month 
name). 

### Fact Table Created: 
• FactSales: Records transactional data such as product sold, quantity, total amount, 
linked to dimension tables via foreign keys. 
### Why: 
This structure improves query performance, ensures data consistency, and facilitates easier 
reporting and analysis.

## Data Transformation and Population 
Data was transformed from the staging table and loaded into the dimension and fact tables. 
• Unique customer and product records were inserted into dimension tables. 

• Sales dates were processed to extract components (day, month, year, etc.) for the 
DimDate table. 

• The fact table was populated by linking transactional records to corresponding 
dimension table keys. 
### Why: 
To organize data systematically, eliminate redundancy, and support efficient analytical queries. 
## Data Quality and Consistency Checks 
After loading data, several validation checks were performed: 
**• Duplicate Checks:** Verified that each customer and product record appeared only once 
in respective dimension tables. 
**• Null Value Checks:** Ensured no critical fields (like keys in fact table) were left null. 
**• Foreign Key Integrity:** Confirmed that every fact table record referenced valid keys in 
dimension tables. 
### Why: 
To maintain data integrity, accuracy, and reliability in the data warehouse.

## Performance Optimization 
To enhance data retrieval speed and efficiency: 

• Indexes were applied to key columns used in joins and filters. 

• Partitioning was introduced on the fact table based on the sales date to manage large 
datasets better and improve query performance.

### Why: 
Optimized queries are essential for handling large transactional datasets and maintaining fast, 
responsive reporting systems.

## Metadata Table Creation 
A metadata table was created to document the structure and state of the data warehouse: 

• Contains records of each table and column. 

• Tracks the number of non-null values in each column. 

A stored procedure was designed to automatically populate and update this metadata. 
### Why: 
To maintain an internal record of data definitions and completeness for auditing and monitoring 
purposes.

## Data Anomaly Detection 
An anomaly detection process was implemented to identify unusually high or low sales 
amounts: 
• Calculated the mean and standard deviation of total transaction amounts. 
• Identified records that fell outside three standard deviations from the mean. 
### Why: 
To spot potential data entry errors, outliers, or fraudulent transactions that may distort business 
insights.

### Business Intelligence Queries 
Various analytical queries were executed to extract meaningful business insights, such as: 

• Total sales by product category

• Monthly and daily sales trends

• Total Sales by Customer

• Top customers by sales 

• Sales distribution by gender and age group 

• Average sales per transaction 

• Most profitable day of the week

### Why: 
To transform raw data into actionable information for business decision-making. 

# Power BI Dashboard 
After preparing and extracting the necessary datasets, an interactive Power BI dashboard was 
created for visualizing insights and KPIs.

## Dashboard Components 
### Slicers (Filters) 
These allow users to dynamically filter data across all visuals in the report: 

• Month: Selects transactions by month. 

• Product Category: Filters data by product category. 

• Day: Filters data by day of the month.

**Purpose:** 
To provide interactivity and enable users to focus on specific time periods, product groups, or 
days for analysis.

## Cards (KPI Indicators) 
These display key business performance metrics: 

• Total Quantity Sold: 2514 

• Total Transactions: 1000 

• Total Profit: 159.60K 

• Total Sales: 456.00K 
**Purpose:** 
To give users an at-a-glance view of essential business indicators. 

## Visualizations (Graphs & Charts) 
### 1. Profit by Day Name (Bar Chart) 
• Displays total profit for each day of the week. 

• Highlights the most and least profitable days. 

### 2. Total Transactions by Day Name (Bar Chart) 
• Shows how transaction volumes vary by day.

### 3. Total Sales by Month Name and Year (Line Chart) 
• Illustrates monthly sales trends over 2023 and 2024. 

• Helps identify seasonal patterns or monthly growth. 

### 4. Total Sales by Gender (Pie Chart) 
• Visualizes sales distribution between male and female customers.

### 5. Total Sales by Product Category (Bar Chart) 
• Displays sales figures for different product categories.

• Identifies top-performing and underperforming categories. 

### 6. Total Sales $ Profit (Combined KPI Display) 
• Likely shows a comparison of total sales and profit, potentially via a combo chart or KPI 
summary. 

**Purpose:** 
These visualizations offer clear, actionable insights into business performance trends and 
customer behavior.

