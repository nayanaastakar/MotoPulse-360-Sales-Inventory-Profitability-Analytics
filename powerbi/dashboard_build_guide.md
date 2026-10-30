# MotoPulse 360: Executive Power BI Dashboard Build Guide

**Document Version:** 1.0  
**Target Platform:** Power BI Desktop  
**Canvas Resolution:** 16:9 Standard (`1280 x 720` or `1920 x 1080`)  
**Design Philosophy:** Enterprise executive presentation — high data density, clear visual hierarchy, accessible contrast, and zero clutter.

---

## 1. Visual Style Guide & Design Tokens

### 1.1 Executive Color Palette
| Token Name | Hex Code | Visual Application |
|---|---|---|
| **Primary Navy** | `#0F172A` | Canvas background, card containers, primary headers |
| **Surface Slate** | `#1E293B` | Visual container card backgrounds, table headers |
| **Accent Electric Blue** | `#2563EB` | Retail channel, primary revenue bars, active highlights |
| **Accent Cyan** | `#06B6D4` | Wholesale channel, secondary time comparisons |
| **Success Emerald** | `#10B981` | Positive variance, profitable subcategories, adequate stock |
| **Warning Amber** | `#F59E0B` | Reorder warning threshold, minor discount erosion |
| **Alert Crimson** | `#EF4444` | Negative margins, critical inventory stockouts, discount leakage |
| **Neutral White/Text** | `#F8FAFC` | Primary labels, KPI callout values |
| **Muted Silver/Text** | `#94A3B8` | Axis labels, card captions, secondary notes |

### 1.2 Global Typography
- **KPI Callout Values:** `Segoe UI Bold`, 24–28 pt, `#F8FAFC`
- **Visual Titles:** `Segoe UI Semibold`, 12–14 pt, `#F8FAFC`
- **Axis & Data Labels:** `Segoe UI`, 9–10 pt, `#94A3B8`
- **Tables & Matrix Cells:** `Segoe UI`, 10 pt, `#F8FAFC`

---

## 2. Page 1: Executive Overview Dashboard

**Purpose:** Provide C-suite stakeholders with an immediate, high-level view of company health, revenue velocity, gross profitability, and regional market distribution.

```
+-------------------------------------------------------------------------------------------------------+
|  MOTOPULSE 360 | Executive Sales & Profitability Overview             [Filter: Year] [Channel] [Territory]  |
+-------------------------------------------------------------------------------------------------------+
|  [CARD: Net Sales]   |  [CARD: Gross Profit]   |  [CARD: Gross Margin]   |  [CARD: Orders / Units]     |
|     $109.81M         |       $12.55M           |         11.43%          |       31.5K / 274.8K        |
+---------------------------------------------+---------------------------------------------------------+
|                                             |                                                         |
|  VISUAL 1: Monthly Revenue & Profit Trend   |  VISUAL 2: Category Revenue & Profitability             |
|  (Line & Clustered Column: Sales vs Cost)   |  (Horizontal Clustered Bar: Net Sales & Margin %)       |
|                                             |                                                         |
+---------------------------------------------+---------------------------------------------------------+
|                                             |                                                         |
|  VISUAL 3: Sales by Territory               |  VISUAL 4: Channel Contribution Split                   |
|  (Treemap / Filled Map: Revenue by Country) |  (Donut: Retail $29.36M vs Wholesale $80.45M)           |
|                                             |                                                         |
+-------------------------------------------------------------------------------------------------------+
```

### 2.1 Top Banner & Global Slicers
- **Title Block:** `MotoPulse 360 | Executive Sales & Profitability Overview`
- **Sub-label:** *Source: Microsoft AdventureWorksDW (Synthetic Bicycle Enterprise Modeling)*
- **Slicers (Horizontal dropdowns in top-right header):**
  1. `vw_dim_date[CalendarYear]` (Dropdown: All, 2011, 2012, 2013, 2014)
  2. `vw_sales_fact[Channel]` (Buttons / Tile: All, Internet, Reseller)
  3. `vw_dim_territory[SalesTerritoryCountry]` (Dropdown)

### 2.2 Executive KPI Scorecards (Top Row)
1. **Net Sales Revenue:**
   - Field: `_Measures[Net Sales]`
   - Display: `$109.81M`
   - Secondary Label: `Gross Sales $110.34M (-$527.5K Discounts)`
2. **Gross Profit (Standard Cost):**
   - Field: `_Measures[Gross Profit]`
   - Display: `$12.55M`
   - Secondary Label: `Model standard cost basis`
3. **Gross Margin %:**
   - Field: `_Measures[Gross Margin %]`
   - Display: `11.43%`
   - Target Color: Green if $\ge 10\%$, Amber if $5\%\text{--}10\%$, Red if $< 5\%$
4. **Order Volume & Velocity:**
   - Field: `_Measures[Total Orders]` & `_Measures[Units Sold]`
   - Display: `31,455 Orders | 274,776 Units`
   - Secondary Label: `AOV: $3,491.00`

### 2.3 Visual Configurations
- **Visual 1: Monthly Net Sales & Cost Velocity**
  - Type: **Line and Clustered Column Chart**
  - X-Axis: `vw_dim_date[Date]` (Continuous, aggregated by Month)
  - Column Y-Axis: `_Measures[Net Sales]` (Accent Blue `#2563EB`)
  - Line Y-Axis: `_Measures[Gross Profit]` (Success Emerald `#10B981`)
  - Data Labels: Off (enabled on hover tooltip)
- **Visual 2: Category Revenue & Profit Breakdown**
  - Type: **Clustered Bar Chart**
  - Y-Axis: `vw_dim_product[CategoryName]` (Bikes, Components, Clothing, Accessories)
  - X-Axis: `_Measures[Net Sales]`
  - Tooltips: `_Measures[Gross Profit]`, `_Measures[Gross Margin %]`, `_Measures[Units Sold]`
- **Visual 3: Geographic Sales by Territory**
  - Type: **Treemap** (or **Filled Map**)
  - Group: `vw_dim_territory[SalesTerritoryCountry]`
  - Details: `vw_dim_territory[SalesTerritoryRegion]`
  - Values: `_Measures[Net Sales]`
  - Data Colors: Gradient based on `_Measures[Gross Margin %]`
- **Visual 4: Channel Contribution Split**
  - Type: **Donut Chart**
  - Legend: `vw_sales_fact[Channel]` (Retail / Internet, Wholesale / Reseller)
  - Values: `_Measures[Net Sales]`
  - Detail Labels: `Category, Data value, Percent of total`

---

## 3. Page 2: Product & Channel Intelligence

**Purpose:** Equip sales directors and product managers to diagnose profitability drivers, compare retail vs. wholesale dynamics, identify high-volume loss-leaders, and examine discount leakage.

```
+-------------------------------------------------------------------------------------------------------+
|  MOTOPULSE 360 | Product & Commercial Channel Intelligence           [Category Slicer] [Subcategory]  |
+-------------------------------------------------------------------------------------------------------+
|  [CARD: Retail Margin] | [CARD: Wholesale Margin] | [CARD: Wholesale AOV] | [CARD: Discount Leakage]  |
|         41.15%         |          0.58%           |        $21,194        |         -$527.5K          |
+---------------------------------------------+---------------------------------------------------------+
|                                             |                                                         |
|  VISUAL 1: Top 10 Revenue Products          |  VISUAL 2: Product Volume vs. Revenue Scatter           |
|  (Horizontal Bar: Product vs Margin Color)  |  (X: Units, Y: Net Sales, Bubble Size: Gross Profit)    |
|                                             |                                                         |
+---------------------------------------------+---------------------------------------------------------+
|                                             |                                                         |
|  VISUAL 3: Subcategory Financial Matrix     |  VISUAL 4: Reseller Volume Discount Margin Leakage      |
|  (Table: Subcategory, Sales, Cost, Margin%) |  (Column: Discount Tiers 0%, 1-5%, 6-10%, >10%)        |
|                                             |                                                         |
+-------------------------------------------------------------------------------------------------------+
```

### 3.1 Channel Diagnostic Cards
1. **Retail Gross Margin:** `_Measures[Retail Gross Margin %]` $\rightarrow$ **41.15%** (High-margin direct driver)
2. **Wholesale Gross Margin:** `_Measures[Wholesale Gross Margin %]` $\rightarrow$ **0.58%** (Volume absorption engine)
3. **Wholesale Average Order Value:** `CALCULATE([AOV], vw_sales_fact[Channel] = "Reseller")` $\rightarrow$ **$21,193.50**
4. **Total Discount Concession:** `_Measures[Discount Amount]` $\rightarrow$ **$527,507.93** (3,282 discounted orders)

### 3.2 Visual Configurations
- **Visual 1: Top 10 Revenue Products**
  - Type: **Clustered Bar Chart**
  - Y-Axis: `vw_dim_product[ProductName]` (Filter: Top 10 by `_Measures[Net Sales]`)
  - X-Axis: `_Measures[Net Sales]`
  - Color Saturation / Conditional Formatting: Based on `_Measures[Gross Margin %]` (Red for $<0\%$, Green for $>20\%$)
- **Visual 2: Product Volume vs. Revenue Scatter Plot**
  - Type: **Scatter Chart**
  - Values: `vw_dim_product[ProductName]`
  - X-Axis: `_Measures[Units Sold]`
  - Y-Axis: `_Measures[Net Sales]`
  - Size: `_Measures[Gross Profit]`
  - Legend: `vw_dim_product[CategoryName]`
- **Visual 3: Subcategory Financial Performance Matrix**
  - Type: **Matrix**
  - Rows: `vw_dim_product[CategoryName]`, `vw_dim_product[SubcategoryName]`
  - Values: `_Measures[Net Sales]`, `_Measures[Total Product Cost]`, `_Measures[Gross Profit]`, `_Measures[Gross Margin %]`
  - Conditional Formatting: Background color scale on `[Gross Margin %]` (Diverging: Red at `-15%`, White at `0%`, Green at `+50%`)
- **Visual 4: Wholesale Discount Margin Leakage Analysis**
  - Type: **Clustered Column Chart**
  - X-Axis: Discount Tier (`0% Standard`, `1% - 5%`, `6% - 10%`, `> 10%`)
  - Y-Axis: Gross Margin % (`3.06%`, `-4.40%`, `-8.02%`, `-13.06%`)
  - Secondary Line: Total Net Sales ($)

---

## 4. Page 3: Inventory & Operational Alerts

**Purpose:** Provide procurement and supply chain managers with real-time stockout risk identification, safety stock deficit tracking, and prioritized replenishment lists.

```
+-------------------------------------------------------------------------------------------------------+
|  MOTOPULSE 360 | Supply Chain & Inventory Replenishment Alert Center   [Stock Status Slicer] [Line]   |
+-------------------------------------------------------------------------------------------------------+
|  [CARD: Current Stock] | [CARD: Safety Buffer]    | [CARD: Shortage SKUs] | [CARD: Reorder Deficit]   |
|      602,593 Units     |      487,210 Units       |        84 SKUs        |       142,390 Units       |
+---------------------------------------------+---------------------------------------------------------+
|                                             |                                                         |
|  VISUAL 1: Inventory Health Breakdown       |  VISUAL 2: Top Stock Shortage Deficits by Product       |
|  (Donut: Adequate vs Reorder vs Shortage)   |  (Horizontal Bar: Deficit Units by SKU)                 |
|                                             |                                                         |
+---------------------------------------------+---------------------------------------------------------+
|                                                                                                       |
|  VISUAL 3: Priority Procurement Replenishment Action Grid                                             |
|  (Table: Product Name | Units Balance | Safety Stock | Reorder Point | Deficit | Replenish Status)    |
|                                                                                                       |
+-------------------------------------------------------------------------------------------------------+
```

### 4.1 Visual Configurations
- **Visual 1: Catalog Stock Health Status**
  - Type: **Donut Chart**
  - Legend: `vw_inventory_latest[StockStatus]` (`Adequate Stock`, `Reorder Needed`, `Critical Shortage`)
  - Values: `COUNTROWS(vw_inventory_latest)`
  - Colors: Adequate Stock (`#10B981` Emerald), Reorder Needed (`#F59E0B` Amber), Critical Shortage (`#EF4444` Crimson)
- **Visual 2: Top Product Stock Deficits**
  - Type: **Horizontal Bar Chart**
  - Y-Axis: `vw_inventory_latest[ProductName]` (Filter: Top 15 by `_Measures[Total Stock Deficit Units]`)
  - X-Axis: `_Measures[Total Stock Deficit Units]`
  - Data Color: Crimson (`#EF4444`)
- **Visual 3: Priority Procurement Action Table**
  - Type: **Table**
  - Columns:
    1. `vw_inventory_latest[ProductName]`
    2. `vw_inventory_latest[UnitsBalance]` (Current physical count)
    3. `vw_inventory_latest[SafetyStockLevel]` (Mandated safety threshold)
    4. `vw_inventory_latest[ReorderPoint]` (Procurement trigger)
    5. `vw_inventory_latest[StockDeficit]` (Units required to restock)
    6. `vw_inventory_latest[StockStatus]` (Status indicator)
  - Sorting: Sorted descending by `StockDeficit`
  - Conditional Formatting: Field value or rules on `StockStatus` (Red tag for Critical Shortage, Yellow tag for Reorder Needed).

---

## 5. Report Quality & Validation Checklist

Before presenting the dashboard or capturing screenshots for your portfolio:
- [x] **Consolidated Net Sales Card:** Matches exactly **$109,809,274.20**.
- [x] **Consolidated Gross Profit Card:** Matches exactly **$12,551,366.25**.
- [x] **Consolidated Margin %:** Matches exactly **11.43%**.
- [x] **Order Count Card:** Matches exactly **31,455**.
- [x] **Total Units Sold Card:** Matches exactly **274,776**.
- [x] **Channel Slicer Test:**
  - Selecting `Internet` yields **$29.36M** Sales and **41.15%** Margin.
  - Selecting `Reseller` yields **$80.45M** Sales and **0.58%** Margin.
- [x] **Date Table Sorting:** Months display in chronological sequence (`Jan`, `Feb`, `Mar`...) rather than alphabetical.
- [x] **Disclosure Footer:** Present on all report pages noting Microsoft AdventureWorksDW bicycle business modeling.
