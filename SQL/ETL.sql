USE ecommerce;

-- 暂时禁用外键检查，以便更轻松地进行设置
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================
-- 1. 产品类别翻译表
-- =============================================
ALTER TABLE product_category_name_translation
    MODIFY COLUMN product_category_name         VARCHAR(100) NOT NULL,
    MODIFY COLUMN product_category_name_english VARCHAR(100) NOT NULL;

ALTER TABLE product_category_name_translation
    ADD PRIMARY KEY (product_category_name);

-- =============================================
-- 2. 产品表
-- =============================================
ALTER TABLE olist_products_dataset
    MODIFY COLUMN product_id                 VARCHAR(32)    NOT NULL,
    MODIFY COLUMN product_category_name      VARCHAR(100)   NULL,
    MODIFY COLUMN product_name_lenght        INT            NULL DEFAULT 0,
    MODIFY COLUMN product_description_lenght INT            NULL DEFAULT 0,
    MODIFY COLUMN product_photos_qty         INT            NULL DEFAULT 0,
    MODIFY COLUMN product_weight_g           DECIMAL(10,2)  NULL,
    MODIFY COLUMN product_length_cm          DECIMAL(10,2)  NULL,
    MODIFY COLUMN product_height_cm          DECIMAL(10,2)  NULL,
    MODIFY COLUMN product_width_cm           DECIMAL(10,2)  NULL;

ALTER TABLE olist_products_dataset
    ADD PRIMARY KEY (product_id);

ALTER TABLE olist_products_dataset
    ADD CONSTRAINT FK_products_category
        FOREIGN KEY (product_category_name)
        REFERENCES product_category_name_translation (product_category_name);

CREATE INDEX IX_products_category
    ON olist_products_dataset (product_category_name);

-- =============================================
-- 3. 卖家表
-- =============================================
ALTER TABLE olist_sellers_dataset
    MODIFY COLUMN seller_id              VARCHAR(32)   NOT NULL,
    MODIFY COLUMN seller_zip_code_prefix VARCHAR(5)    NOT NULL,
    MODIFY COLUMN seller_city            VARCHAR(100)  NOT NULL,
    MODIFY COLUMN seller_state           VARCHAR(2)    NOT NULL;

ALTER TABLE olist_sellers_dataset
    ADD PRIMARY KEY (seller_id);

CREATE INDEX IX_sellers_zip
    ON olist_sellers_dataset (seller_zip_code_prefix);

CREATE INDEX IX_sellers_state
    ON olist_sellers_dataset (seller_state);

-- =============================================
-- 4. 客户表
-- =============================================
ALTER TABLE olist_customers_dataset
    MODIFY COLUMN customer_id              VARCHAR(32)   NOT NULL,
    MODIFY COLUMN customer_unique_id       VARCHAR(32)   NOT NULL,
    MODIFY COLUMN customer_zip_code_prefix VARCHAR(5)    NOT NULL,
    MODIFY COLUMN customer_city            VARCHAR(100)  NOT NULL,
    MODIFY COLUMN customer_state           VARCHAR(2)    NOT NULL;

ALTER TABLE olist_customers_dataset
    ADD PRIMARY KEY (customer_id);

CREATE INDEX IX_customers_unique
    ON olist_customers_dataset (customer_unique_id);

CREATE INDEX IX_customers_zip
    ON olist_customers_dataset (customer_zip_code_prefix);

CREATE INDEX IX_customers_state
    ON olist_customers_dataset (customer_state);

-- =============================================
-- 5. 地理位置表
-- =============================================
ALTER TABLE olist_geolocation_dataset
    MODIFY COLUMN geolocation_zip_code_prefix VARCHAR(5)     NOT NULL,
    MODIFY COLUMN geolocation_lat             DECIMAL(10,8)  NULL,
    MODIFY COLUMN geolocation_lng             DECIMAL(11,8)  NULL,
    MODIFY COLUMN geolocation_city            VARCHAR(100)   NULL,
    MODIFY COLUMN geolocation_state           VARCHAR(2)     NULL;

CREATE INDEX IX_geolocation_zip
    ON olist_geolocation_dataset (geolocation_zip_code_prefix);

CREATE INDEX IX_geolocation_state
    ON olist_geolocation_dataset (geolocation_state);

-- =============================================
-- 6. 订单表
-- =============================================
-- CSV 日期：d/m/YYYY H:MM（例如 2/10/2017 10:56）。将文本转换为 DATETIME/DATE。
-- STR_TO_DATE 格式：%e/%c/%Y %k:%i（日、月、年、小时、分钟）。

-- 确保关键列使用 VARCHAR（而不是 TEXT/BLOB），以便主键/外键/索引能够正常工作
ALTER TABLE olist_orders_dataset
    MODIFY COLUMN order_id    VARCHAR(32)  NOT NULL,
    MODIFY COLUMN customer_id VARCHAR(32)  NOT NULL,
    MODIFY COLUMN order_status VARCHAR(30) NULL;

SET @orders_date_is_text = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'ecommerce' AND TABLE_NAME = 'olist_orders_dataset'
    AND COLUMN_NAME = 'order_purchase_timestamp' AND DATA_TYPE IN ('varchar', 'text', 'char')
);

SET @sql = IF(@orders_date_is_text > 0,
    'ALTER TABLE olist_orders_dataset
        ADD COLUMN order_purchase_timestamp_dt DATETIME NULL,
        ADD COLUMN order_approved_at_dt DATETIME NULL,
        ADD COLUMN order_delivered_carrier_date_dt DATETIME NULL,
        ADD COLUMN order_delivered_customer_date_dt DATETIME NULL,
        ADD COLUMN order_estimated_delivery_date_dt DATE NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@orders_date_is_text > 0,
    'UPDATE olist_orders_dataset SET
        order_purchase_timestamp_dt = STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''''), ''%e/%c/%Y %k:%i''),
        order_approved_at_dt          = STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''''), ''%e/%c/%Y %k:%i''),
        order_delivered_carrier_date_dt  = STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''''), ''%e/%c/%Y %k:%i''),
        order_delivered_customer_date_dt = STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''''), ''%e/%c/%Y %k:%i''),
        order_estimated_delivery_date_dt = DATE(STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''''), ''%e/%c/%Y %k:%i''))',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@orders_date_is_text > 0,
    'UPDATE olist_orders_dataset SET order_purchase_timestamp_dt = ''2017-01-01 00:00:00'' WHERE order_purchase_timestamp_dt IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(@orders_date_is_text > 0,
    'ALTER TABLE olist_orders_dataset
        DROP COLUMN order_purchase_timestamp,
        CHANGE COLUMN order_purchase_timestamp_dt order_purchase_timestamp DATETIME NOT NULL,
        DROP COLUMN order_approved_at,
        CHANGE COLUMN order_approved_at_dt order_approved_at DATETIME NULL,
        DROP COLUMN order_delivered_carrier_date,
        CHANGE COLUMN order_delivered_carrier_date_dt order_delivered_carrier_date DATETIME NULL,
        DROP COLUMN order_delivered_customer_date,
        CHANGE COLUMN order_delivered_customer_date_dt order_delivered_customer_date DATETIME NULL,
        DROP COLUMN order_estimated_delivery_date,
        CHANGE COLUMN order_estimated_delivery_date_dt order_estimated_delivery_date DATE NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 主键
SET @pk = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = 'ecommerce' AND TABLE_NAME = 'olist_orders_dataset' AND CONSTRAINT_TYPE = 'PRIMARY KEY');
SET @sql = IF(@pk > 0, 'ALTER TABLE olist_orders_dataset DROP PRIMARY KEY', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
ALTER TABLE olist_orders_dataset ADD PRIMARY KEY (order_id);

-- 外键
SET @fk = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = 'ecommerce' AND TABLE_NAME = 'olist_orders_dataset' AND CONSTRAINT_NAME = 'FK_orders_customer' LIMIT 1);
SET @sql = IF(@fk IS NOT NULL, CONCAT('ALTER TABLE olist_orders_dataset DROP FOREIGN KEY ', @fk), 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
ALTER TABLE olist_orders_dataset ADD CONSTRAINT FK_orders_customer FOREIGN KEY (customer_id) REFERENCES olist_customers_dataset (customer_id);

SET @idx = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = 'ecommerce' AND TABLE_NAME = 'olist_orders_dataset' AND INDEX_NAME = 'IX_orders_status');
SET @sql = IF(@idx = 0, 'CREATE INDEX IX_orders_status ON olist_orders_dataset (order_status)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @idx = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = 'ecommerce' AND TABLE_NAME = 'olist_orders_dataset' AND INDEX_NAME = 'IX_orders_purchase_date');
SET @sql = IF(@idx = 0, 'CREATE INDEX IX_orders_purchase_date ON olist_orders_dataset (order_purchase_timestamp)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- =============================================
-- 7. 订单明细表
-- =============================================
-- 步骤 1：清理无效的日期时间值
UPDATE olist_order_items_dataset
SET shipping_limit_date = '2017-01-01 00:00:00'
WHERE shipping_limit_date = '' 
   OR shipping_limit_date = '0000-00-00 00:00:00'
   OR shipping_limit_date IS NULL
   OR (shipping_limit_date IS NOT NULL AND STR_TO_DATE(shipping_limit_date, '%Y-%m-%d %H:%i:%s') IS NULL);

-- 步骤 2：修改列类型
ALTER TABLE olist_order_items_dataset
    MODIFY COLUMN order_id           VARCHAR(32)    NOT NULL,
    MODIFY COLUMN order_item_id      INT            NOT NULL,
    MODIFY COLUMN product_id         VARCHAR(32)    NOT NULL,
    MODIFY COLUMN seller_id          VARCHAR(32)    NOT NULL,
    MODIFY COLUMN shipping_limit_date DATETIME      NOT NULL,
    MODIFY COLUMN price              DECIMAL(10,2)  NOT NULL,
    MODIFY COLUMN freight_value      DECIMAL(10,2)  NOT NULL;

ALTER TABLE olist_order_items_dataset
    ADD PRIMARY KEY (order_id, order_item_id);

ALTER TABLE olist_order_items_dataset
    ADD CONSTRAINT FK_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders_dataset (order_id),
    ADD CONSTRAINT FK_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES olist_products_dataset (product_id),
    ADD CONSTRAINT FK_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES olist_sellers_dataset (seller_id);

-- =============================================
-- 8. OLIST ORDER PAYMENTS DATASET
-- =============================================
ALTER TABLE olist_order_payments_dataset
    MODIFY COLUMN order_id           VARCHAR(32)   NOT NULL,
    MODIFY COLUMN payment_sequential INT           NOT NULL,
    MODIFY COLUMN payment_type       VARCHAR(20)   NOT NULL,
    MODIFY COLUMN payment_installments INT         NOT NULL,
    MODIFY COLUMN payment_value      DECIMAL(10,2) NOT NULL;

ALTER TABLE olist_order_payments_dataset
    ADD PRIMARY KEY (order_id, payment_sequential);

ALTER TABLE olist_order_payments_dataset
    ADD CONSTRAINT FK_order_payments_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders_dataset (order_id);

CREATE INDEX IX_payments_type
    ON olist_order_payments_dataset (payment_type);

-- =============================================
-- 9. OLIST ORDER REVIEWS DATASET
-- =============================================
ALTER TABLE olist_order_reviews_dataset
    MODIFY COLUMN review_id              VARCHAR(32)  NOT NULL,
    MODIFY COLUMN order_id               VARCHAR(32)  NOT NULL,
    MODIFY COLUMN review_score           INT          NULL,
    MODIFY COLUMN review_comment_title   VARCHAR(255) NULL,
    MODIFY COLUMN review_comment_message TEXT         NULL;

SET @date_col_type = (
    SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'ecommerce' 
    AND TABLE_NAME = 'olist_order_reviews_dataset' 
    AND COLUMN_NAME = 'review_creation_date'
);

SET @sql = IF(@date_col_type IN ('varchar', 'text', 'char'),
    'ALTER TABLE olist_order_reviews_dataset
        ADD COLUMN review_creation_date_new DATETIME NULL,
        ADD COLUMN review_answer_timestamp_new DATETIME NULL',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@date_col_type IN ('varchar', 'text', 'char'),
    'UPDATE olist_order_reviews_dataset
        SET review_creation_date_new = 
            CASE 
                WHEN TRIM(review_creation_date) REGEXP ''^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}$''
                THEN STR_TO_DATE(TRIM(review_creation_date), ''%e/%c/%Y %k:%i'')
                ELSE NULL
            END,
            review_answer_timestamp_new = 
            CASE 
                WHEN TRIM(review_answer_timestamp) REGEXP ''^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}$''
                THEN STR_TO_DATE(TRIM(review_answer_timestamp), ''%e/%c/%Y %k:%i'')
                ELSE NULL
            END',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@date_col_type IN ('varchar', 'text', 'char'),
    'ALTER TABLE olist_order_reviews_dataset
        DROP COLUMN review_creation_date,
        DROP COLUMN review_answer_timestamp,
        CHANGE COLUMN review_creation_date_new review_creation_date DATETIME NULL,
        CHANGE COLUMN review_answer_timestamp_new review_answer_timestamp DATETIME NULL',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_duplicates = (
    SELECT COUNT(*) FROM (
        SELECT review_id FROM olist_order_reviews_dataset
        GROUP BY review_id HAVING COUNT(*) > 1
        LIMIT 1
    ) AS dups
);

SET @sql = IF(@has_duplicates > 0,
    'DELETE t1 FROM olist_order_reviews_dataset t1
     LEFT JOIN (
         SELECT review_id, MIN(order_id) as min_order_id
         FROM olist_order_reviews_dataset
         GROUP BY review_id
     ) t2 ON t1.review_id = t2.review_id AND t1.order_id = t2.min_order_id
     WHERE t2.review_id IS NULL',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @pk_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'ecommerce' 
    AND TABLE_NAME = 'olist_order_reviews_dataset' 
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@pk_exists = 0,
    'ALTER TABLE olist_order_reviews_dataset ADD PRIMARY KEY (review_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'ecommerce' 
    AND TABLE_NAME = 'olist_order_reviews_dataset' 
    AND CONSTRAINT_NAME = 'FK_order_reviews_order'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE olist_order_reviews_dataset 
        ADD CONSTRAINT FK_order_reviews_order 
        FOREIGN KEY (order_id) REFERENCES olist_orders_dataset (order_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'ecommerce' 
    AND TABLE_NAME = 'olist_order_reviews_dataset' 
    AND INDEX_NAME = 'IX_reviews_order'
);

SET @sql = IF(@idx_exists = 0,
    'CREATE INDEX IX_reviews_order ON olist_order_reviews_dataset (order_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'ecommerce' 
    AND TABLE_NAME = 'olist_order_reviews_dataset' 
    AND INDEX_NAME = 'IX_reviews_score'
);

SET @sql = IF(@idx_exists = 0,
    'CREATE INDEX IX_reviews_score ON olist_order_reviews_dataset (review_score)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;




