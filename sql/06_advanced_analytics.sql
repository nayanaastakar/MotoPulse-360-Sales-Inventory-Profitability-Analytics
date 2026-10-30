-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 06: Advanced SQL Analytics & Window Functions
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- PURPOSE:
-- Implements advanced analytical patterns for executive decision support:
-- window ranking, time-series lag/lead growth, cumulative running totals,
-- rolling moving averages, Pareto 80/20 distribution, and quota attainment.
--
-- PORTFOLIO & INTERVIEW VALUE:
-- Demonstrates mastery of:
-- 1. Window Functions: ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE(), LAG(), LEAD().
-- 2. Window Framing: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW, UNBOUNDED PRECEDING.
-- 3. Complex Common Table Expressions (CTEs) and multi-level analytical rollups.
-- ==============================================================================

USE motopulse360;

-- ==============================================================================
-- QUERY 1: MONTH-OVER-MONTH (MoM) REVENUE GROWTH BY SALES CHANNEL
-- ==============================================================================
-- Analytical Goal:
-- Track month-over-month percentage growth in net revenue for each sales channel
-- using the LAG() window function.
--
-- SQL Concept:
-- - LAG(value, 1) OVER (PARTITION BY channel ORDER BY year_month)
-- ==============================================================================

WITH monthly_channel_revenue AS (
    SELECT 
        fsl.channel,
        dd.CalendarYear AS cal_year,
        dd.MonthNumberOfYear AS cal_month,
        CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0')) AS year_month,
        ROUND(SUM(fsl.SalesAmount), 2) AS monthly_net_revenue
    FROM fact_sales_line fsl
    INNER JOIN dim_date dd ON fsl.OrderDateKey = dd.DateKey
    GROUP BY fsl.channel, dd.CalendarYear, dd.MonthNumberOfYear, CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0'))
),
growth_calc AS (
    SELECT 
        channel,
        year_month,
        monthly_net_revenue,
        LAG(monthly_net_revenue, 1) OVER (
            PARTITION BY channel 
            ORDER BY year_month
        ) AS prior_month_revenue
    FROM monthly_channel_revenue
)
SELECT 
    channel,
    year_month,
    monthly_net_revenue,
    prior_month_revenue,
    ROUND(monthly_net_revenue - prior_month_revenue, 2) AS absolute_mom_change,
    ROUND((monthly_net_revenue - prior_month_revenue) / prior_month_revenue * 100, 2) AS mom_growth_pct
FROM growth_calc
ORDER BY channel, year_month;


-- ==============================================================================
-- QUERY 2: CUMULATIVE RUNNING TOTAL REVENUE OVER TIME
-- ==============================================================================
-- Analytical Goal:
-- Calculate the continuous cumulative net sales trajectory by channel across time
-- to evaluate portfolio revenue milestones.
--
-- SQL Concept:
-- - SUM() OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
-- ==============================================================================

WITH monthly_sales AS (
    SELECT 
        fsl.channel,
        dd.CalendarYear AS cal_year,
        dd.MonthNumberOfYear AS cal_month,
        CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0')) AS year_month,
        SUM(fsl.SalesAmount) AS monthly_revenue
    FROM fact_sales_line fsl
    INNER JOIN dim_date dd ON fsl.OrderDateKey = dd.DateKey
    GROUP BY fsl.channel, dd.CalendarYear, dd.MonthNumberOfYear, CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0'))
)
SELECT 
    channel,
    year_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        PARTITION BY channel 
        ORDER BY year_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_running_total_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        ORDER BY year_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS global_portfolio_running_total
FROM monthly_sales
ORDER BY year_month, channel;


-- ==============================================================================
-- QUERY 3: 3-MONTH MOVING AVERAGE REVENUE (TREND SMOOTHING)
-- ==============================================================================
-- Analytical Goal:
-- Filter out high-frequency monthly fluctuations using a 3-month rolling moving
-- average to identify underlying macro secular trends.
--
-- SQL Concept:
-- - AVG() OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
-- ==============================================================================

WITH monthly_stream AS (
    SELECT 
        fsl.channel,
        CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0')) AS year_month,
        SUM(fsl.SalesAmount) AS monthly_revenue
    FROM fact_sales_line fsl
    INNER JOIN dim_date dd ON fsl.OrderDateKey = dd.DateKey
    GROUP BY fsl.channel, CONCAT(dd.CalendarYear, '-', LPAD(dd.MonthNumberOfYear, 2, '0'))
)
SELECT 
    channel,
    year_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (
        PARTITION BY channel 
        ORDER BY year_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3_month_revenue
FROM monthly_stream
ORDER BY channel, year_month;


-- ==============================================================================
-- QUERY 4: TOP 3 PRODUCTS WITHIN EACH SUBCATEGORY (DENSE_RANK)
-- ==============================================================================
-- Analytical Goal:
-- Identify the top 3 highest-revenue products inside each product subcategory.
--
-- SQL Concept:
-- - DENSE_RANK() OVER (PARTITION BY subcategory ORDER BY revenue DESC)
-- ==============================================================================

WITH product_sales AS (
    SELECT 
        pc.EnglishProductCategoryName AS category_name,
        psc.EnglishProductSubcategoryName AS subcategory_name,
        dp.ProductAlternateKey AS product_sku,
        dp.EnglishProductName AS product_name,
        ROUND(SUM(fsl.SalesAmount), 2) AS net_revenue
    FROM fact_sales_line fsl
    INNER JOIN dim_product dp ON fsl.ProductKey = dp.ProductKey
    INNER JOIN dim_product_subcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
    INNER JOIN dim_product_category pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY pc.EnglishProductCategoryName, psc.EnglishProductSubcategoryName, dp.ProductAlternateKey, dp.EnglishProductName
),
ranked_products AS (
    SELECT 
        category_name,
        subcategory_name,
        product_sku,
        product_name,
        net_revenue,
        DENSE_RANK() OVER (
            PARTITION BY subcategory_name 
            ORDER BY net_revenue DESC
        ) AS subcategory_rank
    FROM product_sales
)
SELECT 
    category_name,
    subcategory_name,
    subcategory_rank,
    product_sku,
    product_name,
    net_revenue
FROM ranked_products
WHERE subcategory_rank <= 3
ORDER BY category_name, subcategory_name, subcategory_rank;


-- ==============================================================================
-- QUERY 5: PARETO ANALYSIS (80/20 RULE) & ABC PRODUCT CLASSIFICATION
-- ==============================================================================
-- Analytical Goal:
-- Categorize products into Class A (top 80% revenue), Class B (next 15%), and
-- Class C (bottom 5%) based on cumulative percentage contribution.
--
-- SQL Concept:
-- - Cumulative sum over ordered products divided by grand total.
-- ==============================================================================

WITH product_revenue AS (
    SELECT 
        dp.ProductAlternateKey AS product_sku,
        dp.EnglishProductName AS product_name,
        SUM(fsl.SalesAmount) AS product_net_revenue
    FROM fact_sales_line fsl
    INNER JOIN dim_product dp ON fsl.ProductKey = dp.ProductKey
    GROUP BY dp.ProductAlternateKey, dp.EnglishProductName
),
cumulative_calc AS (
    SELECT 
        product_sku,
        product_name,
        product_net_revenue,
        SUM(product_net_revenue) OVER (
            ORDER BY product_net_revenue DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_revenue,
        SUM(product_net_revenue) OVER () AS total_portfolio_revenue
    FROM product_revenue
),
pareto_classified AS (
    SELECT 
        product_sku,
        product_name,
        ROUND(product_net_revenue, 2) AS product_net_revenue,
        ROUND(running_revenue / total_portfolio_revenue * 100, 2) AS cumulative_revenue_pct,
        CASE 
            WHEN running_revenue / total_portfolio_revenue <= 0.80 THEN 'Class A (Core 80%)'
            WHEN running_revenue / total_portfolio_revenue <= 0.95 THEN 'Class B (Next 15%)'
            ELSE 'Class C (Tail 5%)'
        END AS abc_classification
    FROM cumulative_calc
)
SELECT 
    abc_classification,
    COUNT(*) AS products_in_class,
    ROUND(SUM(product_net_revenue), 2) AS class_revenue,
    ROUND(SUM(product_net_revenue) / (SELECT SUM(SalesAmount) FROM fact_sales_line) * 100, 2) AS actual_revenue_share_pct
FROM pareto_classified
GROUP BY abc_classification
ORDER BY MIN(cumulative_revenue_pct);


-- ==============================================================================
-- QUERY 6: RETAIL CUSTOMER LIFETIME VALUE (LTV) DECILE SEGMENTATION
-- ==============================================================================
-- Analytical Goal:
-- Segment retail customers into 10 equal deciles using NTILE(10) based on lifetime
-- net spend to evaluate customer revenue concentration.
--
-- SQL Concept:
-- - NTILE(10) OVER (ORDER BY total_spend DESC)
-- ==============================================================================

WITH customer_lifetime_spend AS (
    SELECT 
        dc.CustomerKey,
        CONCAT(dc.FirstName, ' ', dc.LastName) AS customer_name,
        SUM(fis.SalesAmount) AS lifetime_spend
    FROM fact_internet_sales fis
    INNER JOIN dim_customer dc ON fis.CustomerKey = dc.CustomerKey
    GROUP BY dc.CustomerKey, dc.FirstName, dc.LastName
),
deciled_customers AS (
    SELECT 
        CustomerKey,
        customer_name,
        lifetime_spend,
        NTILE(10) OVER (ORDER BY lifetime_spend DESC) AS spend_decile
    FROM customer_lifetime_spend
)
SELECT 
    spend_decile,
    COUNT(*) AS customers_in_decile,
    ROUND(MIN(lifetime_spend), 2) AS min_spend_in_decile,
    ROUND(MAX(lifetime_spend), 2) AS max_spend_in_decile,
    ROUND(SUM(lifetime_spend), 2) AS total_decile_spend,
    ROUND(SUM(lifetime_spend) / (SELECT SUM(SalesAmount) FROM fact_internet_sales) * 100, 2) AS decile_revenue_share_pct
FROM deciled_customers
GROUP BY spend_decile
ORDER BY spend_decile ASC;


-- ==============================================================================
-- QUERY 7: COMMERCIAL RESELLER ACCOUNT CONCENTRATION (TOP 20 ACCOUNTS)
-- ==============================================================================
-- Analytical Goal:
-- What proportion of commercial wholesale revenue is controlled by our top 20
-- reseller accounts? (Key risk analysis for B2B dependency).
--
-- SQL Concept:
-- - ROW_NUMBER() and cumulative percentage contribution.
-- ==============================================================================

WITH reseller_totals AS (
    SELECT 
        dr.ResellerKey,
        dr.ResellerName,
        dr.BusinessType,
        dst.SalesTerritoryRegion,
        SUM(frs.SalesAmount) AS reseller_net_revenue
    FROM fact_reseller_sales frs
    INNER JOIN dim_reseller dr ON frs.ResellerKey = dr.ResellerKey
    INNER JOIN dim_sales_territory dst ON frs.SalesTerritoryKey = dst.SalesTerritoryKey
    GROUP BY dr.ResellerKey, dr.ResellerName, dr.BusinessType, dst.SalesTerritoryRegion
),
ranked_resellers AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY reseller_net_revenue DESC) AS revenue_rank,
        ResellerName,
        BusinessType,
        SalesTerritoryRegion,
        ROUND(reseller_net_revenue, 2) AS reseller_net_revenue,
        ROUND(reseller_net_revenue / (SELECT SUM(SalesAmount) FROM fact_reseller_sales) * 100, 2) AS account_revenue_share_pct,
        ROUND(SUM(reseller_net_revenue) OVER (
            ORDER BY reseller_net_revenue DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / (SELECT SUM(SalesAmount) FROM fact_reseller_sales) * 100, 2) AS cumulative_reseller_revenue_pct
    FROM reseller_totals
)
SELECT 
    revenue_rank,
    ResellerName,
    BusinessType,
    SalesTerritoryRegion,
    reseller_net_revenue,
    account_revenue_share_pct,
    cumulative_reseller_revenue_pct
FROM ranked_resellers
WHERE revenue_rank <= 20;


-- ==============================================================================
-- QUERY 8: INVENTORY DAILY VELOCITY & RUN-RATE DEPLETION
-- ==============================================================================
-- Analytical Goal:
-- Calculate rolling 7-day average daily unit dispatch (UnitsOut) for top finished goods
-- to establish inventory velocity.
--
-- SQL Concept:
-- - AVG(UnitsOut) OVER (PARTITION BY ProductKey ORDER BY MovementDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- ==============================================================================

WITH inventory_movements AS (
    SELECT 
        fpi.ProductKey,
        dp.ProductAlternateKey AS sku,
        dp.EnglishProductName AS product_name,
        fpi.MovementDate,
        fpi.UnitsOut,
        fpi.UnitsBalance,
        AVG(fpi.UnitsOut) OVER (
            PARTITION BY fpi.ProductKey 
            ORDER BY fpi.MovementDate 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_7day_avg_daily_dispatch
    FROM fact_product_inventory fpi
    INNER JOIN dim_product dp ON fpi.ProductKey = dp.ProductKey
    WHERE dp.FinishedGoodsFlag = 1
)
SELECT 
    sku,
    product_name,
    MovementDate,
    UnitsOut,
    UnitsBalance,
    ROUND(rolling_7day_avg_daily_dispatch, 2) AS rolling_7day_avg_dispatch
FROM inventory_movements
WHERE MovementDate >= '2013-12-01'
  AND sku IN ('BK-M68B-42', 'BK-R93R-44', 'BK-T79U-50')
ORDER BY sku, MovementDate DESC
LIMIT 30;


-- ==============================================================================
-- QUERY 9: SALES REPRESENTATIVE QUOTA ATTAINMENT & PERFORMANCE TIERING
-- ==============================================================================
-- Analytical Goal:
-- Evaluate quarterly sales performance of commercial account executives against
-- assigned sales quotas in FactSalesQuota.
--
-- SQL Concept:
-- - Joining FactSalesQuota to aggregated FactResellerSales on EmployeeKey and Quarter.
-- ==============================================================================

WITH rep_quarterly_sales AS (
    SELECT 
        frs.EmployeeKey,
        dd.CalendarYear,
        dd.CalendarQuarter,
        SUM(frs.SalesAmount) AS actual_reseller_sales
    FROM fact_reseller_sales frs
    INNER JOIN dim_date dd ON frs.OrderDateKey = dd.DateKey
    GROUP BY frs.EmployeeKey, dd.CalendarYear, dd.CalendarQuarter
)
SELECT 
    fsq.EmployeeKey AS sales_rep_id,
    fsq.CalendarYear AS quota_year,
    fsq.CalendarQuarter AS quota_quarter,
    ROUND(fsq.SalesAmountQuota, 2) AS quota_target,
    ROUND(COALESCE(rqs.actual_reseller_sales, 0), 2) AS actual_achieved_sales,
    ROUND(COALESCE(rqs.actual_reseller_sales, 0) - fsq.SalesAmountQuota, 2) AS variance_from_quota,
    ROUND(COALESCE(rqs.actual_reseller_sales, 0) / fsq.SalesAmountQuota * 100, 2) AS quota_attainment_pct,
    CASE 
        WHEN COALESCE(rqs.actual_reseller_sales, 0) >= fsq.SalesAmountQuota THEN 'TARGET_ACHIEVED'
        WHEN COALESCE(rqs.actual_reseller_sales, 0) >= fsq.SalesAmountQuota * 0.85 THEN 'NEAR_TARGET'
        ELSE 'BELOW_TARGET'
    END AS performance_status
FROM fact_sales_quota fsq
LEFT JOIN rep_quarterly_sales rqs 
    ON fsq.EmployeeKey = rqs.EmployeeKey 
   AND fsq.CalendarYear = rqs.CalendarYear 
   AND fsq.CalendarQuarter = rqs.CalendarQuarter
ORDER BY fsq.CalendarYear DESC, fsq.CalendarQuarter DESC, quota_attainment_pct DESC;


-- ==============================================================================
-- QUERY 10: ORDER-LEVEL CROSS-CATEGORY BASKET CO-PURCHASE ANALYSIS
-- ==============================================================================
-- Analytical Goal:
-- How often do direct retail consumers buy apparel (Clothing) or Accessories
-- together in the same order as a Bicycle?
--
-- SQL Concept:
-- - Conditional aggregation over order header CTE.
-- ==============================================================================

WITH order_category_flags AS (
    SELECT 
        fis.SalesOrderNumber,
        MAX(CASE WHEN pc.EnglishProductCategoryName = 'Bikes' THEN 1 ELSE 0 END) AS has_bike,
        MAX(CASE WHEN pc.EnglishProductCategoryName = 'Accessories' THEN 1 ELSE 0 END) AS has_accessory,
        MAX(CASE WHEN pc.EnglishProductCategoryName = 'Clothing' THEN 1 ELSE 0 END) AS has_clothing
    FROM fact_internet_sales fis
    INNER JOIN dim_product dp ON fis.ProductKey = dp.ProductKey
    INNER JOIN dim_product_subcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
    INNER JOIN dim_product_category pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY fis.SalesOrderNumber
)
SELECT 
    CASE 
        WHEN has_bike = 1 AND (has_accessory = 1 OR has_clothing = 1) THEN 'Bike + Gear Bundle'
        WHEN has_bike = 1 THEN 'Bike Only'
        WHEN has_accessory = 1 AND has_clothing = 1 THEN 'Accessories + Clothing'
        WHEN has_accessory = 1 THEN 'Accessories Only'
        ELSE 'Clothing Only'
    END AS basket_combination,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM order_category_flags) * 100, 2) AS basket_share_pct
FROM order_category_flags
GROUP BY 
    CASE 
        WHEN has_bike = 1 AND (has_accessory = 1 OR has_clothing = 1) THEN 'Bike + Gear Bundle'
        WHEN has_bike = 1 THEN 'Bike Only'
        WHEN has_accessory = 1 AND has_clothing = 1 THEN 'Accessories + Clothing'
        WHEN has_accessory = 1 THEN 'Accessories Only'
        ELSE 'Clothing Only'
    END
ORDER BY total_orders DESC;
