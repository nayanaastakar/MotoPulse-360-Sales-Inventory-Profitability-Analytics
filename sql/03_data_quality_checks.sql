-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 03: Data Quality & Integrity Validation Engine
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- PURPOSE:
-- Executes read-only validation audits against staging and analytical data.
-- Records results in `dq_summary` with zero destructive modifications.
-- Verifies referential integrity, financial consistency, and fact grains.
-- ==============================================================================

USE motopulse360;

DROP TABLE IF EXISTS dq_summary;
CREATE TABLE dq_summary (
    check_id INT AUTO_INCREMENT PRIMARY KEY,
    check_category VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    check_description VARCHAR(255) NOT NULL,
    failing_records_count INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    notes TEXT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 1. PRIMARY KEY UNIQUENESS CHECKS
-- ------------------------------------------------------------------------------

-- DimDate
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Primary Key Uniqueness', 'stg_dim_date', 'Duplicate DateKey count',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Expected 0 duplicate DateKey values'
FROM (
    SELECT DateKey, COUNT(*) AS cnt FROM stg_dim_date GROUP BY DateKey HAVING cnt > 1
) dupes;

-- DimProduct
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Primary Key Uniqueness', 'stg_dim_product', 'Duplicate ProductKey count',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Expected 0 duplicate surrogate ProductKey values'
FROM (
    SELECT ProductKey, COUNT(*) AS cnt FROM stg_dim_product GROUP BY ProductKey HAVING cnt > 1
) dupes;

-- DimCustomer
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Primary Key Uniqueness', 'stg_dim_customer', 'Duplicate CustomerKey count',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Expected 0 duplicate CustomerKey values'
FROM (
    SELECT CustomerKey, COUNT(*) AS cnt FROM stg_dim_customer GROUP BY CustomerKey HAVING cnt > 1
) dupes;

-- DimReseller
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Primary Key Uniqueness', 'stg_dim_reseller', 'Duplicate ResellerKey count',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Expected 0 duplicate ResellerKey values'
FROM (
    SELECT ResellerKey, COUNT(*) AS cnt FROM stg_dim_reseller GROUP BY ResellerKey HAVING cnt > 1
) dupes;

-- FactInternetSales Line Grain
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Line Grain Uniqueness', 'stg_fact_internet_sales', 'Duplicate (SalesOrderNumber, SalesOrderLineNumber)',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Line grain must be unique per order line'
FROM (
    SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*) AS cnt 
    FROM stg_fact_internet_sales 
    GROUP BY SalesOrderNumber, SalesOrderLineNumber 
    HAVING cnt > 1
) dupes;

-- FactResellerSales Line Grain
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Line Grain Uniqueness', 'stg_fact_reseller_sales', 'Duplicate (SalesOrderNumber, SalesOrderLineNumber)',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Line grain must be unique per order line'
FROM (
    SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*) AS cnt 
    FROM stg_fact_reseller_sales 
    GROUP BY SalesOrderNumber, SalesOrderLineNumber 
    HAVING cnt > 1
) dupes;

-- FactProductInventory Snapshot Grain
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Snapshot Grain Uniqueness', 'stg_fact_product_inventory', 'Duplicate (ProductKey, DateKey)',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Snapshot grain must be unique per product per calendar date'
FROM (
    SELECT ProductKey, DateKey, COUNT(*) AS cnt 
    FROM stg_fact_product_inventory 
    GROUP BY ProductKey, DateKey 
    HAVING cnt > 1
) dupes;

-- ------------------------------------------------------------------------------
-- 2. FOREIGN KEY REFERENTIAL INTEGRITY (ORPHAN CHECKS)
-- ------------------------------------------------------------------------------

-- FactInternetSales -> DimProduct
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Foreign Key Integrity', 'stg_fact_internet_sales', 'Orphan ProductKey references',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'FactInternetSales rows where ProductKey is missing from DimProduct'
FROM stg_fact_internet_sales fis
LEFT JOIN stg_dim_product dp ON fis.ProductKey = dp.ProductKey
WHERE dp.ProductKey IS NULL;

-- FactInternetSales -> DimCustomer
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Foreign Key Integrity', 'stg_fact_internet_sales', 'Orphan CustomerKey references',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'FactInternetSales rows where CustomerKey is missing from DimCustomer'
FROM stg_fact_internet_sales fis
LEFT JOIN stg_dim_customer dc ON fis.CustomerKey = dc.CustomerKey
WHERE dc.CustomerKey IS NULL;

-- FactResellerSales -> DimReseller
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Foreign Key Integrity', 'stg_fact_reseller_sales', 'Orphan ResellerKey references',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'FactResellerSales rows where ResellerKey is missing from DimReseller'
FROM stg_fact_reseller_sales frs
LEFT JOIN stg_dim_reseller dr ON frs.ResellerKey = dr.ResellerKey
WHERE dr.ResellerKey IS NULL;

-- FactResellerSales -> DimProduct
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Foreign Key Integrity', 'stg_fact_reseller_sales', 'Orphan ProductKey references',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'FactResellerSales rows where ProductKey is missing from DimProduct'
FROM stg_fact_reseller_sales frs
LEFT JOIN stg_dim_product dp ON frs.ProductKey = dp.ProductKey
WHERE dp.ProductKey IS NULL;

-- FactProductInventory -> DimProduct
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Foreign Key Integrity', 'stg_fact_product_inventory', 'Orphan ProductKey in inventory',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Inventory records referencing missing ProductKey'
FROM stg_fact_product_inventory fpi
LEFT JOIN stg_dim_product dp ON fpi.ProductKey = dp.ProductKey
WHERE dp.ProductKey IS NULL;

-- ------------------------------------------------------------------------------
-- 3. FINANCIAL CONSISTENCY AUDITS
-- ------------------------------------------------------------------------------

-- FactInternetSales: SalesAmount == ExtendedAmount - DiscountAmount
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Financial Consistency', 'stg_fact_internet_sales', 'SalesAmount != ExtendedAmount - DiscountAmount',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Net sales revenue must exactly equal gross extended amount minus discount amount'
FROM stg_fact_internet_sales
WHERE ABS(CAST(SalesAmount AS DECIMAL(19,4)) - (CAST(ExtendedAmount AS DECIMAL(19,4)) - CAST(DiscountAmount AS DECIMAL(19,4)))) > 0.01;

-- FactResellerSales: SalesAmount == ExtendedAmount - DiscountAmount
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Financial Consistency', 'stg_fact_reseller_sales', 'SalesAmount != ExtendedAmount - DiscountAmount',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Net sales revenue must exactly equal gross extended amount minus discount amount'
FROM stg_fact_reseller_sales
WHERE ABS(CAST(SalesAmount AS DECIMAL(19,4)) - (CAST(ExtendedAmount AS DECIMAL(19,4)) - CAST(DiscountAmount AS DECIMAL(19,4)))) > 0.01;

-- FactResellerSales: ExtendedAmount == OrderQuantity * UnitPrice
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Financial Consistency', 'stg_fact_reseller_sales', 'ExtendedAmount != OrderQuantity * UnitPrice',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Gross extended amount must equal quantity multiplied by unit price'
FROM stg_fact_reseller_sales
WHERE ABS(CAST(ExtendedAmount AS DECIMAL(19,4)) - (CAST(OrderQuantity AS SIGNED) * CAST(UnitPrice AS DECIMAL(19,4)))) > 0.01;

-- FactResellerSales: TotalProductCost == OrderQuantity * ProductStandardCost
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Financial Consistency', 'stg_fact_reseller_sales', 'TotalProductCost != OrderQuantity * ProductStandardCost',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Total standard product cost must equal quantity multiplied by unit standard cost'
FROM stg_fact_reseller_sales
WHERE ABS(CAST(TotalProductCost AS DECIMAL(19,4)) - (CAST(OrderQuantity AS SIGNED) * CAST(ProductStandardCost AS DECIMAL(19,4)))) > 0.01;

-- ------------------------------------------------------------------------------
-- 4. CHANNEL DISJOINTNESS & INTEGRITY AUDITS
-- ------------------------------------------------------------------------------

-- Check order number overlap between Internet and Reseller sales
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Channel Disjointness', 'Sales Order Headers', 'Overlapping SalesOrderNumber between channels',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Internet and Reseller orders must be completely disjoint'
FROM (
    SELECT fis.SalesOrderNumber
    FROM stg_fact_internet_sales fis
    INNER JOIN stg_fact_reseller_sales frs ON fis.SalesOrderNumber = frs.SalesOrderNumber
    GROUP BY fis.SalesOrderNumber
) overlap;

-- ------------------------------------------------------------------------------
-- 5. CHRONOLOGY & DATE LOGIC AUDITS
-- ------------------------------------------------------------------------------

-- OrderDate <= ShipDate check
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Chronological Consistency', 'stg_fact_internet_sales', 'ShipDate earlier than OrderDate',
    COUNT(*),
    IF(COUNT(*) = 0, 'PASSED', 'FAILED'),
    'Fulfillment ship date cannot precede order placement date'
FROM stg_fact_internet_sales
WHERE STR_TO_DATE(SUBSTRING(ShipDate, 1, 10), '%Y-%m-%d') < STR_TO_DATE(SUBSTRING(OrderDate, 1, 10), '%Y-%m-%d');

-- ------------------------------------------------------------------------------
-- 6. INVENTORY ARTEFACT AUDIT (NEGATIVE BALANCES)
-- ------------------------------------------------------------------------------

-- Inventory UnitsBalance < 0
INSERT INTO dq_summary (check_category, table_name, check_description, failing_records_count, status, notes)
SELECT 
    'Operational Boundary', 'stg_fact_product_inventory', 'Negative UnitsBalance records',
    COUNT(*),
    'FLAGGED',
    CONCAT('Found ', COUNT(*), ' records with negative stock. Synthetic AdventureWorksDW deficit artefacts.')
FROM stg_fact_product_inventory
WHERE CAST(UnitsBalance AS SIGNED) < 0;

-- ------------------------------------------------------------------------------
-- FINAL DATA QUALITY SUMMARY REPORT
-- ------------------------------------------------------------------------------
SELECT 
    check_id,
    check_category,
    table_name,
    check_description,
    failing_records_count,
    status,
    notes
FROM dq_summary
ORDER BY check_id;
