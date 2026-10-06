
USE ecommerce;

-- =============================================
-- 语义层视图（事实表与维度表）
-- =============================================
-- 这些视图为 BI 工具和分析提供了一个干净、可复用的层，
-- 因此查询可以引用 fact_* 和 dim_*，而不必引用原始的 olist_* 表。

-- =============================================
-- 维度：客户
-- 粒度：每个逻辑客户一行（customer_unique_id）
CREATE OR REPLACE VIEW dim_customer AS
SELECT
    c.customer_unique_id              AS customer_key,
    MIN(c.customer_id)                AS sample_customer_id,   -- one physical id per unique customer
    MAX(c.customer_city)              AS city,
    MAX(c.customer_state)             AS state,
    MIN(o.order_purchase_timestamp)   AS first_order_date,
    MAX(o.order_purchase_timestamp)   AS last_order_date,
    COUNT(DISTINCT o.order_id)        AS lifetime_orders
FROM olist_customers_dataset c
LEFT JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_unique_id;


-- =============================================
-- 维度：产品
-- 粒度：每个产品一行
-- =============================================
CREATE OR REPLACE VIEW dim_product AS
SELECT
    p.product_id                      AS product_key,
    p.product_category_name,
    pct.product_category_name_english AS category_english,
    p.product_name_lenght             AS name_length,
    p.product_description_lenght      AS description_length,
    p.product_photos_qty              AS photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation pct
  ON p.product_category_name = pct.product_category_name;


-- =============================================
-- 事实：订单
-- 粒度：每个订单一行
-- =============================================
CREATE OR REPLACE VIEW fact_orders AS
SELECT
    o.order_id,
    c.customer_unique_id          AS customer_key,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE
        WHEN o.order_status = 'delivered' THEN 1
        ELSE 0
    END AS is_delivered
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
  ON o.customer_id = c.customer_id;


-- =============================================
-- 事实：订单商品项
-- 粒度：每个订单商品项一行（order_id, order_item_id）
-- =============================================
CREATE OR REPLACE VIEW fact_order_items_enriched AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id              AS product_key,
    c.customer_unique_id       AS customer_key,
    o.order_purchase_timestamp,
    o.order_status,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS line_revenue,
    c.customer_state,
    dp.category_english
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
  ON oi.order_id = o.order_id
JOIN olist_customers_dataset c
  ON o.customer_id = c.customer_id
LEFT JOIN dim_product dp
  ON oi.product_id = dp.product_key;


