-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 05: Core & Intermediate Business Analysis
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- PURPOSE:
-- Executes enterprise analytical queries across sales channels, product hierarchies,
-- regional sales territories, customer demographics, and inventory health.
--
-- PORTFOLIO & INTERVIEW VALUE:
-- Each query block documents:
-- 1. Business Question: Strategic context and managerial relevance.
-- 2. SQL Concepts Demonstrated: Technical patterns (CTEs, conditional aggregation,
--    multi-table inner joins, CASE tiering, subqueries, grain alignment).
-- 3. Execution Query: Clean, optimized, MySQL 8.x compatible SQL.
-- 4. Grain Safety Check: Guarantees no Cartesian multiplication of revenue.
-- ==============================================================================

USE motopulse360;

-- ==============================================================================
-- QUERY 1: TOP-LINE PERFORMANCE BY SALES CHANNEL (RETAIL VS WHOLESALE)
-- ==============================================================================
-- Business Question:
-- How does top-line performance diverge between direct retail consumers (Internet)
-- and commercial wholesale accounts (Reseller) in revenue, volume, AOV, and margin?
--
-- SQL Concepts Demonstrated:
-- - Aggregation with COUNT(DISTINCT) for order-grain calculation.
-- - Conditional formatting and rounding with DECIMAL precision.
-- - Standard-cost gross profit and margin ratio evaluation.
-- ==============================================================================

SELECT 
    channel AS sales_channel,
    COUNT(DISTINCT SalesOrderNumber) AS total_orders,
    COUNT(*) AS total_order_lines,
    ROUND(COUNT(*) / COUNT(DISTINCT SalesOrderNumber), 2) AS avg_lines_per_order,
    SUM(OrderQuantity) AS total_units_sold,
    ROUND(SUM(ExtendedAmount), 2) AS gross_sales_amount,
    ROUND(SUM(DiscountAmount), 2) AS total_discounts_deducted,
    ROUND(SUM(SalesAmount), 2) AS net_sales_revenue,
    ROUND(SUM(SalesAmount) / COUNT(DISTINCT SalesOrderNumber), 2) AS average_order_value,
    ROUND(SUM(TotalProductCost), 2) AS total_standard_cost,
    ROUND(SUM(SalesAmount - TotalProductCost), 2) AS gross_profit_standard_cost,
    ROUND(SUM(SalesAmount - TotalProductCost) / SUM(SalesAmount) * 100, 2) AS gross_margin_pct
FROM fact_sales_line
GROUP BY channel
ORDER BY net_sales_revenue DESC;

-- Validation Cross-Check: Total net sales must exactly equal $109,809,274.20 ($29,358,677.22 Internet + $80,450,596.98 Reseller).


-- ==============================================================================
-- QUERY 2: PRODUCT CATEGORY & SUBCATEGORY PROFITABILITY BREAKDOWN
-- ==============================================================================
-- Business Question:
-- Which product categories and subcategories drive the highest volume, revenue,
-- and gross profit? Are high-revenue categories also the most profitable?
--
-- SQL Concepts Demonstrated:
-- - Multi-table INNER JOIN across 3-tier product dimensional hierarchy.
-- - Profitability margin ranking using standard cost.
-- - Percentage share of revenue using window functions / CTEs.
-- ==============================================================================

WITH category_summary AS (
    SELECT 
        pc.EnglishProductCategoryName AS category_name,
        psc.EnglishProductSubcategoryName AS subcategory_name,
        SUM(fsl.OrderQuantity) AS units_sold,
        ROUND(SUM(fsl.SalesAmount), 2) AS net_sales_revenue,
        ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost), 2) AS gross_profit,
        ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS gross_margin_pct
    FROM fact_sales_line fsl
    INNER JOIN dim_product dp ON fsl.ProductKey = dp.ProductKey
    INNER JOIN dim_product_subcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
    INNER JOIN dim_product_category pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY pc.EnglishProductCategoryName, psc.EnglishProductSubcategoryName
)
SELECT 
    category_name,
    subcategory_name,
    units_sold,
    net_sales_revenue,
    gross_profit,
    gross_margin_pct,
    ROUND(net_sales_revenue / SUM(net_sales_revenue) OVER () * 100, 2) AS revenue_share_pct
FROM category_summary
ORDER BY net_sales_revenue DESC;


-- ==============================================================================
-- QUERY 3: REGIONAL SALES TERRITORY REVENUE & MARKET SHARE
-- ==============================================================================
-- Business Question:
-- How is commercial revenue distributed across global sales territories, and which
-- geographic theaters represent our highest market concentration?
--
-- SQL Concepts Demonstrated:
-- - Relational join to geographic dimension.
-- - Multi-level geographic grouping (Group -> Country -> Region).
-- - Subquery for dynamic market share calculation.
-- ==============================================================================

SELECT 
    dst.SalesTerritoryGroup AS territory_theater,
    dst.SalesTerritoryCountry AS sovereign_country,
    dst.SalesTerritoryRegion AS operational_region,
    COUNT(DISTINCT fsl.SalesOrderNumber) AS distinct_orders,
    SUM(fsl.OrderQuantity) AS units_sold,
    ROUND(SUM(fsl.SalesAmount), 2) AS net_sales_revenue,
    ROUND(SUM(fsl.SalesAmount) / (SELECT SUM(SalesAmount) FROM fact_sales_line) * 100, 2) AS global_revenue_share_pct,
    ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS territory_gross_margin_pct
FROM fact_sales_line fsl
INNER JOIN dim_sales_territory dst ON fsl.SalesTerritoryKey = dst.SalesTerritoryKey
GROUP BY dst.SalesTerritoryGroup, dst.SalesTerritoryCountry, dst.SalesTerritoryRegion
ORDER BY net_sales_revenue DESC;


-- ==============================================================================
-- QUERY 4: MONTHLY REVENUE TRAJECTORY & CHANNEL CONVERGENCE
-- ==============================================================================
-- Business Question:
-- What is the chronological monthly sales trend across channels? Is there a seasonal
-- peak in bicycle sales during spring and summer quarters?
--
-- SQL Concepts Demonstrated:
-- - Chronological time-series grouping via DimDate.
-- - Conditional aggregation (PIVOT simulation in standard MySQL) separating Internet and Reseller.
-- - Temporal sorting by calendar year and month.
-- ==============================================================================

SELECT 
    dd.CalendarYear AS calendar_year,
    dd.MonthNumberOfYear AS month_number,
    dd.EnglishMonthName AS month_name,
    ROUND(SUM(CASE WHEN fsl.channel = 'Internet' THEN fsl.SalesAmount ELSE 0 END), 2) AS internet_revenue,
    ROUND(SUM(CASE WHEN fsl.channel = 'Reseller' THEN fsl.SalesAmount ELSE 0 END), 2) AS reseller_revenue,
    ROUND(SUM(fsl.SalesAmount), 2) AS total_combined_revenue,
    COUNT(DISTINCT fsl.SalesOrderNumber) AS total_orders
FROM fact_sales_line fsl
INNER JOIN dim_date dd ON fsl.OrderDateKey = dd.DateKey
GROUP BY dd.CalendarYear, dd.MonthNumberOfYear, dd.EnglishMonthName
ORDER BY dd.CalendarYear, dd.MonthNumberOfYear;


-- ==============================================================================
-- QUERY 5: AVERAGE ORDER VALUE (AOV) & BASKET SIZE DISTRIBUTION
-- ==============================================================================
-- Business Question:
-- How does basket size (items per order) correlate with total order revenue?
-- What percentage of retail orders consist of a single item versus multi-item bundles?
--
-- SQL Concepts Demonstrated:
-- - Two-stage CTE aggregation: first aggregating to order header, then bucketing orders.
-- - Case-based categorical binning of order size.
-- ==============================================================================

WITH order_header_summary AS (
    SELECT 
        channel,
        SalesOrderNumber,
        COUNT(*) AS line_items_count,
        SUM(OrderQuantity) AS total_units_in_order,
        SUM(SalesAmount) AS total_order_sales_amt
    FROM fact_sales_line
    GROUP BY channel, SalesOrderNumber
),
order_binned AS (
    SELECT 
        channel,
        SalesOrderNumber,
        line_items_count,
        total_units_in_order,
        total_order_sales_amt,
        CASE 
            WHEN total_units_in_order = 1 THEN '1 Unit (Single Item)'
            WHEN total_units_in_order BETWEEN 2 AND 4 THEN '2 - 4 Units (Small Bundle)'
            WHEN total_units_in_order BETWEEN 5 AND 10 THEN '5 - 10 Units (Medium Order)'
            ELSE '11+ Units (Bulk Wholesale)'
        END AS order_size_tier
    FROM order_header_summary
)
SELECT 
    channel,
    order_size_tier,
    COUNT(*) AS total_orders_in_tier,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY channel) * 100, 2) AS order_tier_share_pct,
    ROUND(SUM(total_order_sales_amt), 2) AS total_revenue_in_tier,
    ROUND(AVG(total_order_sales_amt), 2) AS avg_order_value_in_tier
FROM order_binned
GROUP BY channel, order_size_tier
ORDER BY channel, MIN(total_units_in_order);


-- ==============================================================================
-- QUERY 6: COMMERCIAL RESELLER VOLUME DISCOUNT DEPTH & MARGIN IMPACT
-- ==============================================================================
-- Business Question:
-- What is the effective discount depth offered to commercial resellers across order tiers?
-- Does higher volume discounting trigger severe gross margin erosion?
--
-- SQL Concepts Demonstrated:
-- - CASE categorization of discount percentage ranges.
-- - Margin compression calculation.
-- ==============================================================================

SELECT 
    CASE 
        WHEN UnitPriceDiscountPct = 0 THEN '0% (Standard Dealer Price)'
        WHEN UnitPriceDiscountPct <= 0.05 THEN '1% - 5% (Low Volume Discount)'
        WHEN UnitPriceDiscountPct <= 0.10 THEN '6% - 10% (Medium Volume Discount)'
        WHEN UnitPriceDiscountPct <= 0.20 THEN '11% - 20% (High Volume Tier)'
        ELSE '20%+ (Deep Wholesale Clearance)'
    END AS discount_tier,
    COUNT(*) AS order_lines_count,
    SUM(OrderQuantity) AS total_units_sold,
    ROUND(SUM(ExtendedAmount), 2) AS gross_sales_amount,
    ROUND(SUM(DiscountAmount), 2) AS total_discount_deducted,
    ROUND(SUM(SalesAmount), 2) AS net_sales_revenue,
    ROUND(SUM(DiscountAmount) / SUM(ExtendedAmount) * 100, 2) AS effective_discount_rate_pct,
    ROUND(SUM(SalesAmount - TotalProductCost) / SUM(SalesAmount) * 100, 2) AS realized_gross_margin_pct
FROM fact_reseller_sales
GROUP BY 
    CASE 
        WHEN UnitPriceDiscountPct = 0 THEN '0% (Standard Dealer Price)'
        WHEN UnitPriceDiscountPct <= 0.05 THEN '1% - 5% (Low Volume Discount)'
        WHEN UnitPriceDiscountPct <= 0.10 THEN '6% - 10% (Medium Volume Discount)'
        WHEN UnitPriceDiscountPct <= 0.20 THEN '11% - 20% (High Volume Tier)'
        ELSE '20%+ (Deep Wholesale Clearance)'
    END
ORDER BY MIN(UnitPriceDiscountPct);


-- ==============================================================================
-- QUERY 7: TOP 10 REVENUE GENERATING PRODUCTS (SCD TYPE 2 SAFE)
-- ==============================================================================
-- Business Question:
-- What are the top 10 best-selling products across all channels combined?
-- How do we prevent SCD Type 2 product history from fragmenting a single product?
--
-- SQL Concepts Demonstrated:
-- - Safe grouping by ProductAlternateKey and EnglishProductName rather than ProductKey.
-- - Combining distinct historical versions under canonical SKU.
-- ==============================================================================

SELECT 
    dp.ProductAlternateKey AS product_sku,
    dp.EnglishProductName AS canonical_product_name,
    psc.EnglishProductSubcategoryName AS subcategory_name,
    COUNT(DISTINCT dp.ProductKey) AS historical_versions_count,
    SUM(fsl.OrderQuantity) AS total_units_sold,
    ROUND(SUM(fsl.SalesAmount), 2) AS total_net_revenue,
    ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost), 2) AS total_gross_profit,
    ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS gross_margin_pct
FROM fact_sales_line fsl
INNER JOIN dim_product dp ON fsl.ProductKey = dp.ProductKey
INNER JOIN dim_product_subcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
GROUP BY dp.ProductAlternateKey, dp.EnglishProductName, psc.EnglishProductSubcategoryName
ORDER BY total_net_revenue DESC
LIMIT 10;


-- ==============================================================================
-- QUERY 8: RETAIL CONSUMER DEMOGRAPHIC REVENUE CONTRIBUTION
-- ==============================================================================
-- Business Question:
-- How does household income and educational attainment influence purchase behavior
-- among direct-to-consumer Internet buyers?
--
-- SQL Concepts Demonstrated:
-- - Demographic segmentation using CASE income brackets.
-- - Cross-dimensional demographic aggregation.
-- ==============================================================================

WITH customer_spend AS (
    SELECT 
        dc.CustomerKey,
        dc.EnglishEducation AS education_level,
        CASE 
            WHEN dc.YearlyIncome < 40000 THEN 'Under $40k (Budget)'
            WHEN dc.YearlyIncome BETWEEN 40000 AND 75000 THEN '$40k - $75k (Middle Income)'
            WHEN dc.YearlyIncome BETWEEN 75001 AND 110000 THEN '$75k - $110k (Upper Middle)'
            ELSE '$110k+ (High Net Worth)'
        END AS income_bracket,
        SUM(fis.SalesAmount) AS total_customer_spend
    FROM fact_internet_sales fis
    INNER JOIN dim_customer dc ON fis.CustomerKey = dc.CustomerKey
    GROUP BY dc.CustomerKey, dc.EnglishEducation, dc.YearlyIncome
)
SELECT 
    income_bracket,
    education_level,
    COUNT(DISTINCT CustomerKey) AS unique_purchasing_customers,
    ROUND(SUM(total_customer_spend), 2) AS total_net_revenue,
    ROUND(AVG(total_customer_spend), 2) AS avg_revenue_per_customer
FROM customer_spend
GROUP BY income_bracket, education_level
ORDER BY total_net_revenue DESC;


-- ==============================================================================
-- QUERY 9: RESELLER BUSINESS TYPE PERFORMANCE & WHOLESALE DYNAMICS
-- ==============================================================================
-- Business Question:
-- How do sales compare between Value Added Resellers, Specialty Bike Shops, and
-- commercial "Warehouse" customer accounts?
--
-- Technical Note:
-- Demonstrates that "Warehouse" is a customer classification, NOT internal storage.
-- ==============================================================================

SELECT 
    dr.BusinessType AS customer_business_type,
    COUNT(DISTINCT dr.ResellerKey) AS active_reseller_accounts,
    COUNT(DISTINCT frs.SalesOrderNumber) AS wholesale_orders_placed,
    SUM(frs.OrderQuantity) AS wholesale_units_purchased,
    ROUND(SUM(frs.SalesAmount), 2) AS net_wholesale_revenue,
    ROUND(SUM(frs.SalesAmount) / COUNT(DISTINCT frs.SalesOrderNumber), 2) AS average_order_value,
    ROUND(SUM(frs.SalesAmount - frs.TotalProductCost) / SUM(frs.SalesAmount) * 100, 2) AS realized_gross_margin_pct
FROM fact_reseller_sales frs
INNER JOIN dim_reseller dr ON frs.ResellerKey = dr.ResellerKey
GROUP BY dr.BusinessType
ORDER BY net_wholesale_revenue DESC;


-- ==============================================================================
-- QUERY 10: INVENTORY STOCK HEALTH & REPLENISHMENT URGENCY
-- ==============================================================================
-- Business Question:
-- Based on the most recent inventory snapshot date, which products are currently
-- in critical shortage (below safety stock) or breach their reorder point?
--
-- SQL Concepts Demonstrated:
-- - Filtering for latest snapshot date via subquery.
-- - Stock-to-Reorder ratio calculation.
-- - Operational prioritization flag.
-- ==============================================================================

WITH latest_inventory AS (
    SELECT 
        fpi.ProductKey,
        fpi.MovementDate AS snapshot_date,
        fpi.UnitsBalance,
        dp.ProductAlternateKey,
        dp.EnglishProductName,
        dp.SafetyStockLevel,
        dp.ReorderPoint,
        CASE 
            WHEN fpi.UnitsBalance <= dp.SafetyStockLevel THEN 'CRITICAL_SHORTAGE'
            WHEN fpi.UnitsBalance <= dp.ReorderPoint THEN 'REORDER_RECOMMENDED'
            ELSE 'SUFFICIENT_STOCK'
        END AS stock_health_status,
        ROUND(fpi.UnitsBalance / dp.ReorderPoint, 2) AS stock_to_reorder_ratio
    FROM fact_product_inventory fpi
    INNER JOIN dim_product dp ON fpi.ProductKey = dp.ProductKey
    WHERE fpi.MovementDate = (SELECT MAX(MovementDate) FROM fact_product_inventory)
      AND dp.FinishedGoodsFlag = 1
)
SELECT 
    stock_health_status,
    COUNT(*) AS products_count,
    MIN(UnitsBalance) AS min_units_balance,
    MAX(UnitsBalance) AS max_units_balance,
    AVG(stock_to_reorder_ratio) AS avg_stock_ratio
FROM latest_inventory
GROUP BY stock_health_status
ORDER BY MIN(UnitsBalance) ASC;
