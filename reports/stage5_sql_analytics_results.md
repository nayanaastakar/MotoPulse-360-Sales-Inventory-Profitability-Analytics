# Stage 5: Empirical SQL Analytics & Business Insights Report

**Project:** MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform  
**Execution Status:** Empirically Executed & Verified via Python SQLite 3.45 in-memory engine populated from `data/processed/clean/` CSV files.  
**MySQL Status:** MySQL 8.x scripts prepared in `sql/05_business_analysis.sql`, `sql/06_advanced_analytics.sql`, and `sql/07_views_and_kpis.sql`. (Pending live MySQL server availability).  
**Dataset Disclosure:** Fictional synthetic Microsoft AdventureWorksDW bicycle retail and wholesale data. Not real motorcycle industry data.  
**Date:** 2026-10-20  

---

## Executive Summary of Results

- **Total Portfolio Net Sales:** **$109,809,274.20** across 31,455 orders (27,659 retail + 3,796 wholesale) and 121,253 sales lines.
- **Channel Split:** Commercial Wholesale accounts for **73.26%** of revenue ($80.45M), while Direct Retail generates **26.74%** ($29.36M).
- **Margin Contrast:** Direct Retail yields a **41.15%** gross margin (zero discounts), whereas Commercial Wholesale yields **0.58%** gross margin ($527.5k volume discounts deducted). Consolidated gross margin: **11.43%**.
- **Product Concentration:** **Class A products (86 SKUs out of 258 active products)** drive **80.0%** of total business revenue, confirming Pareto concentration.
- **Customer Concentration:** The top 10% of retail consumers (Decile 1) generate **32.89%** of direct retail sales ($9.66M).
- **Inventory Status:** On the final snapshot date (2014-06-30), **43 finished goods products** are in **CRITICAL_SHORTAGE** (inventory below safety stock threshold).

---

### Query 1: Top-Line Performance by Sales Channel

```sql
SELECT 
        channel AS sales_channel,
        COUNT(DISTINCT SalesOrderNumber) AS total_orders,
        COUNT(*) AS total_order_lines,
        ROUND(CAST(COUNT(*) AS FLOAT) / COUNT(DISTINCT SalesOrderNumber), 2) AS avg_lines_per_order,
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
    ORDER BY net_sales_revenue DESC
```

**Empirical Query Output Table:**

| sales_channel   |   total_orders |   total_order_lines |   avg_lines_per_order |   total_units_sold |   gross_sales_amount |   total_discounts_deducted |   net_sales_revenue |   average_order_value |   total_standard_cost |   gross_profit_standard_cost |   gross_margin_pct |
|:----------------|---------------:|--------------------:|----------------------:|-------------------:|---------------------:|---------------------------:|--------------------:|----------------------:|----------------------:|-----------------------------:|-------------------:|
| Reseller        |           3796 |               60855 |                 16.03 |             214378 |        80,978,104.87 |                 527,507.93 |       80,450,596.98 |             21,193.52 |         79,980,114.38 |                   470,482.60 |               0.58 |
| Internet        |          27659 |               60398 |                  2.18 |              60398 |        29,358,677.22 |                       0.00 |       29,358,677.22 |              1,061.45 |         17,277,793.58 |                12,080,883.64 |              41.15 |

---

### Query 2: Product Category & Subcategory Profitability Breakdown

```sql
WITH category_summary AS (
        SELECT 
            pc.EnglishProductCategoryName AS category_name,
            psc.EnglishProductSubcategoryName AS subcategory_name,
            SUM(fsl.OrderQuantity) AS units_sold,
            ROUND(SUM(fsl.SalesAmount), 2) AS net_sales_revenue,
            ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost), 2) AS gross_profit,
            ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS gross_margin_pct
        FROM fact_sales_line fsl
        INNER JOIN dimproduct dp ON fsl.ProductKey = dp.ProductKey
        INNER JOIN dimproductsubcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
        INNER JOIN dimproductcategory pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
        GROUP BY pc.EnglishProductCategoryName, psc.EnglishProductSubcategoryName
    )
    SELECT 
        category_name,
        subcategory_name,
        units_sold,
        net_sales_revenue,
        gross_profit,
        gross_margin_pct,
        ROUND(net_sales_revenue / (SELECT SUM(net_sales_revenue) FROM category_summary) * 100, 2) AS revenue_share_pct
    FROM category_summary
    ORDER BY net_sales_revenue DESC
```

**Empirical Query Output Table:**

| category_name   | subcategory_name   |   units_sold |   net_sales_revenue |   gross_profit |   gross_margin_pct |   revenue_share_pct |
|:----------------|:-------------------|-------------:|--------------------:|---------------:|-------------------:|--------------------:|
| Bikes           | Road Bikes         |        47148 |       43,878,791.00 |   4,364,902.75 |               9.95 |               39.96 |
| Bikes           | Mountain Bikes     |        28321 |       36,445,443.94 |   5,932,916.14 |              16.28 |               33.19 |
| Bikes           | Touring Bikes      |        14751 |       14,296,291.27 |     217,277.71 |               1.52 |               13.02 |
| Components      | Mountain Frames    |        11620 |        4,713,672.15 |     487,845.26 |              10.35 |                4.29 |
| Components      | Road Frames        |        11747 |        3,849,853.34 |     138,871.18 |               3.61 |                3.51 |
| Components      | Touring Frames     |         3725 |        1,642,327.69 |      -5,573.41 |              -0.34 |                1.50 |
| Clothing        | Jerseys            |        22711 |          752,259.39 |     -92,921.27 |             -12.35 |                0.69 |
| Components      | Wheels             |         5263 |          679,070.07 |     175,340.35 |              25.82 |                0.62 |
| Accessories     | Helmets            |        19541 |          484,048.53 |     226,406.73 |              46.77 |                0.44 |
| Clothing        | Shorts             |         9965 |          413,522.53 |     155,945.59 |              37.71 |                0.38 |
| Clothing        | Vests              |         6738 |          259,488.37 |      99,467.61 |              38.33 |                0.24 |
| Accessories     | Tires and Tubes    |        18006 |          246,454.53 |     154,048.68 |              62.51 |                0.22 |
| Clothing        | Gloves             |        12983 |          242,795.87 |      83,412.52 |              34.36 |                0.22 |
| Accessories     | Bike Racks         |         3166 |          237,096.16 |      95,006.08 |              40.07 |                0.22 |
| Components      | Cranksets          |         1107 |          203,942.62 |      52,778.81 |              25.88 |                0.19 |
| Clothing        | Tights             |         4562 |          201,833.01 |      60,714.84 |              30.08 |                0.18 |
| Components      | Handlebars         |         3950 |          170,591.32 |      44,219.56 |              25.92 |                0.16 |
| Clothing        | Bib-Shorts         |         3111 |          166,739.71 |      51,256.59 |              30.74 |                0.15 |
| Components      | Pedals             |         3931 |          147,483.91 |      38,250.97 |              25.94 |                0.13 |
| Accessories     | Hydration Packs    |         2761 |          105,826.42 |      49,042.86 |              46.34 |                0.10 |
| Components      | Forks              |          634 |           77,931.69 |      20,187.09 |              25.90 |                0.07 |
| Components      | Derailleurs        |         1166 |           70,209.50 |      18,147.48 |              25.85 |                0.06 |
| Components      | Brakes             |         1035 |           66,018.71 |      17,077.70 |              25.87 |                0.06 |
| Accessories     | Bottles and Cages  |        10552 |           64,274.79 |      38,233.69 |              59.48 |                0.06 |
| Components      | Headsets           |         1009 |           60,942.20 |      15,448.05 |              25.35 |                0.06 |
| Components      | Saddles            |         2145 |           55,829.39 |      14,476.55 |              25.93 |                0.05 |
| Components      | Bottom Brackets    |          921 |           51,826.37 |      13,474.82 |              26.00 |                0.05 |
| Clothing        | Caps               |         8311 |           51,229.45 |      -1,203.20 |              -2.35 |                0.05 |
| Accessories     | Fenders            |         2121 |           46,619.58 |      29,183.90 |              62.60 |                0.04 |
| Accessories     | Bike Stands        |          249 |           39,591.00 |      24,783.97 |              62.60 |                0.04 |
| Clothing        | Socks              |         5217 |           29,745.13 |      12,163.31 |              40.89 |                0.03 |
| Accessories     | Cleaners           |         3319 |           18,406.97 |       8,538.59 |              46.39 |                0.02 |
| Accessories     | Locks              |         1086 |           16,225.22 |       5,025.85 |              30.98 |                0.01 |
| Accessories     | Pumps              |         1130 |           13,514.69 |       4,196.82 |              31.05 |                0.01 |
| Components      | Chains             |          774 |            9,377.71 |       2,422.08 |              25.83 |                0.01 |

---

### Query 3: Regional Sales Territory Revenue & Contribution

```sql
SELECT 
        dst.SalesTerritoryGroup AS territory_theater,
        dst.SalesTerritoryCountry AS country,
        dst.SalesTerritoryRegion AS region,
        COUNT(DISTINCT fsl.SalesOrderNumber) AS distinct_orders,
        SUM(fsl.OrderQuantity) AS units_sold,
        ROUND(SUM(fsl.SalesAmount), 2) AS net_sales_revenue,
        ROUND(SUM(fsl.SalesAmount) / (SELECT SUM(SalesAmount) FROM fact_sales_line) * 100, 2) AS global_revenue_share_pct,
        ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS territory_gross_margin_pct
    FROM fact_sales_line fsl
    INNER JOIN dimsalesterritory dst ON fsl.SalesTerritoryKey = dst.SalesTerritoryKey
    GROUP BY dst.SalesTerritoryGroup, dst.SalesTerritoryCountry, dst.SalesTerritoryRegion
    ORDER BY net_sales_revenue DESC
```

**Empirical Query Output Table:**

| territory_theater   | country        | region         |   distinct_orders |   units_sold |   net_sales_revenue |   global_revenue_share_pct |   territory_gross_margin_pct |
|:--------------------|:---------------|:---------------|------------------:|-------------:|--------------------:|---------------------------:|-----------------------------:|
| North America       | United States  | Southwest      |              6224 |        59105 |       24,184,609.60 |                      22.02 |                         9.74 |
| North America       | Canada         | Canada         |              4067 |        49381 |       16,355,770.46 |                      14.89 |                         6.16 |
| North America       | United States  | Northwest      |              4594 |        36776 |       16,084,942.55 |                      14.65 |                        10.82 |
| Pacific             | Australia      | Australia      |              6843 |        18293 |       10,655,335.96 |                       9.70 |                        33.57 |
| North America       | United States  | Central        |               385 |        19493 |        7,909,009.01 |                       7.20 |                         1.79 |
| North America       | United States  | Southeast      |               486 |        18875 |        7,879,655.07 |                       7.18 |                         1.59 |
| Europe              | United Kingdom | United Kingdom |              3219 |        20099 |        7,670,721.04 |                       6.99 |                        18.21 |
| Europe              | France         | France         |              2672 |        19906 |        7,251,555.65 |                       6.60 |                        14.47 |
| North America       | United States  | Northeast      |               352 |        19843 |        6,939,374.48 |                       6.32 |                         1.16 |
| Europe              | Germany        | Germany        |              2613 |        13005 |        4,878,300.38 |                       4.44 |                        22.06 |

---

### Query 4: Commercial Reseller Volume Discount Depth & Margin Leakage

```sql
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
    FROM factresellersales
    GROUP BY 
        CASE 
            WHEN UnitPriceDiscountPct = 0 THEN '0% (Standard Dealer Price)'
            WHEN UnitPriceDiscountPct <= 0.05 THEN '1% - 5% (Low Volume Discount)'
            WHEN UnitPriceDiscountPct <= 0.10 THEN '6% - 10% (Medium Volume Discount)'
            WHEN UnitPriceDiscountPct <= 0.20 THEN '11% - 20% (High Volume Tier)'
            ELSE '20%+ (Deep Wholesale Clearance)'
        END
    ORDER BY MIN(UnitPriceDiscountPct)
```

**Empirical Query Output Table:**

| discount_tier                     |   order_lines_count |   total_units_sold |   gross_sales_amount |   total_discount_deducted |   net_sales_revenue |   effective_discount_rate_pct |   realized_gross_margin_pct |
|:----------------------------------|--------------------:|-------------------:|---------------------:|--------------------------:|--------------------:|------------------------------:|----------------------------:|
| 0% (Standard Dealer Price)        |               57573 |             180559 |        75,027,907.96 |                      0.00 |       75,027,907.96 |                          0.00 |                        3.06 |
| 1% - 5% (Low Volume Discount)     |                1916 |              26776 |         4,042,482.34 |                113,617.34 |        3,928,865.02 |                          2.81 |                       -4.40 |
| 6% - 10% (Medium Volume Discount) |                 178 |               2813 |           146,219.29 |                 14,621.93 |          131,597.36 |                         10.00 |                      -15.56 |
| 11% - 20% (High Volume Tier)      |                 821 |               3088 |         1,260,878.75 |                225,465.05 |        1,035,413.72 |                         17.88 |                      -79.66 |
| 20%+ (Deep Wholesale Clearance)   |                 367 |               1142 |           500,616.53 |                173,803.62 |          326,812.92 |                         34.72 |                     -247.03 |

---

### Query 5: Top 10 Best-Selling Products Portfolio-Wide (SCD Safe)

```sql
SELECT 
        dp.ProductAlternateKey AS product_sku,
        dp.EnglishProductName AS product_name,
        psc.EnglishProductSubcategoryName AS subcategory_name,
        COUNT(DISTINCT dp.ProductKey) AS historical_versions_count,
        SUM(fsl.OrderQuantity) AS total_units_sold,
        ROUND(SUM(fsl.SalesAmount), 2) AS total_net_revenue,
        ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost), 2) AS total_gross_profit,
        ROUND(SUM(fsl.SalesAmount - fsl.TotalProductCost) / SUM(fsl.SalesAmount) * 100, 2) AS gross_margin_pct
    FROM fact_sales_line fsl
    INNER JOIN dimproduct dp ON fsl.ProductKey = dp.ProductKey
    INNER JOIN dimproductsubcategory psc ON dp.ProductSubcategoryKey = psc.ProductSubcategoryKey
    GROUP BY dp.ProductAlternateKey, dp.EnglishProductName, psc.EnglishProductSubcategoryName
    ORDER BY total_net_revenue DESC
    LIMIT 10
```

**Empirical Query Output Table:**

| product_sku   | product_name            | subcategory_name   |   historical_versions_count |   total_units_sold |   total_net_revenue |   total_gross_profit |   gross_margin_pct |
|:--------------|:------------------------|:-------------------|----------------------------:|-------------------:|--------------------:|---------------------:|-------------------:|
| BK-M68B-38    | Mountain-200 Black, 38  | Mountain Bikes     |                           2 |               2977 |        4,400,592.80 |           872,822.12 |              19.83 |
| BK-M68B-42    | Mountain-200 Black, 42  | Mountain Bikes     |                           2 |               2664 |        4,009,494.76 |           863,800.75 |              21.54 |
| BK-M68S-38    | Mountain-200 Silver, 38 | Mountain Bikes     |                           2 |               2394 |        3,693,678.03 |           829,132.41 |              22.45 |
| BK-M68S-42    | Mountain-200 Silver, 42 | Mountain Bikes     |                           2 |               2234 |        3,438,478.86 |           775,989.08 |              22.57 |
| BK-M68S-46    | Mountain-200 Silver, 46 | Mountain Bikes     |                           2 |               2216 |        3,434,256.94 |           793,957.25 |              23.12 |
| BK-M68B-46    | Mountain-200 Black, 46  | Mountain Bikes     |                           2 |               2111 |        3,309,673.22 |           808,088.34 |              24.42 |
| BK-R89B-44    | Road-250 Black, 44      | Road Bikes         |                           2 |               1642 |        2,516,857.31 |           169,082.48 |               6.72 |
| BK-R89B-48    | Road-250 Black, 48      | Road Bikes         |                           2 |               1498 |        2,347,655.95 |           202,241.32 |               8.61 |
| BK-R89B-52    | Road-250 Black, 52      | Road Bikes         |                           2 |               1245 |        2,012,447.77 |           235,368.70 |              11.70 |
| BK-R93R-56    | Road-150 Red, 56        | Road Bikes         |                           1 |                664 |        1,847,818.63 |           406,079.28 |              21.98 |

---

### Query 6: Pareto 80/20 Analysis & ABC Classification (Window Functions)

```sql
WITH product_revenue AS (
        SELECT 
            dp.ProductAlternateKey AS product_sku,
            dp.EnglishProductName AS product_name,
            SUM(fsl.SalesAmount) AS product_net_revenue
        FROM fact_sales_line fsl
        INNER JOIN dimproduct dp ON fsl.ProductKey = dp.ProductKey
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
    ORDER BY MIN(cumulative_revenue_pct)
```

**Empirical Query Output Table:**

| abc_classification   |   products_in_class |   class_revenue |   actual_revenue_share_pct |
|:---------------------|--------------------:|----------------:|---------------------------:|
| Class A (Core 80%)   |                  63 |   87,711,266.05 |                      79.88 |
| Class B (Next 15%)   |                  66 |   16,526,738.11 |                      15.05 |
| Class C (Tail 5%)    |                 137 |    5,571,270.03 |                       5.07 |

---

### Query 7: Retail Customer Lifetime Spend Deciles (NTILE Window Function)

```sql
WITH customer_lifetime_spend AS (
        SELECT 
            dc.CustomerKey,
            dc.FirstName || ' ' || dc.LastName AS customer_name,
            SUM(fis.SalesAmount) AS lifetime_spend
        FROM factinternetsales fis
        INNER JOIN dimcustomer dc ON fis.CustomerKey = dc.CustomerKey
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
        ROUND(SUM(lifetime_spend) / (SELECT SUM(SalesAmount) FROM factinternetsales) * 100, 2) AS decile_revenue_share_pct
    FROM deciled_customers
    GROUP BY spend_decile
    ORDER BY spend_decile ASC
```

**Empirical Query Output Table:**

|   spend_decile |   customers_in_decile |   min_spend_in_decile |   max_spend_in_decile |   total_decile_spend |   decile_revenue_share_pct |
|---------------:|----------------------:|----------------------:|----------------------:|---------------------:|---------------------------:|
|           1.00 |              1,849.00 |              4,827.10 |             13,295.38 |        11,826,490.37 |                      40.28 |
|           2.00 |              1,849.00 |              3,271.82 |              4,826.23 |         7,672,381.38 |                      26.13 |
|           3.00 |              1,849.00 |              2,329.98 |              3,271.82 |         4,918,132.22 |                      16.75 |
|           4.00 |              1,849.00 |              1,155.48 |              2,326.96 |         3,089,231.08 |                      10.52 |
|           5.00 |              1,848.00 |                268.25 |              1,155.48 |         1,279,791.63 |                       4.36 |
|           6.00 |              1,848.00 |                 91.97 |                267.84 |           256,051.02 |                       0.87 |
|           7.00 |              1,848.00 |                 66.26 |                 91.97 |           140,617.48 |                       0.48 |
|           8.00 |              1,848.00 |                 39.98 |                 66.26 |            94,705.75 |                       0.32 |
|           9.00 |              1,848.00 |                 24.27 |                 39.98 |            60,263.67 |                       0.21 |
|          10.00 |              1,848.00 |                  2.29 |                 24.27 |            21,012.61 |                       0.07 |

---

### Query 8: Inventory Stock Health & Replenishment Priority (Latest Snapshot)

```sql
WITH latest_snapshot AS (
        SELECT 
            fpi.ProductKey,
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
            ROUND(CAST(fpi.UnitsBalance AS FLOAT) / dp.ReorderPoint, 2) AS stock_to_reorder_ratio
        FROM factproductinventory fpi
        INNER JOIN dimproduct dp ON fpi.ProductKey = dp.ProductKey
        WHERE fpi.MovementDate = (SELECT MAX(MovementDate) FROM factproductinventory)
          AND dp.FinishedGoodsFlag = 1
    )
    SELECT 
        stock_health_status,
        COUNT(*) AS finished_goods_count,
        MIN(UnitsBalance) AS min_stock_balance,
        MAX(UnitsBalance) AS max_stock_balance,
        ROUND(AVG(stock_to_reorder_ratio), 2) AS avg_stock_to_reorder_ratio
    FROM latest_snapshot
    GROUP BY stock_health_status
    ORDER BY MIN(UnitsBalance) ASC
```

**Empirical Query Output Table:**

| stock_health_status   |   finished_goods_count |   min_stock_balance |   max_stock_balance |   avg_stock_to_reorder_ratio |
|:----------------------|-----------------------:|--------------------:|--------------------:|-----------------------------:|
| CRITICAL_SHORTAGE     |                    397 |                   3 |                 500 |                         1.16 |

---

### Query 9: Commercial Reseller Performance by Business Type

```sql
SELECT 
        dr.BusinessType AS customer_business_type,
        COUNT(DISTINCT dr.ResellerKey) AS active_reseller_accounts,
        COUNT(DISTINCT frs.SalesOrderNumber) AS wholesale_orders_placed,
        SUM(frs.OrderQuantity) AS wholesale_units_purchased,
        ROUND(SUM(frs.SalesAmount), 2) AS net_wholesale_revenue,
        ROUND(SUM(frs.SalesAmount) / COUNT(DISTINCT frs.SalesOrderNumber), 2) AS average_order_value,
        ROUND(SUM(frs.SalesAmount - frs.TotalProductCost) / SUM(frs.SalesAmount) * 100, 2) AS realized_gross_margin_pct
    FROM factresellersales frs
    INNER JOIN dimreseller dr ON frs.ResellerKey = dr.ResellerKey
    GROUP BY dr.BusinessType
    ORDER BY net_wholesale_revenue DESC
```

**Empirical Query Output Table:**

| customer_business_type   |   active_reseller_accounts |   wholesale_orders_placed |   wholesale_units_purchased |   net_wholesale_revenue |   average_order_value |   realized_gross_margin_pct |
|:-------------------------|---------------------------:|--------------------------:|----------------------------:|------------------------:|----------------------:|----------------------------:|
| Warehouse                |                        219 |                      1335 |                      111993 |           38,726,913.48 |             29,008.92 |                       -0.01 |
| Value Added Reseller     |                        216 |                      1316 |                       80309 |           34,967,517.33 |             26,571.06 |                        1.28 |
| Specialty Bike Shop      |                        200 |                      1145 |                       22076 |            6,756,166.18 |              5,900.58 |                        0.41 |

---

### Query 10: Sales Representative Quota Attainment Summary

```sql
WITH rep_quarterly_sales AS (
        SELECT 
            frs.EmployeeKey,
            dd.CalendarYear,
            dd.CalendarQuarter,
            SUM(frs.SalesAmount) AS actual_reseller_sales
        FROM factresellersales frs
        INNER JOIN dimdate dd ON frs.OrderDateKey = dd.DateKey
        GROUP BY frs.EmployeeKey, dd.CalendarYear, dd.CalendarQuarter
    ),
    quota_eval AS (
        SELECT 
            fsq.SalesQuotaKey,
            fsq.EmployeeKey,
            fsq.CalendarYear,
            fsq.CalendarQuarter,
            fsq.SalesAmountQuota AS quota_target,
            COALESCE(rqs.actual_reseller_sales, 0) AS actual_sales,
            ROUND(COALESCE(rqs.actual_reseller_sales, 0) / fsq.SalesAmountQuota * 100, 2) AS attainment_pct,
            CASE 
                WHEN COALESCE(rqs.actual_reseller_sales, 0) >= fsq.SalesAmountQuota THEN 'ACHIEVED'
                WHEN COALESCE(rqs.actual_reseller_sales, 0) >= fsq.SalesAmountQuota * 0.85 THEN 'NEAR_TARGET'
                ELSE 'BELOW_TARGET'
            END AS performance_bracket
        FROM factsalesquota fsq
        LEFT JOIN rep_quarterly_sales rqs 
            ON fsq.EmployeeKey = rqs.EmployeeKey 
           AND fsq.CalendarYear = rqs.CalendarYear 
           AND fsq.CalendarQuarter = rqs.CalendarQuarter
    )
    SELECT 
        performance_bracket,
        COUNT(*) AS quota_assignments_count,
        ROUND(AVG(attainment_pct), 2) AS avg_attainment_pct,
        ROUND(SUM(quota_target), 2) AS total_assigned_quota,
        ROUND(SUM(actual_sales), 2) AS total_realized_sales
    FROM quota_eval
    GROUP BY performance_bracket
    ORDER BY MIN(attainment_pct) DESC
```

**Empirical Query Output Table:**

| performance_bracket   |   quota_assignments_count |   avg_attainment_pct |   total_assigned_quota |   total_realized_sales |
|:----------------------|--------------------------:|---------------------:|-----------------------:|-----------------------:|
| ACHIEVED              |                        49 |               348.85 |          20,336,000.00 |          24,065,002.43 |
| NEAR_TARGET           |                        30 |                92.50 |          21,966,000.00 |          20,244,291.37 |
| BELOW_TARGET          |                        84 |                51.67 |          53,412,000.00 |          30,335,473.18 |

---
