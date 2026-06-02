-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT 
	DISTINCT(market)
FROM dim_customer
WHERE customer = "Atliq Exclusive" 
		AND region = 'APAC';
        
-- What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
-- unique_products_2020, unique_products_2021, percentage_chg
WITH unique_products AS (
	SELECT
		COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN product_code END) AS unique_products_2020,
		COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN product_code END) AS unique_products_2021
	FROM fact_sales_monthly)
 SELECT 
	* ,
    CONCAT(ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2),"%") AS percentage_chg
 FROM unique_products;
 
-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
-- 2 fields, segment & product_count

SELECT 
	segment,
    COUNT(DISTINCT(product_code)) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields:
-- segment, product_count_2020, product_count_2021, difference

WITH unique_products AS (
	SELECT
		p.segment,
		COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN s.product_code END) AS product_count_2020,
		COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN s.product_code END) AS product_count_2021
	FROM fact_sales_monthly s
    JOIN dim_product p
    USING (product_code)
    GROUP BY p.segment
    )
 SELECT 
	* ,
    (product_count_2021-product_count_2020) AS difference
 FROM unique_products
 ORDER BY difference DESC;
 
 -- 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
-- product_code, product, manufacturing_cost
   
SELECT
	p.product_code,
    p.product,
    CONCAT("$ ",ROUND(m.manufacturing_cost,2)) AS manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p
USING (product_code)
WHERE m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
	OR m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- tried using cte, not working
-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields: customer_code, customer, average_discount_percentage
SELECT
	c.customer_code,
    c.customer,
    CONCAT(ROUND(AVG(pre_invoice_discount_pct*100),2)," %") AS average_discount_percentage
 FROM dim_customer c
 JOIN fact_pre_invoice_deductions pre
 USING (customer_code)
 WHERE fiscal_year = 2021 AND market = "india"
 GROUP BY c.customer_code,c.customer
 ORDER BY AVG(pre_invoice_discount_pct) DESC
 LIMIT 5;
    
    -- IF I GIVE average_discount_percentage in ORDER BY, it is giving wrong o/p order, may be coz of % sign added
-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions. The final report contains these columns: Month, Year, Gross sales Amount
SELECT 
	MONTHNAME(date) as month,
    YEAR(date) AS YEAR,
   	CONCAT("$",ROUND(SUM(gross_price*sold_quantity)/1000000,2)) AS Gross_sales_amount_mln
FROM fact_sales_monthly
JOIN fact_gross_price
	USING (product_code,fiscal_year)
JOIN dim_customer
	USING (customer_code)
WHERE customer = "Atliq Exclusive"
GROUP BY YEAR,MONTH(DATE),MONTHNAME(date)
ORDER BY YEAR;

-- year(date) and order by year gives the correctorder of results

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields:
-- sorted by the total_sold_quantity, Quarter, total_sold_quantity
SELECT 
	CASE 
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
        WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
        WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
        WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
    END AS Quarter,    
	SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
-- channel, gross_sales_mln, percentage/*

WITH CTE AS (
SELECT 
	c.channel,
    ROUND(SUM((gross_price*sold_quantity))/1000000,2) AS gross_sales_mln
FROM fact_sales_monthly s
JOIN dim_customer c
	USING (customer_code)
JOIN fact_gross_price g
		USING (product_code)
 WHERE s.fiscal_year = 2021
 GROUP BY c.channel
 ORDER BY gross_sales_mln DESC)
 SELECT 
	*,
	CONCAT(ROUND(gross_sales_mln*100/SUM(gross_sales_mln) over(),2)," %") as percentage
FROM CTE;

-- use window function over() (had to refer back to course material)
/*Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields:
division, product_code, product, total_sold_quantity, rank_order */ 


WITH CTE AS(
SELECT
	p.division,
    p.product_code,
    p.product,
    SUM(sold_quantity) AS total_sold_quantity,
    DENSE_RANK() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS rank_order
FROM dim_product P
JOIN fact_sales_monthly S
		USING (product_code)
GROUP BY   p.division,    p.product_code, p.product
)
SELECT 
	*
 FROM CTE
 WHERE rank_order <=3
 
-- 1. Generate a yearly report for 'croma' customer where the output contains these fields: 
--           fiscal_year, yearly_gross_sales,    make sure that yearly_gross_sales are in millions (divide the total by 1000000)

Query:
    -- Step1: Get the customer code for croma
            SELECT 
                customer_code 
            FROM dim_customer
            WHERE customer = 'croma';


     -- step2: Generate the yearly report
             SELECT
                 s.fiscal_year,
                 ROUND(SUM(g.gross_price * s.sold_quantity)/1000000,2) as yearly_gross_sales
             FROM fact_sales_monthly s
             JOIN fact_gross_price g
				USING(fiscal_year,product_code)
			 WHERE customer_code=90002002
             GROUP BY fiscal_year
             ORDER BY fiscal_year;

-- Generate a report which contain fiscal year and also the number of unique products sold in that year. 
-- This helps Atliq hardwares regarding the development of new products and its growth year on year

-- Query:
    SELECT
	    fiscal_year,
	    COUNT(DISTINCT product_code) as unique_product_count
   FROM fact_sales_monthly 

    GROUP BY fiscal_year;

