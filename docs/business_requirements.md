# MotoPulse 360: Business Requirements & Analytical Scope

**Project Title:** MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform  
**Target Audience:** Fresher Data Analyst Portfolio, Technical Interviews, Executive Stakeholders  
**Date:** 2026-10-20  

---

## 1. Transparency & Dataset Disclosure

> [!IMPORTANT]
> **Data Authenticity Disclosure:**  
> The **MotoPulse 360** platform is built on **Microsoft AdventureWorksDW**, the industry-standard synthetic data warehouse representing a fictional bicycle manufacturing, retail, and commercial wholesale corporation.
> 
> While the platform branding uses the name *MotoPulse 360*, all underlying data entities, product categories (Bikes, Components, Clothing, Accessories), order transactions, and inventory ledgers represent bicycle products. This project makes **zero claims** of being real-world motorcycle industry data, maintaining 100% professional integrity, transparency, and credibility for technical portfolio review.

---

## 2. Business Problem & Executive Context

MotoPulse 360 operates a dual-channel distribution model:
1. **Direct-to-Consumer (B2C) Internet Sales:** High transaction frequency, individual consumer purchases, standard list prices, zero line-level discounts, small basket sizes (average ~2.18 items/order).
2. **Commercial (B2B) Reseller Wholesale:** Low transaction frequency, high volume per order (average ~16.03 items/order), negotiated dealer prices, active volume discounting (up to 40% on qualifying orders), managed by internal sales representatives.

### Key Executive Pain Points:
- **Channel Profitability Disparity:** Executive leadership lacks a single source of truth comparing direct consumer profitability with wholesale reseller margin contribution after volume discounts.
- **Inventory Replenishment Blindspots:** Inventory management struggles to identify items falling below safety stock and reorder thresholds on daily cycles.
- **Geographic & Sales Representative Attribution:** Regional directors need clear visibility into sales territory performance across North America, Europe, and the Pacific, as well as quota attainment for commercial account executives.

---

## 3. Key Stakeholders & Target Personas

| Stakeholder Persona | Primary Focus & Analytical Needs | Key Decisions Supported |
|---|---|---|
| **Chief Commercial Officer (CCO)** | High-level channel revenue, year-over-year expansion, global territory contribution, and customer acquisition trends. | Strategic channel resource allocation; expansion into top-performing regional territories. |
| **Finance Director / Controller** | Gross sales, discount leakage, net sales revenue, gross margin %, and foreign exchange exposure. | Discount policy enforcement; pricing strategies; standard cost review. |
| **Head of Supply Chain & Inventory** | Daily inventory balances, units in vs units out, safety stock violations, and replenishment prioritization. | Production run scheduling; supplier replenishment purchase orders. |
| **Regional Sales Directors** | Territory performance, top/bottom reseller accounts, salesperson quota attainment, and customer demographics. | Sales incentive plans; account management interventions. |

---

## 4. Analytical Scope: Answerable vs Unanswerable Questions

A disciplined data analyst must explicitly state what the data can and cannot answer.

### 4.1. Business Questions Answerable by MotoPulse 360
1. **Revenue & Channel Dynamics:**
   - What is total Net Sales Revenue across Internet and Reseller channels over time?
   - How do order volume, units sold, and Average Order Value (AOV) differ between direct retail consumers and wholesale resellers?
   - What is the Month-over-Month (MoM) revenue growth across product lines?
2. **Product & Category Intelligence:**
   - Which product categories (Bikes vs Components vs Clothing vs Accessories) generate the highest revenue and highest gross profit?
   - What are the top 10 revenue-generating products, and do they exhibit high sales concentration (Pareto 80/20 rule)?
   - How does product versioning (SCD Type 2) impact historical sales analysis?
3. **Discount & Margin Leakage:**
   - What is the effective discount rate granted to commercial resellers by volume tier?
   - How much gross margin is sacrificed to drive wholesale volume?
4. **Geographic & Sales Rep Performance:**
   - Which sales territories (e.g. Northwest, Southwest, Australia, UK, Germany) lead in revenue and order volume?
   - Which commercial sales representatives achieved or exceeded their quarterly sales quotas?
5. **Inventory & Operational Health:**
   - Which products currently hold inventory balances below their designated `ReorderPoint` or `SafetyStockLevel`?
   - What is the current replenishment priority list across finished goods?

### 4.2. Business Questions NOT Answerable (and Why)

| Unanswerable Business Question | Technical / Data Reason | Analytical Guardrail in MotoPulse 360 |
|---|---|---|
| **Payment Gateway Processing Fees** | The schema contains zero payment processing fee columns, interchange fee rates, or payment merchant tables. | Never fabricate or infer payment processing deductions. Net sales is defined prior to payment fees. |
| **Customer Returns & Refund Rates** | The AdventureWorksDW install script contains no `FactReturn`, `ReturnQuantity`, or refund status flags. | Never assume returns. Report all sales orders as completed shipments as recorded. |
| **Warehouse-Specific Stock & Bin Locations** | `FactProductInventory` contains no warehouse dimension key. Inventory is tracked strictly at the enterprise-product level. `DimReseller.BusinessType = 'Warehouse'` is a customer business type, not internal storage. | Inventory analysis is performed at the product level only. Geographic analysis is mapped via `DimSalesTerritory`. |
| **Stockout Frequency & Lost Sales Demand** | The dataset records historical inventory balances and completed transactions, but contains no records of unfulfilled customer demand, abandoned carts, or backorders. | Never infer lost sales revenue from inventory dips alone. |
| **Actual Observed Supplier Invoice Cost** | The `ProductStandardCost` and `TotalProductCost` fields represent model-based management accounting standards, not dynamic supplier purchase invoices. | Gross profit must always be labeled: *"Gross profit based on standard cost (model value, not observed supplier invoice cost)"*. |

---

## 5. Core Key Performance Indicators (KPIs) & Mathematical Formulas

```
+-------------------------------------------------------------------------------------------------------+
|                                  CORE FINANCIAL & OPERATIONAL KPIs                                    |
+-------------------------------------------------------------------------------------------------------+
| KPI Name                  | Mathematical Formula                       | Analytical Rule              |
+---------------------------+--------------------------------------------+------------------------------+
| Gross Sales Amount        | OrderQuantity * UnitPrice                  | ExtendedAmount pre-discount  |
| Discount Amount           | ExtendedAmount * UnitPriceDiscountPct      | Explicit discount deduction  |
| Net Sales Revenue         | ExtendedAmount - DiscountAmount            | Core top-line revenue        |
| Total Product Cost        | OrderQuantity * ProductStandardCost        | Standard-cost basis only     |
| Gross Profit              | Net Sales Revenue - Total Product Cost     | Standard-cost gross profit   |
| Gross Margin %            | Gross Profit / Net Sales Revenue           | Profitability ratio          |
| Units Sold                | SUM(OrderQuantity)                         | Physical volume sold         |
| Distinct Orders           | COUNT(DISTINCT SalesOrderNumber)           | True document header count   |
| Average Order Value (AOV) | Net Sales Revenue / Distinct Orders        | Order-level, never line avg  |
| MoM Revenue Growth %      | (Revenue_current - Revenue_prev) / Rev_prev| Time intelligence metric     |
| Revenue Share %           | Revenue_group / SUM(Revenue_all)           | Contribution percentage      |
| Stock-to-Reorder Ratio    | UnitsBalance / ReorderPoint                | Replenishment priority index |
| Quota Attainment %        | Reseller Revenue / SalesAmountQuota        | Sales performance index      |
+-------------------------------------------------------------------------------------------------------+
```

---

## 6. Implementation Guardrails & Technical Standards

1. **MySQL 8.x Compatibility:**
   - All SQL scripts must run cleanly on standard MySQL 8.x Community Server using UTF-8 (`utf8mb4`).
   - Window functions (`ROW_NUMBER()`, `RANK()`, `LAG()`, `SUM() OVER ()`) and Common Table Expressions (CTEs) are standard.
2. **Grain Protection:**
   - Sales facts (`FactInternetSales`, `FactResellerSales`) must never be joined directly to each other or to `FactProductInventory` at the transaction line level.
   - Distinct order counts must always use `COUNT(DISTINCT SalesOrderNumber)`.
3. **Traceability Layer (Staging):**
   - Source data imported into `stg_*` tables as untransformed text (`VARCHAR`) before typing and cleaning into production dimension and fact tables.
4. **Slowly Changing Dimension Strategy:**
   - Line transactions link to the specific `ProductKey` in effect at order date.
   - Aggregations and product performance rollups group by `ProductAlternateKey` or `EnglishProductName` to prevent multi-version fragmentation.
