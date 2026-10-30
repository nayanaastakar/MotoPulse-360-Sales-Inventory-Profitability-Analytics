# MotoPulse 360: Analytical Limitations, Data Assumptions & Boundaries

**Document Version:** 1.0  
**Target Audience:** Interviewers, Data Engineering Teams, Analytics Leadership  
**Guiding Principle:** Complete analytical transparency. A great data analyst knows not only what the data reveals, but also what the data cannot answer.

---

## 1. Dataset Origin & Synthetic Nature

### 1.1 Source Attribution
- **Source Dataset:** Official Microsoft AdventureWorksDW sample database (Data Warehouse install scripts and relational CSV files).
- **Domain:** Global bicycle manufacturing, direct retail e-commerce, and commercial wholesale distribution.
- **Licence:** MIT Licence (Microsoft SQL Server Samples repository).
- **Synthetic Nature Disclosure:** While the platform uses the memorable business branding "MotoPulse 360", the underlying data represents a fictional bicycle business created by Microsoft for benchmarking and architectural training. **It is not real motorcycle industry data.**
- **Portfolio Integrity Rule:** In interviews and documentation, this project is presented as an enterprise-grade analytics demonstration on synthetic corporate data, demonstrating realistic data cleaning, SQL modeling, DAX architecture, and financial reconciliation.

---

## 2. Financial & Accounting Limitations

### 2.1 Standard Cost vs. Actual Cost of Goods Sold (COGS)
- **Standard Cost is a Managerial Model Value:**  
  All profit calculations in this repository (`GrossProfit = SalesAmount - TotalProductCost`) rely on `StandardCost` and `ProductStandardCost` fields provided in the schema. In manufacturing accounting, standard cost is a predetermined estimate reflecting expected raw material costs, direct labor hours, and allocated fixed overhead.
- **Absence of Supplier Invoices:**  
  The dataset does not contain purchase orders to third-party suppliers, raw material price variance (PPV), or actual batch manufacturing receipts. Therefore, profit figures represent **standard gross margin**, not audited GAAP/IFRS accounting net income.
- **Operating Expenses Excluded:**  
  Sales tax (`TaxAmt`) and shipping costs (`Freight`) are tracked on sales orders but are operational pass-through costs. Operating expenses such as sales representative commissions, corporate marketing, software licenses, and executive salaries are not present in the data. Consequently, **EBITDA and Net Income cannot be calculated**.

---

## 3. Operational & Supply Chain Boundaries

### 3.1 Product-Level vs. Warehouse-Level Inventory
- **Single Warehouse Aggregation:**  
  `FactProductInventory` records daily snapshot balances (`UnitsBalance`, `UnitsIn`, `UnitsOut`) by `ProductKey` and `DateKey`. It does not include a warehouse or bin location dimension.
- **Replenishment Semantics:**  
  Inventory analysis reflects enterprise-wide product availability compared against catalog `SafetyStockLevel` and `ReorderPoint`. It cannot measure localized warehouse throughput, intra-facility transfers, or regional picking efficiencies.
- **"Warehouse" Terminology in Reseller Dimension:**  
  In `DimReseller`, the `BusinessType` attribute includes "Warehouse" (e.g. warehouse club retail format). This represents a customer business model, not MotoPulse 360's internal storage facility. Regional supply chain analysis is therefore conducted via `DimSalesTerritory`.

### 3.2 Inventory Balance Anomalies (Negative Stock)
- **Observed Data Quality Issue:**  
  3,319 records (0.43% of `FactProductInventory`) contain negative `UnitsBalance` values (ranging from -1 to -33 units).
- **Engineering Treatment:**  
  These records were preserved and flagged (`dq_negative_stock = 1`) rather than destructively deleted. In physical retail and ERP systems, negative stock balances typically indicate inventory timing lags (e.g., customer checkout scanned before the receiving dock purchase order was processed).

### 3.3 Stockouts and Lost Sales Unanswerable
- Sales transactions only record fulfilled orders. The dataset contains no records of abandoned e-commerce shopping carts, backorders, or customer inquiries for out-of-stock items. As a result, lost sales revenue due to stockouts cannot be directly quantified from sales facts alone.

---

## 4. Customer, Order & Product History Caveats

### 4.1 Absence of Returns and Customer Refunds
- The dataset does not contain a returns fact table or return reason codes. All orders recorded in `FactInternetSales` and `FactResellerSales` are assumed to be completed, non-returned transactions.

### 4.2 Slowly Changing Dimensions (SCD Type 2)
- `DimProduct` contains 606 rows representing historical revisions of 397 unique products (`ProductAlternateKey`). Multiple versions of the same physical product exist with varying `StartDate`, `EndDate`, and `StandardCost`.
- **Analytical Precaution:** To prevent row multiplication, product rollups group by `ProductKey` when evaluating sales facts (preserving the exact historical cost and list price attached to the transaction), or by `ProductAlternateKey` / `EnglishProductName` when evaluating current catalog counts.

### 4.3 Distinct Order-Level Freight & Tax Allocation
- Freight and sales tax are recorded at the order line level. In the source data, these amounts are repeated across lines or pre-allocated.
- **Analytical Precaution:** To prevent artificial inflation of freight and tax, reporting must compute distinct order-level aggregates or isolate them from line-level merchandise revenue. In this platform, **Net Sales is defined strictly as `SalesAmount`** (`ExtendedAmount - DiscountAmount`).

---

## 5. Scope of Answerable vs. Unanswerable Questions

| Business Question Category | Supported & Answerable | Unsupported & Why |
|---|---|---|
| **Revenue & Sales Volume** | Net sales, gross sales, units, distinct orders, AOV by channel, product, territory, month. | Lost sales from website abandonments (no clickstream or cart logs). |
| **Gross Margin Performance** | Gross profit and margin % on standard cost basis by SKU, category, and channel. | Net profit after corporate SG&A, marketing ad spend, or sales rep commissions. |
| **Channel Dynamics** | Comparative AOV, basket size, and margin between Retail e-commerce and Wholesale partners. | Reseller secondary sell-through to end-consumers (data stops at wholesale invoice). |
| **Discounting Impact** | Promotional discount volume, discount rate %, and margin erosion by discount tier. | Annual retrospective partner rebate agreements (not tracked in DW schema). |
| **Inventory Health** | Enterprise stock balances vs. safety stock and reorder thresholds; shortage alerts. | Warehouse aisle picking travel time, regional stock transfers, and bin-level density. |
| **Customer Retention** | B2C repeat order frequency, lifetime spend deciles, customer demographics. | Customer service ticket resolutions, churn propensity, or customer sentiment. |
