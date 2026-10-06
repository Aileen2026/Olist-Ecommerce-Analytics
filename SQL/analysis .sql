-- 业务问题与分析查询


--  1. 月度营收趋势随时间如何变化？
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    SUM(oi.price + oi.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- 2. 按营收排名前 10 的产品品类是哪些？

SELECT 
    pct.product_category_name_english,
    SUM(oi.price + oi.freight_value) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
JOIN olist_orders_dataset o ON oi.order_id = o.order_id AND o.order_status = 'delivered'
GROUP BY pct.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;


-- 3. 按支付方式划分的平均订单价值（AOV）是多少？
SELECT 
    pay.payment_type,
    AVG(pay.order_total) AS avg_order_value,
    COUNT(*) AS order_count
FROM (
    SELECT order_id, 
           SUM(payment_value) AS order_total,
           MAX(payment_type) AS payment_type
    FROM olist_order_payments_dataset
    GROUP BY order_id
) pay
JOIN olist_orders_dataset o ON pay.order_id = o.order_id AND o.order_status = 'delivered'
GROUP BY pay.payment_type
ORDER BY avg_order_value DESC;


-- 4. 哪些州贡献的营收最多？
    
SELECT 
    c.customer_state,
    SUM(oi.price + oi.freight_value) AS revenue,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;

-- 5. 复购率是多少？
SELECT 
    CASE WHEN order_count = 1 THEN '1 order' 
         WHEN order_count = 2 THEN '2 orders' 
         ELSE '3+ orders' END AS purchase_frequency,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_customers
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
    GROUP BY c.customer_unique_id
) cust
GROUP BY purchase_frequency;

-- 6. 配送绩效如何（延迟天数 vs 准时送达）？
SELECT 
    CASE 
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 0 THEN 'On time or early'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS order_count,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days
FROM olist_orders_dataset o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 1;

-- 7. 按品类划分，运费成本占订单金额的百分比是多少？

SELECT 
    pct.product_category_name_english,
    SUM(oi.freight_value) AS total_freight,
    SUM(oi.price) AS total_product_value,
    ROUND(100.0 * SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0), 2) AS freight_pct
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
JOIN olist_orders_dataset o ON oi.order_id = o.order_id AND o.order_status = 'delivered'
GROUP BY pct.product_category_name_english
HAVING total_product_value > 0
ORDER BY freight_pct DESC
LIMIT 15;


-- 8. 收到低评分（1–2 星）的订单占比是多少？

SELECT 
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_reviews
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;


-- 9. 哪些品类的低评分评价最多？

SELECT 
    pct.product_category_name_english,
    COUNT(*) AS low_rating_count,
    ROUND(AVG(r.review_score), 2) AS avg_score
FROM olist_order_reviews_dataset r
JOIN olist_order_items_dataset oi ON r.order_id = oi.order_id
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE r.review_score <= 2
GROUP BY pct.product_category_name_english
ORDER BY low_rating_count DESC
LIMIT 10;

-- 10. 客户如何支付（信用卡、boleto、代金券等）？

SELECT 
    payment_type,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(payment_value) AS total_value,
    ROUND(100.0 * SUM(payment_value) / SUM(SUM(payment_value)) OVER(), 2) AS pct_revenue
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_value DESC;



