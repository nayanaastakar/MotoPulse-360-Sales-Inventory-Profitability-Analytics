# MotoPulse 360: Analytical Methodology & KPI Definitions

**Project:** MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform  
**Target Environment:** MySQL 8.x Community Server & Power BI Desktop  
**Dataset Disclosure:** Microsoft AdventureWorksDW (Fictional synthetic bicycle manufacturing, retail, and commercial wholesale data). Not real motorcycle industry data.  
**Date:** 2026-10-20  

---

## 1. Executive Purpose & Governance Principles

The purpose of this document is to establish a rigorous, standardized semantic layer for the **MotoPulse 360** analytics platform. In enterprise business intelligence and data analytics, semantic drift—where different departments calculate "revenue", "profit", or "orders" using incompatible formulas or at different grains—leads to conflicting reports, double-counted financials, and erroneous leadership decisions.

### Core Governance Principles
1. **Financial Integrity:** Top-line revenue must strictly represent **Net Sales Revenue** (gross extended sales minus volume and promotional discounts). Sales taxes and freight fees are operational pass-throughs and must never be aggregated into product revenue.
2. **Standard-Cost Profitability Disclosure:** In AdventureWorksDW, product costs represent management accounting standards (`StandardCost`), not dynamic supplier invoice costs. Gross profit must always be explicitly designated as *"Gross Profit based on standard cost (model value, not observed supplier invoice cost)"*.
3. **Grain Discipline:** 
   - Sales facts operate at the **order line grain** `(SalesOrderNumber, SalesOrderLineNumber)`.
   - Distinct orders must be computed via `COUNT(DISTINCT SalesOrderNumber)`.
   - Average Order Value (AOV) must strictly be evaluated at the **order level** (`Net Sales / Distinct Orders`), never as an average of individual order lines.
   - Inventory operates at the **daily product snapshot grain** `(ProductKey, DateKey)`. Sales lines and inventory snapshots must never be joined directly at transaction level.
4. **Currency Standardization:** Transaction values in both `FactInternetSales` and `FactResellerSales` are recorded in corporate base currency (USD). Foreign currency rates in `FactCurrencyRate` provide historical exchange rates for international pricing analysis.

---

## 2. Comprehensive Metric Definitions & Mathematical Formulas

### 2.1. Sales & Revenue Metrics

#### A. Gross Sales Amount
- **Business Meaning:** Total nominal transaction value before any line-level discounts, customer price concessions, or promotional deductions.
- **Natural Grain:** Sales Order Line
- **Formula:**
  $$\text{Gross Sales Amount} = \sum (\text{OrderQuantity} \times \text{UnitPrice}) = \sum \text{ExtendedAmount}$$
- **SQL Implementation:** `SUM(ExtendedAmount)` or `SUM(OrderQuantity * UnitPrice)`
- **Behavioral Note:** In direct retail Internet sales, Gross Sales exactly equals Net Sales because line-level discounts are zero. In commercial wholesale, Gross Sales represents pre-discount contract volume.

#### B. Discount Amount
- **Business Meaning:** Monetary value deducted from gross sales due to volume discount tiers or promotional agreements.
- **Natural Grain:** Sales Order Line
- **Formula:**
  $$\text{Discount Amount} = \sum (\text{ExtendedAmount} \times \text{UnitPriceDiscountPct})$$
- **SQL Implementation:** `SUM(DiscountAmount)`
- **Observed Behavior:** Direct consumer sales has \$0.00 discounts (0.0%). Commercial wholesale sales has \$527,507.93 in volume discounts across 3,282 discounted order lines (discounts up to 40%).

#### C. Net Sales Revenue (Headline Revenue)
- **Business Meaning:** The definitive top-line commercial revenue recognized by the business after all contractual discounts have been deducted.
- **Natural Grain:** Sales Order Line
- **Formula:**
  $$\text{Net Sales Revenue} = \text{Gross Sales Amount} - \text{Discount Amount} = \sum \text{SalesAmount}$$
- **SQL Implementation:** `SUM(SalesAmount)`
- **Audit Verification:** Empirically verified across 100.0% of rows (121,253 / 121,253) that `SalesAmount = ExtendedAmount - DiscountAmount`.

#### D. Units Sold
- **Business Meaning:** Physical quantity of finished goods or accessories dispatched to customers.
- **Natural Grain:** Sales Order Line
- **Formula:**
  $$\text{Units Sold} = \sum \text{OrderQuantity}$$
- **SQL Implementation:** `SUM(OrderQuantity)`

#### E. Distinct Orders
- **Business Meaning:** Count of distinct purchase transactions (invoices/orders) completed by customers.
- **Natural Grain:** Sales Order Header
- **Formula:**
  $$\text{Distinct Orders} = \text{COUNT}(\text{DISTINCT } \text{SalesOrderNumber})$$
- **Critical Anti-Pattern:** Never use `COUNT(*)` as an order count. In `fact_sales_line`, `COUNT(*)` returns line count (121,253 lines), whereas `COUNT(DISTINCT SalesOrderNumber)` returns true order count (31,455 orders: 27,659 retail + 3,796 wholesale).

#### F. Average Order Value (AOV)
- **Business Meaning:** Average net sales revenue generated per completed customer order.
- **Natural Grain:** Order Header
- **Formula:**
  $$\text{Average Order Value (AOV)} = \frac{\text{Total Net Sales Revenue}}{\text{Total Distinct Orders}} = \frac{\sum \text{SalesAmount}}{\text{COUNT}(\text{DISTINCT } \text{SalesOrderNumber})}$$
- **SQL Implementation:** `SUM(SalesAmount) / COUNT(DISTINCT SalesOrderNumber)`
- **Analytical Distinction:**
  * Retail Internet AOV = \$29,358,677.22 / 27,659 = **\$1,061.45 per order** (low basket size, high unit cost bikes).
  * Wholesale Reseller AOV = \$80,450,596.98 / 3,796 = **\$21,193.52 per order** (bulk B2B commercial shipments).

---

### 2.2. Profitability & Cost Metrics

#### A. Total Product Cost (Standard Cost)
- **Business Meaning:** Estimated inventory standard cost allocated to sold goods based on management cost standards.
- **Natural Grain:** Sales Order Line
- **Formula:**
  $$\text{Total Product Cost} = \sum (\text{OrderQuantity} \times \text{ProductStandardCost})$$
- **SQL Implementation:** `SUM(TotalProductCost)`
- **Empirical Baseline:** Verified 100.0% across all 121,253 lines that `TotalProductCost = OrderQuantity * ProductStandardCost`.

#### B. Gross Profit (Standard-Cost Basis)
- **Business Meaning:** Residual revenue after deducting standard manufacturing and assembly costs.
- **Natural Grain:** Sales Order Line
- **Formula:**
  $$\text{Gross Profit} = \text{Net Sales Revenue} - \text{Total Product Cost} = \sum (\text{SalesAmount} - \text{TotalProductCost})$$
- **SQL Implementation:** `SUM(SalesAmount - TotalProductCost)`
- **Mandatory Reporting Label:** *"Gross Profit based on standard cost (model value, not observed supplier invoice cost)"*.

#### C. Gross Margin Percentage
- **Business Meaning:** Proportion of net sales revenue converted into gross profit.
- **Formula:**
  $$\text{Gross Margin \%} = \frac{\text{Gross Profit}}{\text{Net Sales Revenue}} = \frac{\sum (\text{SalesAmount} - \text{TotalProductCost})}{\sum \text{SalesAmount}}$$
- **SQL Implementation:** `ROUND(SUM(SalesAmount - TotalProductCost) / SUM(SalesAmount) * 100, 2)`
- **Empirical Baseline:**
  * Direct Retail Internet Margin: **41.15%** (\$12,080,883.65 profit / \$29,358,677.22 sales)
  * Commercial Wholesale Reseller Margin: **0.58%** (\$470,482.60 profit / \$80,450,596.98 sales)
  * Consolidated Business Margin: **11.43%** (\$12,551,366.25 profit / \$109,809,274.20 sales)

---

### 2.3. Time Intelligence & Growth Metrics

#### A. Month-over-Month (MoM) Revenue Growth %
- **Business Meaning:** Percentage change in net sales revenue compared to the immediate prior calendar month.
- **Formula:**
  $$\text{MoM Growth \%} = \frac{\text{Revenue}_{\text{Current Month}} - \text{Revenue}_{\text{Prior Month}}}{\text{Revenue}_{\text{Prior Month}}} \times 100$$
- **SQL Implementation:**
  ```sql
  (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY year_month)) 
  / LAG(monthly_revenue, 1) OVER (ORDER BY year_month) * 100
  ```

#### B. Cumulative Running Total Revenue
- **Business Meaning:** Year-to-date or all-time continuous accumulation of net sales revenue over chronological months.
- **SQL Implementation:**
  ```sql
  SUM(monthly_revenue) OVER (
      PARTITION BY channel 
      ORDER BY year_month 
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )
  ```

#### C. 3-Month Moving Average Revenue
- **Business Meaning:** Smoothed trend line filtering out monthly sales volatility.
- **SQL Implementation:**
  ```sql
  AVG(monthly_revenue) OVER (
      PARTITION BY channel 
      ORDER BY year_month 
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  )
  ```

---

### 2.4. Operational Inventory Metrics

#### A. Daily Inventory Balance (`UnitsBalance`)
- **Natural Grain:** Product x Calendar Date
- **Formula:**
  $$\text{UnitsBalance}_{\text{Today}} = \text{UnitsBalance}_{\text{Yesterday}} + \text{UnitsIn} - \text{UnitsOut}$$
- **SQL Implementation:** `UnitsBalance` from `fact_product_inventory`

#### B. Stock-to-Reorder Ratio
- **Business Meaning:** Index measuring current inventory cushion relative to the product's defined replenishment trigger point.
- **Formula:**
  $$\text{Stock-to-Reorder Ratio} = \frac{\text{UnitsBalance}}{\text{ReorderPoint}}$$
- **SQL Implementation:** `ROUND(UnitsBalance / ReorderPoint, 2)`

#### C. Replenishment Health Status Flag
- **Business Meaning:** Categorical prioritization for warehouse purchasing and production runs.
- **Evaluation Logic:**
  * If `UnitsBalance <= SafetyStockLevel` -> `'CRITICAL_SHORTAGE'` (immediate stockout risk).
  * If `UnitsBalance <= ReorderPoint` -> `'REORDER_RECOMMENDED'` (reorder point breached).
  * If `UnitsBalance > ReorderPoint` -> `'SUFFICIENT'` (inventory healthy).

---

### 2.5. Sales Performance Metrics

#### A. Sales Quota Attainment %
- **Natural Grain:** Sales Representative x Calendar Quarter
- **Formula:**
  $$\text{Quota Attainment \%} = \frac{\text{Actual Reseller Net Sales Revenue}_{\text{Rep, Quarter}}}{\text{SalesAmountQuota}_{\text{Rep, Quarter}}} \times 100$$
- **SQL Implementation:** `ROUND(SUM(frs.SalesAmount) / fsq.SalesAmountQuota * 100, 2)`

---

## 3. Explicit Boundaries: Unsupported Questions & Limitations

| Analytical Question | Data Availability Status | Technical / Domain Reason | Analytical Guardrail in MotoPulse 360 |
|---|---|---|---|
| **Payment Gateway Processing Fees** | **UNSUPPORTED** | AdventureWorksDW contains no fee schedule or merchant payment processing records. | Never invent fee percentages (e.g. 2.9% + \$0.30). Revenue is evaluated gross of processing fees. |
| **Customer Returns & Return Rates** | **UNSUPPORTED** | The data warehouse schema contains no return fact table, return quantity, or refund status flag. | All recorded sales orders are treated as completed shipments. Do not infer return rates. |
| **Warehouse-Specific Stock & Bin Locations** | **UNSUPPORTED** | `FactProductInventory` contains no warehouse dimension foreign key. Tracking is enterprise-level. | "Warehouse" in `DimReseller` is recognized as a customer business category, not internal storage. |
| **Stockout Incidents & Lost Demand** | **UNSUPPORTED** | The database captures completed sales and daily ending stock balances, but no unfulfilled cart demand. | Never infer lost sales revenue from inventory dips alone. |
| **Actual Observed Supplier Invoice Cost** | **UNSUPPORTED** | `ProductStandardCost` is an internal cost-accounting standard, not dynamic supplier invoices. | Label gross profit as based on standard cost model values. |
