
select * from [dbo].[olist_customers_dataset]
select * from [dbo].[olist-geolocation-dataset]
select * from [dbo].[olist_order_items_dataset]
select * from [dbo].[olist_order_payments_dataset]
select * from [dbo].[olist_order_reviews_dataset]
select * from [dbo].[olist_orders_dataset]
select * from [dbo].[olist_products_dataset]
select * from [dbo].[olist_sellers_dataset]
------------------------------------------------------------------------------------------------------------------------------------
select COUNT(distinct([customer_city]))
from [dbo].[olist_customers_dataset];
------------------------------------------------------------------------------------------------------------------------------------
--Total Revenue Calculation: Calculated the total revenue generated from the Order_payment data in the table.
SELECT SUM(payment_value) Total_Revenue
FROM [dbo].[olist_order_payments_dataset];
------------------------------------------------------------------------------------------------------------------------------------
--Top-Selling Branch Identification: Identified the branch (city) with the highest total sales revenue.
CREATE VIEW Top_Branch AS
		SELECT customer_city, customer_state, SUM(OP.payment_value) Total_Revenue
		FROM [dbo].[olist_customers_dataset] C
		JOIN [dbo].[olist_orders_dataset] O
		ON C.customer_id = O.customer_id
		JOIN [dbo].[olist_order_payments_dataset] OP
		ON O.order_id = OP.order_id
		GROUP BY C.customer_city, customer_state ;
SELECT TOP 5 customer_city, Total_Revenue
FROM Top_Branch
ORDER BY Total_Revenue DESC;
------------------------------------------------------------------------------------------------------------------------------------
--Number Of Orders Per Order Status;
SELECT  order_status, COUNT(order_Status) Number_Of_Orders
FROM [dbo].[olist_orders_dataset]
GROUP BY order_status
ORDER BY Number_Of_Orders  DESC;
------------------------------------------------------------------------------------------------------------------------------------
--Most Popular Payment Method: Identified the most popular payment method among customers.
SELECT payment_type, COUNT(*) AS num_payments
FROM [dbo].[olist_order_payments_dataset]
GROUP BY payment_type
ORDER BY num_payments DESC;
------------------------------------------------------------------------------------------------------------------------------------
--Number Of Orders Per Day of week! 
SELECT DATENAME(weekday, order_purchase_timestamp) AS DayName
,COUNT(*) AS num_sales
FROM [dbo].[olist_orders_dataset] O
GROUP BY DATENAME(weekday, order_purchase_timestamp)
ORDER BY num_sales DESC;
------------------------------------------------------------------------------------------------------------------------------------
---What are the top-selling product categories?
SELECT top 10 product_category_name ,round (SUM([price]), 2) Total_sales
FROM [dbo].[olist_order_items_dataset] oi
JOIN [dbo].[olist_products_dataset] p 
ON oi.product_id =p.product_id
GROUP BY p.product_category_name
Order BY Total_sales DESC;
-- end
------------------------------------------------------------------------------------------------------------------------------------
--Which sellers generate the highest revenue?
SELECT top 10 [seller_names] ,round (SUM([payment_value]), 2) Total_sales
FROM [dbo].[olist_order_items_dataset] oi
JOIN [dbo].[olist_order_payments_dataset] py 
ON oi.order_id =py.order_id
join [dbo].[olist_sellers_dataset] s
on oi.seller_id = s.seller_id
GROUP BY [seller_names]
Order BY Total_sales DESC;
------------------------------------------------------------------------------------------------------------------------------------
--How does the total revenue change over time (monthly, yearly)?
SELECT month([order_purchase_timestamp]) month_name, year([order_purchase_timestamp]) year_name ,round (SUM([payment_value]), 2) Total_sales
FROM [dbo].[olist_orders_dataset]o
JOIN [dbo].[olist_order_payments_dataset] py 
ON o.order_id =py.order_id
GROUP BY month([order_purchase_timestamp]), year([order_purchase_timestamp])
Order BY month([order_purchase_timestamp]), year([order_purchase_timestamp]) DESC;
---------------------
SELECT year([order_purchase_timestamp]) year_name,round (SUM([payment_value]), 2) Total_sales
FROM [dbo].[olist_orders_dataset]o
JOIN [dbo].[olist_order_payments_dataset] py 
ON o.order_id =py.order_id
GROUP BY year([order_purchase_timestamp])
Order BY Total_sales DESC;
------------------------------------------------------------------------------------------------------------------------------------
--What is the average order value for each product category?
SELECT TOP 10 [product_category_name], ROUND(AVG([payment_value]), 2) AS Avg_order_value
FROM [dbo].[olist_products_dataset] p
JOIN [dbo].[olist_order_items_dataset] oi ON p.product_id = oi.product_id
JOIN [dbo].[olist_order_payments_dataset] py ON oi.order_id = py.order_id
GROUP BY [product_category_name]
ORDER BY Avg_order_value DESC;
------------------------------------------------------------------------------------------------------------------------------------
--What is the distribution of customer locations? Which cities or states have the highest number of customers?
SELECT TOP 10 [geolocation_city], COUNT([customer_id]) AS total_customers
FROM [dbo].[olist-geolocation-dataset] g
JOIN [dbo].[olist_customers_dataset] c
ON g.[geolocation_zip_code_prefix] = c.customer_zip_code_prefix
GROUP BY 
    g.[geolocation_city];
------------------------------------------------------------------------------------------------------------------------------------
 --How many orders does the average customer place, and how does that differ across regions?
CREATE VIEW v_customr_cities AS
SELECT 
    [geolocation_city], 
    CAST(COUNT([customer_id]) AS BIGINT) AS total_customers
FROM 
    [dbo].[olist-geolocation-dataset] g
JOIN 
    [dbo].[olist_customers_dataset] c
    ON g.geolocation_city = c.customer_city
GROUP BY 
    g.[geolocation_city];

SELECT * 
FROM v_customr_cities
ORDER BY total_customers DESC;
------------------------------------------------------------------------------------------------------------------------------------
--What do customers use as the most common payment method?
create view v_most_payment_method as
select [payment_type], count ([customer_unique_id]) as total_customers
from [dbo].[olist_order_payments_dataset] p
join [dbo].[olist_orders_dataset] o
on p.order_id = o.order_id
join [dbo].[olist_customers_dataset] c
on o.customer_id = c.customer_id
group by [payment_type];

select * from v_most_payment_method
order by total_customers desc;

-- What is the average delivery time per product category?
create view v_delivery_per_category as
select [product_category_name], AVG(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) as avg_deliveried_time
from [dbo].[olist_products_dataset] pc
join [dbo].[olist_order_items_dataset] oi
on pc.product_id = oi.product_id
join [dbo].[olist_orders_dataset] o
on oi.order_id = o.order_id
group by [product_category_name];

select * from v_delivery_per_category
order by avg_deliveried_time desc;

--Which regions experience the longest and shortest delivery times?
create view v_regions_deliviered_time as
select [geolocation_city], AVG(cast (DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date) as bigint)) as avg_deliveried_time
from [dbo].[olist-geolocation-dataset] g
join [dbo].[olist_customers_dataset] c
on g.geolocation_city = c.customer_city
join [dbo].[olist_orders_dataset] o
on c.customer_id = o.customer_id
where 
o.order_delivered_customer_date is not null
group by [geolocation_city];

select * from v_regions_deliviered_time
order by avg_deliveried_time desc;
------------------------------------------------------------------------------------------------------------------------------------
--Is there a relationship between customer satisfaction (reviews) and delivery time?
create view v_satisfaction_deliveried_time as
select [review_comment_message], AVG(cast	(datediff(day,[order_purchase_timestamp], [order_delivered_customer_date]) as bigint)) as avg_deliveried_time
from [dbo].[olist_order_reviews_dataset] rv
join [dbo].[olist_orders_dataset] o
on rv.order_id = o.order_id
where o.order_delivered_customer_date is not null 
and [review_comment_message] is not null
group by [review_comment_message];

select * from v_satisfaction_deliveried_time
order by avg_deliveried_time desc;
------------------------------------------------------------------------------------------------------------------------------------
-- What is the average product review score for different product categories?
select*from [dbo].[olist_order_reviews_dataset]
select * from [dbo].[olist_products_dataset]

create view v_avg_product_review_score as
select [product_category_name], avg([review_score]) as avg_product_review_score
from [dbo].[olist_products_dataset] p
join [dbo].[olist_order_items_dataset] oi
on p.product_id = oi.product_id
join [dbo].[olist_order_reviews_dataset] r
on oi.order_id = r.order_id
group by [product_category_name]

select*from v_avg_product_review_score
order by avg_product_review_score desc;
------------------------------------------------------------------------------------------------------------------------------------
-- How do review scores impact customer repurchase behavior?
create view v_score_impat_purchase as
select [customer_unique_id], count(o.[order_id]) as total_purshase, sum(r.[review_score]) as avg_score
from [dbo].[olist_customers_dataset] c
join [dbo].[olist_orders_dataset] o
on c.customer_id = o.customer_id
join [dbo].[olist_order_reviews_dataset] r
on o.order_id = r.order_id
group by [customer_unique_id]
order by avg_score, total_purshase desc;
------------------------------------------------------------------------------------------------------------------------------------

 -- What is the distribution of sales across different sellers?
 select s.seller_id ,sum(oi.price*oi.order_item_id) as total_sales
 from [dbo].[olist_sellers_dataset] s
 join [dbo].[olist_order_items_dataset] oi
 on s.seller_id = oi.seller_id

 group by s.seller_id
 order by total_sales desc;
 ------------------------------------------------------------------------------------------------------------------------------------
-- Calculate the average delivery time per product category
select [product_category_name], avg(datediff(day, [order_approved_at], [order_delivered_customer_date])) as avg_delivery_time
from [dbo].[olist_products_dataset] p
join [dbo].[olist_order_items_dataset] oi
on p.[product_id] = oi.[product_id]
join [dbo].[olist_orders_dataset] o
on oi.[order_id] = o.[order_id]
where [product_category_name] is not null and
[order_approved_at] is not null and [order_delivered_customer_date] is not null
group by [product_category_name]
order by avg_delivery_time desc;
------------------------------------------------------------------------------------------------------------------------------------
--How does the seller's location impact their sales and delivery times?
select s.[seller_id], [geolocation_city], avg(cast(datediff(day, [order_approved_at], [order_delivered_customer_date])as bigint)) as avg_delivery_time
from [dbo].[olist_sellers_dataset] s
join [dbo].[olist_geolocation_dataset] g
on s.[seller_city] = g.[geolocation_city]
join [dbo].[olist_order_items_dataset] oi
on s.[seller_id] = oi.[seller_id]
join [dbo].[olist_orders_dataset] o
on oi.[order_id] = o.[order_id]
group by g.[geolocation_city], s.[seller_id]
order by avg_delivery_time desc;
------------------------------------------------------------------------------------------------------------------------------------
--What is the trend in the number of orders over time?
select COUNT([order_item_id])as the_most_order_type from [olist_order_items_dataset] 

------------------------------------------------------------------------------------------------------------------------------------
--What is the distribution of payments by payment method (e.g., credit card, debit card, etc.)?
select [payment_type] as payment_method,
count (*) as payment_distribution 
from [dbo].[olist_order_payments_dataset] 
group by [payment_type]
order by payment_distribution desc;
------------------------------------------------------------------------------------------------------------------------------------
--How does the order size (number of items) impact the payment type used?
select [payment_type] as payment_method, COUNT(*) as payment_count,
COUNT([order_item_id]) as item_no from
[dbo].[olist_order_items_dataset] oi
join [dbo].[olist_order_payments_dataset] py
on oi.order_id = py.order_id
group by [payment_type]
order by item_no desc;
------------------------------------------------------------------------------------------------------------------------------------



