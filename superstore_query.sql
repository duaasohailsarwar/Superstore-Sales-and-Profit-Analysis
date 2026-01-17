CREATE DATABASE superstore_analytics;
USE superstore_analytics;

CREATE TABLE sales_data (
    Row_ID INT,
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50),
    Product_ID VARCHAR(20),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(200),
    Sales DOUBLE,
    Quantity INT,
    Discount DOUBLE,
    Profit DOUBLE,
    Year INT,
    Month_Name VARCHAR(20),
    Shipping_Days INT,
    Profit_Margin DOUBLE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/superstore_cleaned.csv'
INTO TABLE sales_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  Row_ID,
  Order_ID,
  @Order_Date,
  @Ship_Date,
  Ship_Mode,
  Customer_ID,
  Customer_Name,
  Segment,
  Country,
  City,
  State,
  Postal_Code,
  Region,
  Product_ID,
  Category,
  Sub_Category,
  Product_Name,
  Sales,
  Quantity,
  Discount,
  Profit,
  Year,
  Month_Name,
  Shipping_Days,
  Profit_Margin
)
SET
  Order_Date = STR_TO_DATE(@Order_Date, '%d/%m/%Y'),
  Ship_Date  = STR_TO_DATE(@Ship_Date, '%d/%m/%Y');

select * from sales_data;






# OBJECTIVE 1: Sales and Profit Performance Analysis

# KPI 1: Total Sales

select sum(Sales) as Total_Sales
from sales_data;


# KPI 2: Total Profit

select sum(Profit) as Total_Profit
from sales_data;


# KPI 3: Profit Margin

select round(sum(Profit) / nullif(sum(Sales),0) * 100, 2) as Profit_Margin_Percentage
from sales_data;


# KPI 4: Year-over-Year Growth(%)
WITH sales_per_year AS (
    SELECT 
        Year,
        SUM(Sales) AS Total_Sales
    FROM sales_data
    GROUP BY Year
    ORDER BY Year DESC
)
SELECT 
    Year, 
    Total_Sales,
    ROUND(
        (
            (Total_Sales - LAG(Total_Sales) OVER (ORDER BY Year)) 
            / NULLIF(LAG(Total_Sales) OVER (ORDER BY Year), 0)
        ) * 100,
        2) AS YOY_GROWTH
FROM sales_per_year
ORDER BY Year DESC;





# OBJECTIVE 2: Discount Impact on Profitability

# KPI 1: Average Discount (%)

SELECT round(avg(Discount) * 100, 2) as Avg_Discount_percentage
from sales_data;

# or weighted average discount

SELECT round((sum(Discount * Sales)/ round(sum(Sales),0)) * 100, 2) as Avg_Discount_percentage
from sales_data;



# KPI 2: Profit Margin per Discount Band

select Discount, count(Discount)
from sales_data
group by Discount;

select 
case
when Discount >= 0 and Discount < 0.1 THEN '0-10%'
when Discount >= 0.1 and Discount < 0.2 THEN '10-20%'
when Discount >= 0.2 and Discount < 0.3 THEN '20-30%'
when Discount >= 0.3 and Discount < 0.4 THEN '30-40%'
when Discount >= 0.4 and Discount < 0.5 THEN '40-50%'
when Discount >= 0.5 and Discount < 0.6 THEN '50-60%'
when Discount >= 0.6 and Discount < 0.7 THEN '60-70%'
when Discount >= 0.7 and Discount < 0.8 THEN '70-80%'
when Discount >= 0.8 and Discount < 0.9 THEN '80-90%'
when Discount >= 0.9 and Discount <= 1.0 THEN '90-100%'
end as discount_band,
round(SUM(Sales),2) AS Total_Sales,
round(SUM(Profit),2) AS Total_Profit,
round((sum(Profit)/	nullif(sum(Sales), 0)) * 100 ,	2) as profit_margin_percentage,
count(*) as rows_in_band
from sales_data
group by discount_band
order by discount_band;

# KPI 4: Profit Lost due to Discounting

select @margin0 := sum(profit)/nullif(sum(sales),0)
from sales_data
where discount = 0;

select 
case
when discount >= 0 and discount < 0.1 then '0-10%'
when discount >= 0.1 and discount < 0.2 then '10-20%'
when Discount >= 0.2 and Discount < 0.3 THEN '20-30%'
when Discount >= 0.3 and Discount < 0.4 THEN '30-40%'
when Discount >= 0.4 and Discount < 0.5 THEN '40-50%'
when Discount >= 0.5 and Discount < 0.6 THEN '50-60%'
when Discount >= 0.6 and Discount < 0.7 THEN '60-70%'
when Discount >= 0.7 and Discount < 0.8 THEN '70-80%'
when Discount >= 0.8 and Discount < 0.9 THEN '80-90%'
when Discount >= 0.9 and Discount <= 1.0 THEN '90-100%'
end as discount_band,
round(sum(sales),2) as Total_Sales,
round(sum(profit),2) as Actual_Profit,
round((sum(Profit)/	nullif(sum(Sales), 0)) * 100 ,	2) as Actual_Margin_Percentage,
round(@margin0 * 100, 2) as Baseline_Margin_Percentage,
round((sum(sales) * @margin0) - sum(profit), 2) as Estimated_Profit_Lost
from sales_data
group by discount_band
order by discount_band;





# OBJECTIVE 3: Regional and Geographic Performance

# KPI 1: Sales by Region

select Region, round(sum(sales), 2) as total_sales
from sales_data
group by Region
order by total_sales;

# KPI 2: Profit by Region

select Region, round(sum(profit), 2) as total_profit
from sales_data
group by Region
order by total_profit;


# KPI 3: Profit Margin by Region (%)

select Region, round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin
from sales_data
group by Region
order by profit_margin;

# KPI 4: Sales per Customer by Region

select Region, round(sum(sales)/ nullif(count(distinct(Customer_ID)), 0), 2) as Sales_per_Customer
from sales_data
group by Region
order by Sales_per_Customer;

# KPI 5: Top 5 States by Profit

select state, round(sum(profit), 2) as total_profit
from sales_data
group by state
order by total_profit desc
limit 5;



# Objective 4: Customer/Segment Profitability and Retention
# Segment-Level Analysis

	# KPI 1: Total Customer by segment
    
select Segment, count(distinct(Customer_ID)) as total_customers
from sales_data
group by Segment
order by total_customers desc;

	# KPI 2: Total Sales by segment
    
select Segment, round(sum(Sales), 2) as total_sales
from sales_data
group by Segment
order by total_sales desc;

	# KPI 3: Total Profit by Segment

select Segment, round(sum(Profit), 2) as total_profit
from sales_data
group by Segment
order by total_profit desc;
    
	# KPI 4: Profit Margin (%) by Segment

select Segment, round(sum(Profit)/ nullif(sum(Sales), 0) * 100, 2) as profit_margin
from sales_data
group by Segment
order by profit_margin desc;

	# KPI 5: Average Sales per Customer by Segment

select Segment, round(sum(Sales)/ nullif(count(distinct(Customer_ID)), 0), 2) as avg_sales_per_customer
from sales_data
group by Segment
order by avg_sales_per_customer desc;


# Customer-Level Analysis

	# KPI 1: Top 7 Customers by Profit

select Customer_ID, Customer_Name, Round(Sum(Profit), 2) as total_profit
from sales_data
group by Customer_ID, Customer_Name
order by total_profit desc
limit 7;

	# KPI 2: Sales Frequency per Customer

select Customer_ID, Customer_Name, count(distinct Order_ID) as Order_Count
from sales_data
group by Customer_ID, Customer_Name
order by Order_Count desc
limit 7;

	# KPI 3: Profit Margin per Customer
    
select Customer_ID, Customer_Name, 
Round((Sum(Profit)/ nullif(Sum(Sales),0)) * 100, 2) as profit_margin
from sales_data
group by Customer_ID, Customer_Name
order by profit_margin desc
limit 20;




# Objective 5: Category/Product Performance

	# KPI 1: Sales by Category
select Category, round(sum(Sales), 2) as Total_Sales
from sales_data
group by Category
order by Total_Sales desc;
    
	# KPI 2: Profit by Category
select Category, round(sum(Profit), 2) as Total_Profit
from sales_data
group by Category
order by Total_Profit desc;
    
	# KPI 3: Profit Margin by Category(%)
select Category, round((sum(Profit)/nullif(sum(Sales),0)) * 100, 2) as Total_Profit
from sales_data
group by Category
order by Total_Profit desc;    
    
	# KPI 4: Sales per Customer by Category
select Category, round(sum(Sales)/nullif(count(distinct(Customer_ID)), 0), 2) as sales_per_customer
from sales_data
group by Category
order by sales_per_customer;




	# KPI 5: Sales by Sub-Category
select Sub_Category, round(sum(Sales), 2) as Total_Sales
from sales_data
group by Sub_Category
order by Total_Sales desc;
    
	# KPI 6: Profit by Sub-Category
select Sub_Category, round(sum(Profit), 2) as Total_Profit
from sales_data
group by Sub_Category
order by Total_Profit desc;
    
	# KPI 7: Profit Margin by Sub-Category(%)
select Sub_Category, round((sum(Profit)/nullif(sum(Sales),0)) * 100, 2) as Total_Profit
from sales_data
group by Sub_Category
order by Total_Profit desc;    
    
	# KPI 8: Sales per Customer by Sub-Category
select Sub_Category, round(sum(Sales)/nullif(count(distinct(Customer_ID)), 0), 2) as sales_per_customer
from sales_data
group by Sub_Category
order by sales_per_customer;






	# KPI 9: Sales by Product
select Product_ID, Product_Name, round(sum(Sales), 2) as Total_Sales
from sales_data
group by Product_ID, Product_Name
order by Total_Sales desc;
    
	# KPI 10: Profit by Product
select Product_ID, Product_Name, round(sum(Profit), 2) as Total_Profit
from sales_data
group by Product_ID, Product_Name
order by Total_Profit desc;
    
	# KPI 11: Profit Margin by Product(%)
select Product_ID, Product_Name, round((sum(Profit)/nullif(sum(Sales),0)) * 100, 2) as Total_Profit
from sales_data
group by Product_ID, Product_Name
order by Total_Profit desc;   
    
	#KPI 12: Sales per Customer by Product
select Product_ID, Product_Name, 
round(sum(Sales)/nullif(count(distinct(Customer_ID)), 0), 2) as sales_per_customer
from sales_data
group by Product_ID, Product_Name
order by sales_per_customer;
    
	#KPI 13: Top 5 Products by Profit
select Product_ID, Product_Name, round(sum(Profit), 2) as total_profit
from sales_data
group by Product_ID, Product_Name
order by total_profit desc
limit 5;






