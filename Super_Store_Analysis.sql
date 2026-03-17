CREATE DATABASE superstore_analysis;

USE superstore_analysis;


CREATE TABLE superstore (
    row_id INT,
    order_id VARCHAR(20),
    order_date VARCHAR(20),
    ship_date VARCHAR(20),
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code INT,
    region VARCHAR(50),
    product_id VARCHAR(20),
    category VARCHAR(100),
    sub_category VARCHAR(200),
    product_name VARCHAR(500),
    sales FLOAT,
    quantity INT,
    discount FLOAT,
    profit FLOAT
);


-- DROP TABLE superstore;


/*
SHOW VARIABLES LIKE 'secure_file_priv';

SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'local_infile';



LOAD DATA LOCAL INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Sample - Superstore-2.csv"
INTO TABLE superstore
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
*/

-- ------------------------- CHANGING Shipping and Order DATE COLUMNS TO DATE FORMAT[previously VARCHAR] ------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE superstore 
SET order_date = STR_TO_DATE(order_date, '%m/%d/%Y')
WHERE order_date LIKE '%/%';

UPDATE superstore 
SET order_date = STR_TO_DATE(order_date, '%m-%d-%Y')
WHERE order_date LIKE '__-__-____';
    
UPDATE superstore 
SET ship_date = STR_TO_DATE(ship_date, '%m/%d/%Y')
WHERE ship_date LIKE '%/%';

UPDATE superstore 
SET ship_date = STR_TO_DATE(ship_date, '%m-%d-%Y')
WHERE ship_date LIKE '__-__-____';


ALTER TABLE superstore 
MODIFY order_date DATE,
MODIFY ship_date DATE;


SELECT DISTINCT order_date
FROM superstore
LIMIT 20;
-- -------------------------------------------------- DATA VALIDATION-------------------------- 
SELECT *
FROM superstore;


SELECT COUNT(*)
FROM superstore;

/*
================================================================================================================================================================



-- ------------------------------------- SQL-Based Business Investigation -------------------------------------------------------------------------------------

/*
		SQL-based analysis was conducted to further investigate profitability
		patterns identified during the exploratory data analysis (EDA) phase.

        These queries aim to identify loss-generating products, analyze regional
        performance differences, and evaluate the impact of discounting strategies
        on overall profitability.
*/

-- -------------------- REGIONAL PROFITABILTY -----------------------------------

SELECT region,
	   ROUND(SUM(sales),2) AS total_sales,
	   ROUND(SUM(profit),2) AS total_profit,
	   ROUND(SUM(profit) / SUM(sales) * 100,2) AS profit_margin
FROM superstore
GROUP BY region
ORDER BY profit_margin DESC;

/*
This analysis compares overall sales and profit across REGIONS. 
It helps identify which markets contribute most to profitability and which regions may require operational improvements. 
*/

-- ------------------ CATEGORY PROFITABILITY -------------------------------------

SELECT category,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profit,
	SUM(profit) / SUM(sales) * 100 AS profit_margin
FROM superstore
GROUP BY category
ORDER BY total_profit ASC;

/* 
This analysis compares overall sales and profit across CATEGORY. 
It helps identify which CATEGORY contribute most to profitability and which may require operational improvements.
*/


-- ------------------- SUB-CATEGORY PROFITABILITY ---------------------------------

SELECT sub_category,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) *100,2) AS profit_margin
FROM superstore
GROUP BY sub_category
ORDER BY total_profit;

/*
This query identifies the most and least profitable product groups. 
It helps detect SUB-CATEGORIES that generate revenue but fail to maintain healthy profit margins.
*/
-- --------------------- CUSTOMER SEGMENT PROFITABILITY -----------------------------------

SELECT 
	segment,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales)*100,2) AS profit_margin
FROM superstore
GROUP BY segment
ORDER BY profit_margin DESC;

/*
This analysis evaluates profitability across different customer segments
to determine which customer groups generate the highest returns.

Understanding segment-level performance helps businesses optimize
marketing strategies and customer targeting.
*/

-- ---------------- TOP PROFITABLE CUSTOMERS ---------------------------------------------

SELECT 
	customer_name,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(sales),2) AS total_sales
FROM superstore
GROUP BY customer_name
ORDER BY total_profit DESC
LIMIT 20;





-- ----------------------------------- MONTHLY PROFITABILITY ------------------------------
SELECT 
	DATE_FORMAT(order_date, '%Y-%m') AS months,
    ROUND(SUM(profit),2) AS monthly_profit,
    ROUND(SUM(sales),2) AS monthly_sales
FROM superstore
GROUP BY months
ORDER BY months;







-- ----------------- REGION + SUB-CATEGORY PROFITABILTY -----------------------------

SELECT region, sub_category,
	ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales)*100,2) AS profit_margin	
FROM superstore
GROUP BY region, sub_category
ORDER BY total_profit;

/*
This analysis identifies specific product-region combinations that contribute to profit losses. 
By examining performance at this level, we can pinpoint exactly where the business is losing money.
*/

-- ------------------------- DISCOUNT HYPOTHESIS ---------------------------------------

SELECT 
	region,
	AVG(discount) AS avg_discount
FROM superstore
WHERE sub_category = 'Tables'
GROUP BY region
ORDER BY avg_discount DESC;


-- ------------------ WORST LOSS-MAKING PRODUCTS (SUBQUERY) -----------------------------

SELECT 
	product_name,
    category, 
    sub_category, 
    SUM(profit) AS total_loss
FROM superstore
WHERE profit < (
	SELECT AVG(profit)
	FROM superstore
)
GROUP BY product_name,category, sub_category
ORDER BY total_loss ASC
LIMIT 10;

/*
This query identifies the products generating the largest financial losses.

A subquery is used to calculate the average profit across all orders.
Products with profits below this average are then filtered and ranked
to highlight the most extreme loss-making items.

This analysis helps uncover specific products that may be harming
overall profitability due to high costs, excessive discounts,
or inefficient pricing strategies.

*/
				
-- ----------------- TOP 3 LOSS-MAKING SUB-CATEGORIES PER REGION (Window Function) ------------------------

SELECT * 
FROM (
	SELECT 
		region,
		sub_category,
		ROUND(SUM(profit),2) AS total_profit,
        ROUND(SUM(profit) / SUM(sales)*100,2) AS profit_margin,
		RANK() OVER(PARTITION BY region ORDER BY SUM(profit)) AS loss_rank
	FROM superstore
    GROUP BY region, sub_category
) ranked_losses
WHERE loss_rank<=3;

/*
This analysis ranks product sub-categories within each region based
on their total profit using a window function.

The RANK() function partitions the data by region and orders sub-categories
by their total profit, allowing us to identify the top three worst-performing
product groups in each geographic market.

This helps pinpoint where losses are concentrated geographically and
which product groups are responsible for those losses in each region

*/

-- -------------------- RUNNING PROFIT TREND --------------------------------------------
SELECT 
	order_date,
    ROUND(SUM(profit),4) AS daily_profit,
    ROUND(SUM(SUM(profit)) OVER (ORDER BY order_date),4) AS running_profit
FROM superstore
GROUP BY order_date
ORDER BY order_date ASC;

/*
This query analyzes how profit accumulates over time by calculating
a running cumulative profit using a window function.

By ordering the data by order_date and applying a cumulative SUM(),
we can observe whether profitability improves, declines, or fluctuates
throughout the dataset's time period.

This type of analysis helps detect long-term trends in financial performance
and can highlight periods where the business experienced sustained losses
or strong profitability.
*/
-- --------------------- SHIPPING TIME ANALYSIS -----------------------------------------
SELECT
	ship_mode,
    ROUND(AVG(DATEDIFF(ship_date, order_date)),2) AS avg_shipping_days
FROM superstore
GROUP BY ship_mode
ORDER BY avg_shipping_days DESC;

/*
This analysis evaluates operational efficiency by measuring the average
time taken to ship orders across different shipping modes.

Understanding shipping performance can help identify logistical delays
that may affect customer satisfaction and operational costs.
*/

-- --------------------- DISCOUNT IMPACT ANALYSIS (CTE) ---------------------------------

WITH discount_analysis AS(
	SELECT
		sub_category,
        ROUND(AVG(discount),4) AS avg_discount,
        ROUND(SUM(profit),4) AS total_profit
	FROM superstore
    GROUP BY sub_category)
SELECT *
FROM discount_analysis
ORDER BY avg_discount DESC;

/*
This analysis investigates the relationship between discount levels
and product profitability.

A Common Table Expression (CTE) is used to calculate the average discount
and total profit for each product sub-category. The results allow us to
compare discounting strategies across product groups.

If highly discounted sub-categories consistently show lower or negative
profits, it suggests that aggressive discounting may be a major driver
of financial losses.
*/

-- ---------------- DISCOUNT AND PROFITABILITY ANALYSIS ----------------------------------

SELECT
	CASE
		WHEN discount = 0 THEN 'NO DISCOUNT'
        WHEN discount > 0 AND discount <= 0.2 THEN 'LOW DISCOUNT(0-20%)'
        WHEN discount > 0.2 AND discount <= 0.5 THEN 'MEDIUM DISCOUNT(20-50%)'
        ELSE 'HIGH DISCOUNT(50%+)'
	END AS discount_band,
    
    COUNT(*) AS total_orders,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(AVG(profit),2) AS avg_profit_per_order,
    ROUND(SUM(sales) / COUNT(*),2) AS avg_order_value,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) *100,2) AS profit_margin
FROM superstore
GROUP BY discount_band
ORDER BY profit_margin;

/*
This query groups orders into discount bands to evaluate how different
levels of discounting impact overall profitability.

Using a CASE statement, orders are categorized into four groups:
No Discount, Low Discount, Medium Discount, and High Discount.

By comparing total sales, average profit per order,average order value ,total profit, and profit margins across
these discount levels, we can determine whether higher discounts
lead to reduced profitability.

This analysis helps validate the hypothesis that excessive discounting
may be a key contributor to the company's financial losses.
*/

-- -------------------------------------------------------------------------------------------------------------

/*
==================================================================================================
                                      FINAL INSIGHT SUMMARY
==================================================================================================

Overall company profit margin stands at 12.47% across $2.29M 
in total revenue. However, this masks significant regional and 
category-level losses identified through the analysis.

1. REGIONAL PERFORMANCE
   Central region is the weakest market with a profit margin of 
   only 7.92%, compared to West (14.94%), East (13.48%), and 
   South (11.93%). Despite being the 3rd highest revenue region 
   at $501K in sales, it generates only $39.7K in profit.

2. CATEGORY PERFORMANCE
   Furniture is the only category generating near-zero returns 
   at a 2.49% profit margin, far below Technology (17.4%) and 
   Office Supplies (17.0%). Within Furniture, Tables account for 
   the largest loss at -$17,725, followed by Bookcases at -$3,472.

3. ROOT CAUSE — DISCOUNTING
   Central region applies the highest average discount on 
   Furniture at 29.7%, nearly double that of East (15.4%), 
   South (12.2%), and West (13.1%). The discount-profit 
   correlation for Central Furniture is -0.48, with Tables 
   specifically showing a strong negative correlation of -0.796, 
   indicating that discounting is the primary driver of losses.

4. DISCOUNT BAND ANALYSIS
   Orders with zero discount maintain healthy profit margins,
   while medium discount (20-50%) and high discount (50%+) 
   bands show significantly reduced or negative margins —
   confirming that aggressive discounting directly erodes 
   profitability.

CONCLUSION
Losses in the Central region are primarily driven by excessive 
discounting on Furniture, particularly Tables. Capping discounts 
on Tables and Bookcases in the Central region represents the 
highest-impact intervention to improve overall profitability.
=============================================================
*/


/*
=======================================================================
                    BUSINESS RECOMMENDATIONS
=======================================================================
                    
1. Introduce discount caps on Furniture products in the Central region
   to prevent excessive margin erosion.

2. Reevaluate pricing strategy for Tables and Bookcases which
   consistently generate losses despite strong sales volume.

3. Prioritize inventory and marketing investment toward
   high-margin Technology products.

4. Monitor discount usage across regions to ensure
   promotional strategies do not undermine profitability.                    
                    
========================================================================
*/
































