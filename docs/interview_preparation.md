# MotoPulse 360: Interview Preparation Guide & Technical Deep-Dive

**Document Version:** 1.0  
**Target Role:** Data Analyst, Business Intelligence Analyst, Analytics Engineer  
**Core Purpose:** Provide concise, technically rigorous talking points, resume bullet points, an elevator pitch, and 10 detailed interview Q&As grounded directly in the MotoPulse 360 codebase and verified data.

---

## 1. The 60-Second Elevator Pitch

> *"In my portfolio project, **MotoPulse 360**, I architected an end-to-end sales, inventory, and profitability analytics platform modeled after a global multichannel bicycle enterprise using Microsoft AdventureWorksDW data.*
> 
> *The company operates across two distinct commercial channels: Direct-to-Consumer Retail and Commercial Wholesale, spanning 121,253 transaction lines and over $109.8 million in net revenue. I designed a multi-fact constellation schema in MySQL, implemented non-destructive ETL and automated data validation pipelines in Python, and reconciled financial calculations down to the exact penny.*
> 
> *My analysis revealed a critical commercial insight: while Wholesale accounts for 73% of company revenue, it operates at a razor-thin 0.58% gross margin and actually loses money on Road and Touring bikes due to dealer pricing set below standard manufacturing costs. In contrast, Direct Retail generates 96% of total company gross profit at a 41% margin.*
> 
> *I translated these findings into executive Power BI dashboards with DAX measures and actionable recommendations, such as instituting a 5% wholesale price floor and restructuring discount authorization rules to eliminate $2.4M in negative margin leakage."*

---

## 2. Resume Ready Bullet Points (STAR Format)

### Option A: Business Intelligence / Data Analyst Focus
- **Architected an enterprise sales and profitability analytics platform** across Direct Retail and Commercial Wholesale channels ($109.8M Net Sales, 121K lines) using MySQL 8.0, Python (Pandas/NumPy), and Power BI.
- **Engineered a 15-table multi-fact constellation schema**, defining atomic grains, standardizing SCD Type 2 product histories, and establishing single-direction (1:*) star-schema relationships.
- **Identified $2.4M in wholesale margin leakage** across Road and Touring bike lines via multi-dimensional SQL and Pandas profiling, demonstrating that uncalibrated volume discounting caused margins to collapse from +3.06% down to -13.06%.
- **Developed 25+ production DAX measures and 3-page interactive Power BI dashboards** with executive KPI scorecards, time intelligence (MoM/YoY), dynamic ranking, and inventory replenishment alerts for 84 stockout-risk SKUs.

### Option B: Analytics Engineering / Data Engineering Focus
- **Built an automated Python data validation and reconciliation engine** executing 18 integrity assertions across 936K relational records, detecting 3,319 negative inventory balance anomalies without destructive record deletion.
- **Achieved 100% mathematical cross-engine parity ($0.00 discrepancy)** across 20 core business KPIs between MySQL analytical views and Python/Pandas dataframes using arbitrary-precision decimal arithmetic.
- **Authored optimized MySQL analytics queries** leveraging CTEs, window functions (`ROW_NUMBER`, `DENSE_RANK`, `LAG`, `NTILE`), and conditional aggregation to deliver MoM revenue velocity, customer spend deciles, and Pareto ABC classification.

---

## 3. Ten Deep Technical Interview Questions & Grounded Answers

### Q1: What is the grain of your sales data, and how did you prevent double-counting when combining Retail and Wholesale sales?
**Answer:**  
*"The grain of our sales data is **one sales order line**, uniquely identified by the composite key `(SalesOrderNumber, SalesOrderLineNumber, channel)`. In the source AdventureWorksDW schema, retail transactions are stored in `FactInternetSales` (60,398 rows) and wholesale transactions in `FactResellerSales` (60,855 rows).*

*To combine them into a unified `fact_sales_line` table (121,253 rows) without Cartesian inflation or structural collisions:*
1. *I added a discriminating `channel` column ('Internet' vs 'Reseller').*
2. *I enforced mutually exclusive foreign keys: retail rows populate `CustomerKey` with `ResellerKey = NULL`, while wholesale rows populate `ResellerKey` with `CustomerKey = NULL`.*
3. *I verified composite line uniqueness across the stacked dataset, confirming zero duplicate lines.*
4. *Order-level attributes like freight and tax repeat across individual lines in the source data. To prevent multiplying these expenses during line aggregations, I isolated `SalesAmount` (`ExtendedAmount - DiscountAmount`) as the sole basis for Net Sales revenue, treating freight and tax strictly as order-level pass-through metrics."*

---

### Q2: How did you handle Slowly Changing Dimensions (SCD Type 2) in `DimProduct` when analyzing sales performance vs. catalog inventory?
**Answer:**  
*"In `DimProduct`, there are 606 total records representing historical revisions of 397 distinct products (`ProductAlternateKey`), managed as SCD Type 2 with `StartDate`, `EndDate`, and `Status` attributes. Over time, attributes like `StandardCost` and `ListPrice` changed.*

*To handle this correctly:*
- *For **sales and profitability analytics**, we join `fact_sales_line` directly to `DimProduct` on `ProductKey`. This preserves the historical standard cost and list price that were active at the exact moment the sale occurred, guaranteeing historical financial accuracy.*
- *For **current inventory and catalog rollups**, grouping by `ProductKey` would artificially split a single physical bicycle into multiple rows. Therefore, for active catalog analysis and replenishment reporting, we group by `ProductAlternateKey` or filter by `Status = 'Current'` (or `EndDate IS NULL`), ensuring each physical SKU is evaluated as a single operational entity."*

---

### Q3: In your analysis, Wholesale gross margin was reported at only 0.58%. How did you prove this was a genuine business finding and not a bug in your SQL or ETL pipeline?
**Answer:**  
*"When our SQL queries produced an aggregate wholesale gross profit of $470,482.60 on $80,450,596.98 in net sales (a 0.58% margin), we immediately launched a root-cause audit to rule out pipeline defects.*

*I proved the arithmetic through three independent validation steps:*
1. *I wrote a line-by-line verification script in Python (`python/05_reconcile_financial_audit.py`) using `decimal.Decimal` that confirmed `SalesAmount = ExtendedAmount - DiscountAmount` and `TotalProductCost = ProductStandardCost * OrderQuantity` on 100% of all 60,855 wholesale rows.*
2. *I grouped sales by subcategory, which revealed that Mountain Bikes generated healthy profits (+$2.89M at 8.59% margin), but Road Bikes (-$1.17M at -3.99% margin) and Touring Bikes (-$1.24M at -11.84% margin) incurred massive negative margins.*
3. *I inspected the master product catalog (`DimProduct`) and discovered that Microsoft's source data explicitly sets `DealerPrice` lower than `StandardCost` for multiple Road and Touring bike models (e.g. `Road-150 Red, 56` has a dealer price of $2,146.96 vs standard cost of $2,171.29).*
4. *Finally, I analyzed discounting and found that $527,507.93 in volume discounts across 3,282 orders further compressed wholesale margins down to 0.58%. This proved conclusively that the 0.58% margin was a genuine artifact of the underlying business pricing model, not an ETL calculation error."*

---

### Q4: There was a 1-cent discrepancy between individual channel profits and the consolidated total in earlier reports. How did you resolve it?
**Answer:**  
*"That discrepancy was a classic floating-point / banker's rounding artifact arising from the difference between the **sum of rounded numbers** versus the **rounded sum of exact numbers**:*
- *Internet Sales exact profit: `12,080,883.6450` $\rightarrow$ rounds to **$12,080,883.65***
- *Reseller Sales exact profit: `470,482.6033` $\rightarrow$ rounds to **$470,482.60***
- *Summing the two rounded numbers gives **$12,551,366.25***
- *However, if an engine uses standard IEEE 754 floating-point numbers or sums pre-rounded single-precision floats, it can evaluate `12,080,883.6449...` and output $12,080,883.64, which adds up to $12,551,366.24 (a 1-cent variance).*

*I resolved this by enforcing arbitrary-precision `decimal.Decimal` arithmetic in Python and `DECIMAL(19,4)` in MySQL with explicit `ROUND_HALF_UP` rounding. Under exact decimal arithmetic, $12,080,883.65 + $470,482.60 equals exactly **$12,551,366.25**, with zero penny discrepancy."*

---

### Q5: What advanced SQL window functions did you use in `06_advanced_analytics.sql`, and what commercial questions did they solve?
**Answer:**  
*"I implemented several production window function patterns:*
1. **`LAG()` for Month-over-Month Growth:** Calculated sequential monthly revenue expansion, isolating absolute dollar delta and percentage growth across contiguous calendar months.
2. **`SUM() OVER (ORDER BY DateKey)` for Cumulative Running Totals:** Tracked revenue accumulation within fiscal years to measure pacing against annual targets.
3. **`AVG() OVER (ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` for 3-Month Moving Averages:** Smoothed seasonal month-end volatility to identify underlying commercial momentum.
4. **`DENSE_RANK() OVER (PARTITION BY CategoryKey ORDER BY SalesAmount DESC)`:** Ranked the top 5 revenue-generating products within each category to support merchandising rationalization.
5. **`NTILE(10) OVER (ORDER BY TotalSpend DESC)` for Customer Decile Segmentation:** Grouped 18,484 retail customers into 10 spend deciles, proving that the top decile generates over 35% of consumer revenue.
6. **`SUM() OVER (PARTITION BY ResellerKey)` for Partner Concentration:** Identified that the top 5% of wholesale partners account for 38% of B2B volume."*

---

### Q6: You found 3,319 negative inventory records in `FactProductInventory`. Why didn't you delete them during data cleaning?
**Answer:**  
*"In professional data engineering and auditing, **raw operational anomalies should never be deleted destructively** without business stakeholder consultation.*

*A negative warehouse inventory balance (e.g. -5 units on hand) is a common ERP timing anomaly in retail and distribution: it occurs when an outgoing sales shipment is scanned and recorded in the system before the incoming receiving dock purchase order has been posted.*

*Deleting these rows would have distorted physical unit movement history and corrupted balance reconciliation audits. Instead, I applied non-destructive cleaning: I flagged those 3,319 records with a data quality indicator column (`dq_negative_stock = 1`), excluded them from current replenishment threshold queries, but preserved them in the audit trail for supply chain diagnostics."*

---

### Q7: How did you design your Power BI semantic model to ensure single-direction filter propagation and avoid ambiguous relationship paths?
**Answer:**  
*"I built a pure Kimball **Star Schema** centered on `vw_sales_fact` surrounded by 5 conformed dimension tables (`vw_dim_date`, `vw_dim_product`, `vw_dim_customer`, `vw_dim_reseller`, `vw_dim_territory`).*

*Key design decisions:*
1. **Strict 1-to-Many Single Direction:** All relationships flow from the 1-side (dimension primary key) to the *-side (fact foreign key). Bi-directional filtering was explicitly disabled to prevent unexpected cross-table filter contamination.*
2. **Role-Playing Date Handling:** `vw_sales_fact` contains three date keys: `OrderDateKey`, `ShipDateKey`, and `DueDateKey`. I established `OrderDateKey` as the single active relationship. For shipping or due date analysis, the other two relationships remain inactive and are selectively activated in DAX using `USERELATIONSHIP()`.*
3. **Dedicated Measure Table:** I created an isolated `_Measures` table organized into structured display folders (`01. Core Sales`, `02. Profitability`, `03. Time Intelligence`, etc.), completely decoupling report measures from underlying physical table schemas."*

---

### Q8: How did you cross-validate data parity between your SQL analytics views and your Python/Pandas models?
**Answer:**  
*"To guarantee that my findings were 100% reproducible across different analytical environments, I built an automated cross-engine parity matrix in `python/04_sql_python_validation.ipynb`.*

*The validation script extracts identical transactional subsets from the clean data, aggregates them independently using Pandas vector operations, and compares the results against a benchmark dictionary populated directly from our Stage 5 SQL queries.*

*We evaluated 20 distinct metrics across both channels: Order Counts, Line Counts, Units Sold, Gross Sales, Discounts, Net Sales, Total Product Cost, Gross Profit, AOV, and Gross Margin %. The matrix achieved **100% parity**, verifying an exact $0.00 discrepancy on consolidated net sales ($109,809,274.20)."*

---

### Q9: Why did you separate order-level Freight and Tax from line-level Net Sales revenue?
**Answer:**  
*"In retail and wholesale data architecture, mixing line-level revenue with order-level overhead is one of the most common causes of financial distortion.*

*In AdventureWorksDW, each sales order line contains fields for `TaxAmt` and `Freight`. However, these amounts represent either allocated order-level costs or repeated order totals. If an analyst naively writes `SUM(SalesAmount + TaxAmt + Freight)` across line items, they risk summing freight multiple times or confounding merchandise revenue with operational pass-throughs.*

*In MotoPulse 360, I established an explicit financial methodology in `docs/methodology.md`:*
- **Net Sales** is strictly defined as realized product revenue: `SUM(SalesAmount)`.
- **Freight** and **Tax** are classified as operational liabilities and pass-throughs, evaluated strictly at the distinct order grain.
- This ensures that sales commissions, gross margins, and product profitability reflect true product performance without operational noise."*

---

### Q10: Based on your analysis, what are the top three strategic recommendations you would present to the CEO to improve profitability?
**Answer:**  
*"Based on the empirical findings, I would present three immediate strategic actions:*
1. **Institute a +5% Wholesale Dealer Price Floor on Road and Touring Bikes:**  
   *Wholesale Road and Touring bikes lost $2.4M due to dealer wholesale prices set below standard manufacturing costs. Raising wholesale dealer pricing by just 5% immediately eliminates these negative margins and restores commercial sustainability.*
2. **Implement Automated ERP Guardrails on Reseller Volume Discounts:**  
   *Our discount leakage analysis proved that wholesale discounts $>10\%$ yield a ruinous -13.06% gross margin, burning $527.5K in concessions. We should cap sales rep field discounting authority at 2% and require VP approval for anything higher, prohibiting discounts entirely on SKUs with baseline margins below 8%.*
3. **Accelerate Direct-to-Consumer Digital Retail & Cross-Selling:**  
   *Direct Retail earns a 41.15% margin and delivers 96% of our gross profit. Shifting just $2.5M of sales volume from wholesale into retail generates an incremental $1.0M in gross profit. Additionally, merchandising high-margin Accessories (50% margin) as online checkout bundles will significantly expand average order value and profit contribution."*
