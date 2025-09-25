CREATE DATABASE ecommerce_1;
USE ecommerce_1;

SELECT * FROM order_items;

SELECT* FROM orders;

SELECT * FROM staff;

SELECT * FROM customers;

RENAME TABLE `products (2)` TO products;

SELECT * FROM products;

-- create view
CREATE OR REPLACE VIEW order_item_facts AS
SELECT
  oi.order_id,
  o.order_date,
  o.customer_id,
  o.store_id,
  o.staff_id,
  o.payment_method,
  oi.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  oi.quantity,
  oi.unit_price         AS sold_price,
  COALESCE(oi.discount, 0) AS discount,
  ROUND((oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))),2) AS revenue,
  ROUND((oi.quantity * p.cost_price),2) AS cost,
  ROUND(((oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) - (oi.quantity * p.cost_price)),2) AS profit
FROM order_items oi
JOIN orders o      ON oi.order_id = o.order_id
JOIN products p    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed';

SELECT * FROM order_item_facts;

-- Data Quality check (High discount or negative profit)
SELECT order_id, product_id, quantity, sold_price, discount, revenue, cost, profit
FROM order_item_facts
WHERE discount > 0.5 OR profit < 0
ORDER BY profit ASC
LIMIT 50;

-- Total revenue, total profit, total customers, total orders and Average order value (AOV)
WITH agg AS (
	SELECT 
		ROUND(SUM(revenue),2) AS total_revenue,
        ROUND(SUM(profit),2) AS total_profit,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customer
	FROM order_item_facts
    )
    SELECT
		total_revenue,
        total_profit,
        total_orders,
        total_customer,
        ROUND(total_revenue/COALESCE(total_orders,0),2) AS avg_order_value
	FROM agg;
	
-- Revenue, profit and %profit margin by category, 
SELECT
  category,
  ROUND(SUM(revenue), 2) AS revenue,
  ROUND(SUM(profit), 2)  AS profit,
  ROUND(100.0 * SUM(profit) / NULLIF(SUM(revenue), 0), 2) AS profit_margin_pct
FROM order_item_facts
GROUP BY category
ORDER BY revenue DESC;

-- Ranking Top Products by Revenue and Profit
With prod AS (
	SELECT
		product_name,
		product_id,
		ROUND(SUM(revenue), 2) AS total_revenue,
		ROUND(SUM(profit), 2) AS total_profit
	FROM order_item_facts
	GROUP BY product_name, product_id
    )
SELECT 
	product_id,
    product_name,
    total_revenue,
    total_profit,
    RANK () OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK () OVER (ORDER BY total_profit DESC) AS profit_rank
FROM prod;

-- Discount Impact (Buckets and Margin by discount level)
SELECT 
	CASE
		WHEN discount = 0 THEN "No Discount"
        WHEN discount <= 0.05 THEN "Small (<=5%)"
        WHEN discount <= 0.10 THEN "Medium (<=10%)"
        ELSE "Large (>10%)"
	END AS discount_buckets,
    COUNT(DISTINCT order_id) AS orders_impacted,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / COALESCE (SUM(revenue), 0)) AS profit_margin
FROM order_item_facts
GROUP BY discount_buckets
ORDER BY total_revenue DESC;
        
-- Month on month growth
WITH monthly AS (
	SELECT
		DATE_FORMAT (order_date, "%Y-%M") AS year_months,
        ROUND(SUM(revenue),2) AS total_revenue,
        ROUND(SUM(profit),2) AS total_profit
	FROM order_item_facts
    GROUP BY year_months
)
SELECT
	year_months,
    total_revenue,
    total_profit,
    ROUND(LAG(total_revenue) OVER (ORDER BY year_months),2) AS prev_revenue,
    ROUND( 100.0 * (total_revenue - NULLIF(LAG(total_revenue) OVER (ORDER BY year_months), 0)) / NULLIF(LAG(total_revenue) OVER (ORDER BY year_months), 0), 2) AS MOM_revenue
FROM monthly
GROUP BY year_months;

-- Customer lifetime value (High value customers and segmenting them into tiers)
WITH clv AS (
	SELECT c.customer_id,
		CONCAT(c.first_name," ",c.last_name) AS customer_name,
        COUNT(DISTINCT oi.order_id) AS order_count,
        ROUND(SUM(oi.revenue), 2) AS lifetime_revenue,
        MAX(o.order_date) AS last_order_date,
        MIN(o.order_date) AS first_order_date
	FROM order_item_facts oi 
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON oi.customer_id = c.customer_id
    GROUP BY customer_id, customer_name
    )
SELECT customer_id,
	customer_name,
    order_count,
    lifetime_revenue,
    CASE
		WHEN lifetime_revenue >= 1000 THEN "Platinum"
        WHEN lifetime_revenue >= 500 THEN "Gold"
        WHEN lifetime_revenue >= 200 THEN "Silver"
        ELSE "Bronze"
    END AS customer_tier
FROM clv
GROUP BY customer_id, customer_name
ORDER BY lifetime_revenue DESC
LIMIT 20;
		
-- Repeat purchase rate and retention (who bought >1 time)
WITH cust_order_count AS (
	SELECT customer_id,
		COUNT(DISTINCT order_id) AS order_count
	FROM order_item_facts
    GROUP BY customer_id
    )
SELECT
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeated_customer,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_purchase,
    COUNT(*) AS total_customer,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS Repeat_rate
FROM cust_order_count;

-- Staff performance
SELECT s.staff_id,
	CONCAT(s.first_name, " ", s.last_name) AS staff_name,
    ROUND(SUM(oi.revenue),2) AS revenue,
    ROUND(SUM(oi.profit),2) AS profit
FROM order_item_facts oi
JOIN staff s ON oi.staff_id = s.staff_id
GROUP BY staff_id, staff_name
ORDER BY revenue DESC;

-- Profit Margin Waterfall
WITH totals AS (
  SELECT
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_sales,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount), 2) AS total_discounts,
    ROUND(SUM(oi.quantity * p.cost_price), 2) AS total_cost
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  JOIN products p ON oi.product_id = p.product_id
  WHERE o.order_status='Completed'
)
SELECT
  gross_sales,
  total_discounts,
  gross_sales - total_discounts AS net_sales,
  total_cost,
  ROUND((gross_sales - total_discounts) - total_cost, 2) AS operating_profit
FROM totals;

    
SELECT * FROM order_item_facts;

-- Summary table
CREATE TABLE monthly_summary AS
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS years_months,
  ROUND(SUM(revenue),2) AS revenue,
  ROUND(SUM(profit),2) AS profit,
  COUNT(DISTINCT order_id) AS orders,
  COUNT(DISTINCT customer_id) AS customers
FROM order_item_facts
GROUP BY years_months;

SELECT * FROM monthly_summary;

-- Repeat customer
WITH repeat_cust AS(
	SELECT *,
    ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY order_date) AS purchase_number
    FROM order_item_facts
    )
SELECT 
	order_id,
    customer_id,
    order_date
    revenue,
    CASE
		WHEN purchase_number > 1 THEN 1 ELSE 0
    END AS repeat_order_flag
    FROM repeat_cust;
    
SELECT * FROM order_item_facts;
    
        


