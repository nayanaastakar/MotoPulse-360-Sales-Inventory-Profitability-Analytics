# MotoPulse 360: Production DAX Measures Reference & Formula Guide

**Document Version:** 1.0  
**Target Platform:** Power BI Desktop / Analysis Services (DAX)  
**Standard Practice:** Store all measures in a dedicated calculation table named `_Measures` to ensure maintainability and clean UI presentation.

---

## 1. Setting Up the Dedicated Measure Table

To organize measures professionally in Power BI:
1. In the **Home** tab, click **Enter Data**.
2. Name the table `_Measures` and column `Placeholder`. Click **Load**.
3. Create your first measure in `_Measures`.
4. Right-click the column `Placeholder` and select **Delete from model**.
5. Power BI will promote `_Measures` to the top of the Data pane with a calculator icon.

---

## 2. Comprehensive DAX Measure Catalog

### Folder: `01. Core Sales & Volume`

#### `[Gross Sales]`
- **DAX Formula:**
  ```dax
  Gross Sales = 
  SUM(vw_sales_fact[ExtendedAmount])
  ```
- **Description:** Sum of line item prices before any commercial volume discounts are applied.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$110,336,782.09**

#### `[Discount Amount]`
- **DAX Formula:**
  ```dax
  Discount Amount = 
  SUM(vw_sales_fact[DiscountAmount])
  ```
- **Description:** Total commercial volume discounts deducted on reseller wholesale transactions. (Direct consumer retail has zero discounts).
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$527,507.93**

#### `[Net Sales]`
- **DAX Formula:**
  ```dax
  Net Sales = 
  SUM(vw_sales_fact[SalesAmount])
  ```
- **Description:** Authoritative topline realized revenue (`Gross Sales - Discount Amount`). Excludes freight and sales tax.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$109,809,274.20**

#### `[Units Sold]`
- **DAX Formula:**
  ```dax
  Units Sold = 
  SUM(vw_sales_fact[OrderQuantity])
  ```
- **Description:** Total physical product units delivered across all channels.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Whole Number (`#,##0`)
- **Validation Benchmark:** **274,776**

#### `[Total Orders]`
- **DAX Formula:**
  ```dax
  Total Orders = 
  DISTINCTCOUNT(vw_sales_fact[SalesOrderNumber])
  ```
- **Description:** Count of unique commercial purchase orders and retail customer checkout events.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Whole Number (`#,##0`)
- **Validation Benchmark:** **31,455**

#### `[Order Lines]`
- **DAX Formula:**
  ```dax
  Order Lines = 
  COUNTROWS(vw_sales_fact)
  ```
- **Description:** Total transactional line items recorded in the unified sales grain.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Whole Number (`#,##0`)
- **Validation Benchmark:** **121,253**

#### `[Average Order Value (AOV)]`
- **DAX Formula:**
  ```dax
  Average Order Value (AOV) = 
  DIVIDE([Net Sales], [Total Orders], 0)
  ```
- **Description:** Net sales revenue realized per distinct order. Safely handles zero-order edge cases using `DIVIDE()`.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$3,491.00**

#### `[Average Items per Order]`
- **DAX Formula:**
  ```dax
  Average Items per Order = 
  DIVIDE([Units Sold], [Total Orders], 0)
  ```
- **Description:** Average physical basket quantity per transaction.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Decimal Number (`#,##0.0`)
- **Validation Benchmark:** **8.7**

#### `[Discount Rate %]`
- **DAX Formula:**
  ```dax
  Discount Rate % = 
  DIVIDE([Discount Amount], [Gross Sales], 0)
  ```
- **Description:** Percentage of gross contract value surrendered to promotional/volume discounts.
- **Display Folder:** `01. Core Sales & Volume`
- **Format:** Percentage (`0.00%`)
- **Validation Benchmark:** **0.48%** (Consolidated) | **0.65%** (Wholesale)

---

### Folder: `02. Cost & Profitability (Standard Cost)`

#### `[Total Product Cost]`
- **DAX Formula:**
  ```dax
  Total Product Cost = 
  SUM(vw_sales_fact[TotalProductCost])
  ```
- **Description:** Sum of standard manufacturing costs associated with goods sold (`StandardCost * OrderQuantity`). Reflects predetermined managerial standard cost, not supplier invoice cost.
- **Display Folder:** `02. Cost & Profitability (Standard Cost)`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$97,257,907.95**

#### `[Gross Profit]`
- **DAX Formula:**
  ```dax
  Gross Profit = 
  [Net Sales] - [Total Product Cost]
  ```
- **Description:** Managerial gross profit earned on product sales before operating expenses, logistics, and overhead.
- **Display Folder:** `02. Cost & Profitability (Standard Cost)`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$12,551,366.25**

#### `[Gross Margin %]`
- **DAX Formula:**
  ```dax
  Gross Margin % = 
  DIVIDE([Gross Profit], [Net Sales], 0)
  ```
- **Description:** Profitability percentage realized per dollar of net sales.
- **Display Folder:** `02. Cost & Profitability (Standard Cost)`
- **Format:** Percentage (`0.00%`)
- **Validation Benchmark:** **11.43%**

---

### Folder: `03. Channel Intelligence`

#### `[Retail Net Sales]`
- **DAX Formula:**
  ```dax
  Retail Net Sales = 
  CALCULATE([Net Sales], KEEPFILTERS(vw_sales_fact[Channel] = "Internet"))
  ```
- **Description:** Direct-to-consumer B2C revenue from online store purchases.
- **Display Folder:** `03. Channel Intelligence`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$29,358,677.22**

#### `[Wholesale Net Sales]`
- **DAX Formula:**
  ```dax
  Wholesale Net Sales = 
  CALCULATE([Net Sales], KEEPFILTERS(vw_sales_fact[Channel] = "Reseller"))
  ```
- **Description:** Commercial B2B revenue from wholesale bike shops and distributors.
- **Display Folder:** `03. Channel Intelligence`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$80,450,596.98**

#### `[Retail Gross Profit]`
- **DAX Formula:**
  ```dax
  Retail Gross Profit = 
  CALCULATE([Gross Profit], KEEPFILTERS(vw_sales_fact[Channel] = "Internet"))
  ```
- **Description:** Direct retail gross margin contribution.
- **Display Folder:** `03. Channel Intelligence`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$12,080,883.65**

#### `[Wholesale Gross Profit]`
- **DAX Formula:**
  ```dax
  Wholesale Gross Profit = 
  CALCULATE([Gross Profit], KEEPFILTERS(vw_sales_fact[Channel] = "Reseller"))
  ```
- **Description:** Wholesale commercial gross margin contribution.
- **Display Folder:** `03. Channel Intelligence`
- **Format:** Currency (`$#,##0.00`)
- **Validation Benchmark:** **$470,482.60**

#### `[Retail Gross Margin %]`
- **DAX Formula:**
  ```dax
  Retail Gross Margin % = 
  DIVIDE([Retail Gross Profit], [Retail Net Sales], 0)
  ```
- **Description:** High-margin direct retail return.
- **Display Folder:** `03. Channel Intelligence`
- **Format:** Percentage (`0.00%`)
- **Validation Benchmark:** **41.15%**

#### `[Wholesale Gross Margin %]`
- **DAX Formula:**
  ```dax
  Wholesale Gross Margin % = 
  DIVIDE([Wholesale Gross Profit], [Wholesale Net Sales], 0)
  ```
- **Description:** High-volume wholesale margin return.
- **Display Folder:** `03. Channel Intelligence`
- **Format:** Percentage (`0.00%`)
- **Validation Benchmark:** **0.58%**

---

### Folder: `04. Time Intelligence & Variance`

#### `[Net Sales Prior Year]`
- **DAX Formula:**
  ```dax
  Net Sales Prior Year = 
  CALCULATE(
      [Net Sales],
      SAMEPERIODLASTYEAR(vw_dim_date[Date])
  )
  ```
- **Description:** Net sales in the equivalent period of the previous calendar year.
- **Display Folder:** `04. Time Intelligence & Variance`
- **Format:** Currency (`$#,##0.00`)

#### `[Net Sales YoY Growth $]`
- **DAX Formula:**
  ```dax
  Net Sales YoY Growth $ = 
  VAR CurrentSales = [Net Sales]
  VAR PreviousSales = [Net Sales Prior Year]
  RETURN
  IF(NOT ISBLANK(PreviousSales), CurrentSales - PreviousSales, BLANK())
  ```
- **Description:** Year-over-year revenue difference.
- **Display Folder:** `04. Time Intelligence & Variance`
- **Format:** Currency (`$#,##0.00`)

#### `[Net Sales YoY Growth %]`
- **DAX Formula:**
  ```dax
  Net Sales YoY Growth % = 
  DIVIDE([Net Sales YoY Growth $], [Net Sales Prior Year], BLANK())
  ```
- **Description:** Year-over-year revenue expansion rate.
- **Display Folder:** `04. Time Intelligence & Variance`
- **Format:** Percentage (`0.0%`)

#### `[Net Sales MoM Growth $]`
- **DAX Formula:**
  ```dax
  Net Sales MoM Growth $ = 
  VAR CurrentSales = [Net Sales]
  VAR PrevMonthSales = CALCULATE([Net Sales], DATEADD(vw_dim_date[Date], -1, MONTH))
  RETURN
  IF(NOT ISBLANK(PrevMonthSales), CurrentSales - PrevMonthSales, BLANK())
  ```
- **Description:** Month-over-month revenue variation.
- **Display Folder:** `04. Time Intelligence & Variance`
- **Format:** Currency (`$#,##0.00`)

#### `[Net Sales YTD]`
- **DAX Formula:**
  ```dax
  Net Sales YTD = 
  TOTALYTD([Net Sales], vw_dim_date[Date])
  ```
- **Description:** Cumulative calendar year-to-date revenue accumulation.
- **Display Folder:** `04. Time Intelligence & Variance`
- **Format:** Currency (`$#,##0.00`)

---

### Folder: `05. Contribution & Dynamic Rankings`

#### `[% of Total Sales (Filtered)]`
- **DAX Formula:**
  ```dax
  % of Total Sales (Filtered) = 
  DIVIDE(
      [Net Sales],
      CALCULATE([Net Sales], ALLSELECTED(vw_sales_fact)),
      0
  )
  ```
- **Description:** Relative contribution of the currently grouped dimension (category, territory, channel) against the active filtered context.
- **Display Folder:** `05. Contribution & Dynamic Rankings`
- **Format:** Percentage (`0.0%`)

#### `[Product Revenue Rank]`
- **DAX Formula:**
  ```dax
  Product Revenue Rank = 
  IF(
      NOT ISBLANK([Net Sales]),
      RANKX(
          ALLSELECTED(vw_dim_product[ProductName]),
          [Net Sales],
          ,
          DESC,
          Dense
      )
  )
  ```
- **Description:** Dynamic ranking of individual product revenue within the selected visual context.
- **Display Folder:** `05. Contribution & Dynamic Rankings`
- **Format:** Whole Number (`0`)

---

### Folder: `06. Inventory & Operational Health`

#### `[Current Stock Balance]`
- **DAX Formula:**
  ```dax
  Current Stock Balance = 
  SUM(vw_inventory_latest[UnitsBalance])
  ```
- **Description:** Physical units currently on hand in the latest verified inventory snapshot.
- **Display Folder:** `06. Inventory & Operational Health`
- **Format:** Whole Number (`#,##0`)

#### `[Safety Stock Threshold]`
- **DAX Formula:**
  ```dax
  Safety Stock Threshold = 
  SUM(vw_inventory_latest[SafetyStockLevel])
  ```
- **Description:** Minimum buffer inventory required to prevent stockouts.
- **Display Folder:** `06. Inventory & Operational Health`
- **Format:** Whole Number (`#,##0`)

#### `[Critical Stock Shortage Items]`
- **DAX Formula:**
  ```dax
  Critical Stock Shortage Items = 
  CALCULATE(
      COUNTROWS(vw_inventory_latest),
      vw_inventory_latest[StockStatus] = "Critical Shortage"
  )
  ```
- **Description:** Count of catalog SKUs whose current balance is strictly below their designated safety stock level.
- **Display Folder:** `06. Inventory & Operational Health`
- **Format:** Whole Number (`#,##0`)

#### `[Reorder Alert Items]`
- **DAX Formula:**
  ```dax
  Reorder Alert Items = 
  CALCULATE(
      COUNTROWS(vw_inventory_latest),
      vw_inventory_latest[StockStatus] IN {"Critical Shortage", "Reorder Needed"}
  )
  ```
- **Description:** Total product lines that have triggered procurement replenishment thresholds.
- **Display Folder:** `06. Inventory & Operational Health`
- **Format:** Whole Number (`#,##0`)

#### `[Total Stock Deficit Units]`
- **DAX Formula:**
  ```dax
  Total Stock Deficit Units = 
  SUM(vw_inventory_latest[StockDeficit])
  ```
- **Description:** Cumulative shortfall units required to restore all depleted products back up to their reorder points.
- **Display Folder:** `06. Inventory & Operational Health`
- **Format:** Whole Number (`#,##0`)
