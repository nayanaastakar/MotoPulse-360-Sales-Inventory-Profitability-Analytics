-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 02b: Load Staging Layer from Clean CSV Files
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- PREREQUISITES FOR LOAD DATA LOCAL INFILE:
-- 1. MySQL Server must allow local infile:
--      SET GLOBAL local_infile = 1;
-- 2. MySQL Client must be launched with local-infile enabled:
--      mysql --local-infile=1 -u root -p motopulse360
-- 3. Note: On Windows, use forward slashes in file paths (e.g. 'D:/...').
--
-- PYTHON FALLBACK LOADER:
-- If LOAD DATA LOCAL INFILE is disabled by your server hosting policy, execute
-- the automated Python fallback loader instead:
--      py python/02_load_to_mysql.py
-- ==============================================================================

USE motopulse360;

-- 1. DimDate
LOAD DATA LOCAL INFILE 'data/processed/clean/DimDate.csv'
INTO TABLE stg_dim_date
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 2. DimProductCategory
LOAD DATA LOCAL INFILE 'data/processed/clean/DimProductCategory.csv'
INTO TABLE stg_dim_product_category
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 3. DimProductSubcategory
LOAD DATA LOCAL INFILE 'data/processed/clean/DimProductSubcategory.csv'
INTO TABLE stg_dim_product_subcategory
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 4. DimProduct
LOAD DATA LOCAL INFILE 'data/processed/clean/DimProduct.csv'
INTO TABLE stg_dim_product
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 5. DimCustomer
LOAD DATA LOCAL INFILE 'data/processed/clean/DimCustomer.csv'
INTO TABLE stg_dim_customer
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 6. DimReseller
LOAD DATA LOCAL INFILE 'data/processed/clean/DimReseller.csv'
INTO TABLE stg_dim_reseller
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 7. DimSalesTerritory
LOAD DATA LOCAL INFILE 'data/processed/clean/DimSalesTerritory.csv'
INTO TABLE stg_dim_sales_territory
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 8. DimGeography
LOAD DATA LOCAL INFILE 'data/processed/clean/DimGeography.csv'
INTO TABLE stg_dim_geography
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 9. DimPromotion
LOAD DATA LOCAL INFILE 'data/processed/clean/DimPromotion.csv'
INTO TABLE stg_dim_promotion
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 10. DimCurrency
LOAD DATA LOCAL INFILE 'data/processed/clean/DimCurrency.csv'
INTO TABLE stg_dim_currency
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 11. FactInternetSales
LOAD DATA LOCAL INFILE 'data/processed/clean/FactInternetSales.csv'
INTO TABLE stg_fact_internet_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 12. FactResellerSales
LOAD DATA LOCAL INFILE 'data/processed/clean/FactResellerSales.csv'
INTO TABLE stg_fact_reseller_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 13. FactProductInventory
LOAD DATA LOCAL INFILE 'data/processed/clean/FactProductInventory.csv'
INTO TABLE stg_fact_product_inventory
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 14. FactCurrencyRate
LOAD DATA LOCAL INFILE 'data/processed/clean/FactCurrencyRate.csv'
INTO TABLE stg_fact_currency_rate
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 15. FactSalesQuota
LOAD DATA LOCAL INFILE 'data/processed/clean/FactSalesQuota.csv'
INTO TABLE stg_fact_sales_quota
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Staging Load Verification
SELECT 'stg_dim_date' AS tbl, COUNT(*) AS row_cnt FROM stg_dim_date
UNION ALL SELECT 'stg_dim_product_category', COUNT(*) FROM stg_dim_product_category
UNION ALL SELECT 'stg_dim_product_subcategory', COUNT(*) FROM stg_dim_product_subcategory
UNION ALL SELECT 'stg_dim_product', COUNT(*) FROM stg_dim_product
UNION ALL SELECT 'stg_dim_customer', COUNT(*) FROM stg_dim_customer
UNION ALL SELECT 'stg_dim_reseller', COUNT(*) FROM stg_dim_reseller
UNION ALL SELECT 'stg_dim_sales_territory', COUNT(*) FROM stg_dim_sales_territory
UNION ALL SELECT 'stg_dim_geography', COUNT(*) FROM stg_dim_geography
UNION ALL SELECT 'stg_dim_promotion', COUNT(*) FROM stg_dim_promotion
UNION ALL SELECT 'stg_dim_currency', COUNT(*) FROM stg_dim_currency
UNION ALL SELECT 'stg_fact_internet_sales', COUNT(*) FROM stg_fact_internet_sales
UNION ALL SELECT 'stg_fact_reseller_sales', COUNT(*) FROM stg_fact_reseller_sales
UNION ALL SELECT 'stg_fact_product_inventory', COUNT(*) FROM stg_fact_product_inventory
UNION ALL SELECT 'stg_fact_currency_rate', COUNT(*) FROM stg_fact_currency_rate
UNION ALL SELECT 'stg_fact_sales_quota', COUNT(*) FROM stg_fact_sales_quota;
