-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 07: Production Analytical Views & Semantic KPI Layer
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- PURPOSE:
-- Provides optimized, pre-joined, reusable relational views for Power BI Desktop
-- and reporting applications. Eliminates snowflake joins in frontend models
-- while preserving strict dimensional star-schema semantics.
--
-- VIEWS CREATED & THEIR GRAIN:
-- 1. vw_sales_fact           -> Grain: 1 row per Sales Order Line (121,253 rows)
-- 2. vw_dim_product          -> Grain: 1 row per Product Version (606 rows)
-- 3. vw_dim_customer         -> Grain: 1 row per Retail Customer (18,484 rows)
-- 4. vw_dim_reseller         -> Grain: 1 row per Commercial Reseller (701 rows)
-- 5. vw_dim_territory        -> Grain: 1 row per Sales Territory (11 rows)
-- 6. vw_dim_date             -> Grain: 1 row per Calendar Day (3,652 rows)
-- 7. vw_inventory_latest     -> Grain: 1 row per Finished Good Product (Latest Snapshot)
-- 8. vw_monthly_channel_kpis -> Grain: 1 row per Channel per Calendar Month
-- ==============================================================================

USE motopulse360;

-- ==============================================================================
-- 1. UNIFIED SALES FACT VIEW: vw_sales_fact
-- ==============================================================================
-- Grain: One row per sales order line (channel, SalesOrderNumber, LineNumber).
-- Consolidated retail (Internet) and wholesale (Reseller) transactions.
-- ==============================================================================

DROP VIEW IF EXISTS vw_sales_fact;
CREATE VIEW vw_sales_fact AS
SELECT 
    fsl.channel,
    fsl.SalesOrderNumber,
    fsl.SalesOrderLineNumber,
    CONCAT(fsl.channel, '-', fsl.SalesOrderNumber, '-', fsl.SalesOrderLineNumber) AS sales_line_composite_id,
    fsl.OrderDateKey,
    fsl.DueDateKey,
    fsl.ShipDateKey,
    fsl.ProductKey,
    fsl.CustomerKey,
    fsl.ResellerKey,
    fsl.EmployeeKey,
    fsl.PromotionKey,
    fsl.CurrencyKey,
    fsl.SalesTerritoryKey,
    fsl.OrderQuantity,
    fsl.UnitPrice,
    fsl.ExtendedAmount AS gross_sales_amount,
    fsl.UnitPriceDiscountPct AS discount_pct,
    fsl.DiscountAmount AS discount_amount,
    fsl.SalesAmount AS net_sales_revenue,
    fsl.ProductStandardCost AS standard_unit_cost,
    fsl.TotalProductCost AS total_standard_cost,
    (fsl.SalesAmount - fsl.TotalProductCost) AS gross_profit,
    ROUND((fsl.SalesAmount - fsl.TotalProductCost) / fsl.SalesAmount * 100, 2) AS gross_margin_pct,
    fsl.TaxAmt AS line_allocated_tax,
    fsl.Freight AS line_allocated_freight,
    fsl.CarrierTrackingNumber,
    fsl.CustomerPONumber,
    fsl.OrderDate,
    fsl.DueDate,
    fsl.ShipDate
FROM fact_sales_line fsl;


-- ==============================================================================
-- 2. FLATTENED PRODUCT DIMENSION VIEW: vw_dim_product
-- ==============================================================================
-- Grain: One row per product version (SCD Type 2).
-- Denormalizes subcategory and category into single star-dimension for Power BI.
-- ==============================================================================

DROP VIEW IF EXISTS vw_dim_product;
CREATE VIEW vw_dim_product AS
SELECT 
    dp.ProductKey,
    dp.ProductAlternateKey AS product_sku,
    dp.EnglishProductName AS product_name,
    COALESCE(psc.EnglishProductSubcategoryName, 'Unassigned Subcategory') AS subcategory_name,
    COALESCE(pc.EnglishProductCategoryName, 'Unassigned Category') AS category_name,
    dp.ModelName AS model_name,
    dp.Color AS product_color,
    dp.Size AS product_size,
    dp.ProductLine AS product_line_code,
    CASE 
        WHEN dp.ProductLine = 'M' THEN 'Mountain'
        WHEN dp.ProductLine = 'R' THEN 'Road'
        WHEN dp.ProductLine = 'T' THEN 'Touring'
        WHEN dp.ProductLine = 'S' THEN 'Standard'
        ELSE 'Accessories/Other'
    END AS product_line_name,
    dp.Class AS product_class,
    dp.StandardCost AS standard_cost,
    dp.ListPrice AS list_price,
    dp.DealerPrice AS dealer_price,
    dp.SafetyStockLevel AS safety_stock_level,
    dp.ReorderPoint AS reorder_point,
    dp.DaysToManufacture AS days_to_manufacture,
    dp.FinishedGoodsFlag AS is_finished_good,
    dp.StartDate AS version_start_date,
    dp.EndDate AS version_end_date,
    COALESCE(dp.Status, 'Historical') AS scd_version_status,
    CASE WHEN dp.EndDate IS NULL THEN 1 ELSE 0 END AS is_current_version
FROM dim_product dp
LEFT JOIN dim_product_subcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
LEFT JOIN dim_product_category pc ON psc.ProductCategoryKey = pc.ProductCategoryKey;


-- ==============================================================================
-- 3. FLATTENED RETAIL CUSTOMER VIEW: vw_dim_customer
-- ==============================================================================
-- Grain: One row per retail consumer.
-- Denormalizes geography and sales territory into single customer dimension.
-- ==============================================================================

DROP VIEW IF EXISTS vw_dim_customer;
CREATE VIEW vw_dim_customer AS
SELECT 
    dc.CustomerKey,
    dc.CustomerAlternateKey AS customer_id,
    CONCAT(dc.FirstName, ' ', COALESCE(CONCAT(dc.MiddleName, ' '), ''), dc.LastName) AS customer_full_name,
    dc.EmailAddress AS email_address,
    dc.Phone AS phone_number,
    dc.Gender AS gender,
    CASE WHEN dc.Gender = 'M' THEN 'Male' WHEN dc.Gender = 'F' THEN 'Female' ELSE 'Unknown' END AS gender_label,
    dc.MaritalStatus AS marital_status,
    CASE WHEN dc.MaritalStatus = 'M' THEN 'Married' ELSE 'Single' END AS marital_status_label,
    dc.YearlyIncome AS yearly_income,
    CASE 
        WHEN dc.YearlyIncome < 40000 THEN 'Under $40k'
        WHEN dc.YearlyIncome BETWEEN 40000 AND 75000 THEN '$40k - $75k'
        WHEN dc.YearlyIncome BETWEEN 75001 AND 110000 THEN '$75k - $110k'
        ELSE '$110k+'
    END AS income_bracket,
    dc.EnglishEducation AS education_level,
    dc.EnglishOccupation AS occupation_group,
    dc.HouseOwnerFlag AS homeowner_flag,
    dc.NumberCarsOwned AS cars_owned,
    dc.TotalChildren AS total_children,
    dc.DateFirstPurchase AS first_purchase_date,
    dg.City AS customer_city,
    dg.StateProvinceName AS customer_state_province,
    dg.PostalCode AS customer_postal_code,
    dg.EnglishCountryRegionName AS customer_country,
    dst.SalesTerritoryRegion AS territory_region,
    dst.SalesTerritoryGroup AS territory_group
FROM dim_customer dc
INNER JOIN dim_geography dg ON dc.GeographyKey = dg.GeographyKey
INNER JOIN dim_sales_territory dst ON dg.SalesTerritoryKey = dst.SalesTerritoryKey;


-- ==============================================================================
-- 4. FLATTENED COMMERCIAL RESELLER VIEW: vw_dim_reseller
-- ==============================================================================
-- Grain: One row per commercial reseller B2B account.
-- Denormalizes geography and territory into single reseller dimension.
-- ==============================================================================

DROP VIEW IF EXISTS vw_dim_reseller;
CREATE VIEW vw_dim_reseller AS
SELECT 
    dr.ResellerKey,
    dr.ResellerAlternateKey AS reseller_id,
    dr.ResellerName AS reseller_name,
    dr.BusinessType AS business_type,
    dr.Phone AS phone_number,
    dr.NumberEmployees AS employee_count,
    dr.OrderFrequency AS order_frequency_code,
    dr.AnnualSales AS reported_annual_sales,
    dr.AnnualRevenue AS annual_revenue_estimate,
    dr.YearOpened AS year_founded,
    dg.City AS reseller_city,
    dg.StateProvinceName AS reseller_state_province,
    dg.PostalCode AS reseller_postal_code,
    dg.EnglishCountryRegionName AS reseller_country,
    dst.SalesTerritoryRegion AS territory_region,
    dst.SalesTerritoryGroup AS territory_group
FROM dim_reseller dr
INNER JOIN dim_geography dg ON dr.GeographyKey = dg.GeographyKey
INNER JOIN dim_sales_territory dst ON dg.SalesTerritoryKey = dst.SalesTerritoryKey;


-- ==============================================================================
-- 5. SALES TERRITORY VIEW: vw_dim_territory
-- ==============================================================================
-- Grain: One row per operational sales territory.
-- ==============================================================================

DROP VIEW IF EXISTS vw_dim_territory;
CREATE VIEW vw_dim_territory AS
SELECT 
    SalesTerritoryKey,
    SalesTerritoryRegion AS territory_region,
    SalesTerritoryCountry AS territory_country,
    SalesTerritoryGroup AS territory_theater
FROM dim_sales_territory;


-- ==============================================================================
-- 6. TIME INTELLIGENCE DATE VIEW: vw_dim_date
-- ==============================================================================
-- Grain: One row per calendar day.
-- Prepares sort keys and labels for Power BI Date hierarchy.
-- ==============================================================================

DROP VIEW IF EXISTS vw_dim_date;
CREATE VIEW vw_dim_date AS
SELECT 
    DateKey,
    FullDateAlternateKey AS calendar_date,
    CalendarYear AS calendar_year,
    CalendarQuarter AS calendar_quarter,
    CONCAT('Q', CalendarQuarter, ' ', CalendarYear) AS quarter_year_label,
    MonthNumberOfYear AS month_number,
    EnglishMonthName AS month_name,
    CONCAT(SUBSTRING(EnglishMonthName, 1, 3), ' ', CalendarYear) AS month_year_label,
    CONCAT(CalendarYear, LPAD(MonthNumberOfYear, 2, '0')) AS year_month_sort_key,
    DayNumberOfMonth AS day_of_month,
    DayNumberOfWeek AS day_of_week,
    EnglishDayNameOfWeek AS day_name,
    WeekNumberOfYear AS week_of_year,
    FiscalYear AS fiscal_year,
    FiscalQuarter AS fiscal_quarter
FROM dim_date;


-- ==============================================================================
-- 7. LATEST INVENTORY OPERATIONAL STATUS VIEW: vw_inventory_latest
-- ==============================================================================
-- Grain: One row per finished good product on the latest recorded snapshot date.
-- Computes stock-to-reorder ratio and operational replenishment flags.
-- ==============================================================================

DROP VIEW IF EXISTS vw_inventory_latest;
CREATE VIEW vw_inventory_latest AS
WITH latest_snapshot_date AS (
    SELECT MAX(MovementDate) AS max_date FROM fact_product_inventory
)
SELECT 
    fpi.ProductKey,
    dp.ProductAlternateKey AS product_sku,
    dp.EnglishProductName AS product_name,
    psc.EnglishProductSubcategoryName AS subcategory_name,
    pc.EnglishProductCategoryName AS category_name,
    fpi.MovementDate AS latest_snapshot_date,
    fpi.UnitsBalance AS current_units_balance,
    dp.SafetyStockLevel AS safety_stock_threshold,
    dp.ReorderPoint AS reorder_trigger_point,
    (fpi.UnitsBalance - dp.ReorderPoint) AS reorder_cushion_units,
    ROUND(fpi.UnitsBalance / dp.ReorderPoint, 2) AS stock_to_reorder_ratio,
    CASE 
        WHEN fpi.UnitsBalance <= dp.SafetyStockLevel THEN 'CRITICAL_SHORTAGE'
        WHEN fpi.UnitsBalance <= dp.ReorderPoint THEN 'REORDER_RECOMMENDED'
        ELSE 'SUFFICIENT_STOCK'
    END AS replenishment_priority_status,
    fpi.UnitCost AS unit_carrying_cost,
    ROUND(fpi.UnitsBalance * fpi.UnitCost, 2) AS total_inventory_valuation
FROM fact_product_inventory fpi
INNER JOIN latest_snapshot_date lsd ON fpi.MovementDate = lsd.max_date
INNER JOIN dim_product dp ON fpi.ProductKey = dp.ProductKey
LEFT JOIN dim_product_subcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
LEFT JOIN dim_product_category pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
WHERE dp.FinishedGoodsFlag = 1;


-- ==============================================================================
-- 8. MONTHLY CHANNEL PERFORMANCE SUMMARY VIEW: vw_monthly_channel_kpis
-- ==============================================================================
-- Grain: One row per channel per calendar month.
-- Pre-aggregated KPI summary optimized for high-speed executive dashboards.
-- ==============================================================================

DROP VIEW IF EXISTS vw_monthly_channel_kpis;
CREATE VIEW vw_monthly_channel_kpis AS
SELECT 
    fsl.channel,
    dd.CalendarYear AS cal_year,
    dd.MonthNumberOfYear AS cal_month,
    CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0')) AS year_month,
    CONCAT(SUBSTRING(dd.EnglishMonthName, 1, 3), ' ', dd.CalendarYear) AS month_year_label,
    COUNT(DISTINCT fsl.SalesOrderNumber) AS total_orders,
    COUNT(*) AS total_order_lines,
    SUM(fsl.OrderQuantity) AS units_sold,
    ROUND(SUM(fsl.ExtendedAmount), 2) AS gross_sales_amount,
    ROUND(SUM(fsl.DiscountAmount), 2) AS discount_amount,
    ROUND(SUM(fsl.SalesAmount), 2) AS net_sales_revenue,
    ROUND(SUM(fsl.TotalProductCost), 2) AS total_standard_cost,
    ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost), 2) AS gross_profit,
    ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(fsl.SalesAmount) / COUNT(DISTINCT fsl.SalesOrderNumber), 2) AS average_order_value
FROM fact_sales_line fsl
INNER JOIN dim_date dd ON fsl.OrderDateKey = dd.DateKey
GROUP BY 
    fsl.channel, 
    dd.CalendarYear, 
    dd.MonthNumberOfYear, 
    CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0')),
    CONCAT(SUBSTRING(dd.EnglishMonthName, 1, 3), ' ', dd.CalendarYear);
