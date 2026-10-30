# Stage 4: Data Quality & Reconciliation Audit Report

**Project:** MotoPulse 360  
**Generated On:** 2026-10-20  
**Audit Source:** All 15 clean CSV files in `data/processed/clean/` (936,237 total rows)  

---

## 1. Executive Summary

All 15 raw AdventureWorksDW tables were converted into clean, comma-delimited, header-containing UTF-8 CSVs in `data/processed/clean/`. Every table achieved a **100.0% row count match** against the raw source files.

A comprehensive suite of 18 automated integrity checks was executed covering primary key uniqueness, foreign key referential integrity, financial consistency formulas, channel disjointness, and operational boundaries.

---

## 2. Financial Totals & Reconciliation Baseline

| Metric | Direct-to-Consumer (Internet) | Commercial Wholesale (Reseller) | Consolidated Portfolio Total |
|---|---|---|---|
| **Total Order Lines** | 60,398 lines | 60,855 lines | **121,253 lines** |
| **Distinct Orders** | 27,659 orders | 3,796 orders | **31,455 orders** |
| **Gross Extended Sales** | \$29,358,677.22 | \$80,978,104.87 | **\$110,336,782.09** |
| **Discount Amount** | \$0.00 (0.00%) | \$527,507.93 (0.65%) | **\$527,507.93** |
| **Net Sales Revenue** | **\$29,358,677.22** | **\$80,450,596.98** | **\$109,809,274.20** |
| **Total Product Cost (Standard)** | \$17,277,793.58 | \$79,980,114.38 | **\$97,257,907.95** |
| **Gross Profit (Standard Cost)** | **\$12,080,883.65** | **\$470,482.60** | **\$12,551,366.25** |
| **Gross Margin % (Standard Cost)** | **41.15%** | **0.58%** | **11.43%** |

*Note: Gross profit is computed on a standard-cost basis (model value, not observed invoice supplier cost).*

---

## 3. Data Quality & Referential Integrity Matrix

| Check Category | Table / Entity | Audit Description | Failing Count | Audit Status | Notes |
|---|---|---|---|---|---|
| PK Uniqueness | DimDate | Duplicate DateKey | 0 | **PASSED** |  |
| PK Uniqueness | DimProduct | Duplicate ProductKey | 0 | **PASSED** |  |
| PK Uniqueness | DimCustomer | Duplicate CustomerKey | 0 | **PASSED** |  |
| PK Uniqueness | DimReseller | Duplicate ResellerKey | 0 | **PASSED** |  |
| Line Grain | FactInternetSales | Duplicate (SalesOrderNumber, LineNumber) | 0 | **PASSED** |  |
| Line Grain | FactResellerSales | Duplicate (SalesOrderNumber, LineNumber) | 0 | **PASSED** |  |
| Snapshot Grain | FactProductInventory | Duplicate (ProductKey, DateKey) | 0 | **PASSED** |  |
| FK Integrity | DimProduct | Orphan ProductSubcategoryKey | 0 | **PASSED** |  |
| FK Integrity | DimProductSubcategory | Orphan ProductCategoryKey | 0 | **PASSED** |  |
| FK Integrity | DimCustomer | Orphan GeographyKey | 0 | **PASSED** |  |
| FK Integrity | DimReseller | Orphan GeographyKey | 0 | **PASSED** |  |
| FK Integrity | FactInternetSales | Orphan CustomerKey | 0 | **PASSED** |  |
| FK Integrity | FactInternetSales | Orphan ProductKey | 0 | **PASSED** |  |
| FK Integrity | FactResellerSales | Orphan ResellerKey | 0 | **PASSED** |  |
| FK Integrity | FactResellerSales | Orphan ProductKey | 0 | **PASSED** |  |
| FK Integrity | FactProductInventory | Orphan ProductKey | 0 | **PASSED** |  |
| FK Integrity | FactProductInventory | Orphan DateKey | 0 | **PASSED** |  |
| Financial | FactInternetSales | SalesAmount != ExtendedAmount - Discount | 0 | **PASSED** |  |
| Financial | FactInternetSales | TotalProductCost != Qty * StandardCost | 0 | **PASSED** |  |
| Financial | FactResellerSales | SalesAmount != ExtendedAmount - Discount | 0 | **PASSED** |  |
| Financial | FactResellerSales | ExtendedAmount != Qty * UnitPrice | 0 | **PASSED** |  |
| Financial | FactResellerSales | DiscountAmount != ExtAmount * DiscountPct | 0 | **PASSED** |  |
| Channel Disjoint | Sales Orders | Order Number Overlap between Channels | 0 | **PASSED** | Zero order overlap between Internet and Reseller |
| Inventory | FactProductInventory | Negative UnitsBalance (Stock Deficit) | 3,319 | **FLAGGED** | Expected synthetic AdventureWorksDW deficit artefacts. Flagged in dq_flag. |

---

## 4. Key Findings & Architectural Confirmations

1. **Clean CSV Conversion Verification:**
   - 936,237 raw rows converted into 936,237 clean rows across 15 files with zero data loss and exact column headers.
2. **Referential Integrity Confirmed:**
   - Zero orphan foreign keys found across all dimensions and facts.
3. **Financial Formulas Confirmed:**
   - `SalesAmount == ExtendedAmount - DiscountAmount` holds for 100.0% of sales transactions across both channels.
   - Reseller wholesale volume discounting totaled \$527,507.93 across 3,282 discounted lines.
4. **Channel Disjointness Confirmed:**
   - Zero order number overlap between Internet (`SO43697...`) and Reseller (`SO43659...`).
5. **Operational Inventory Flags:**
   - 3,319 snapshot records (out of 776,286) have `UnitsBalance < 0` (down to -494). These are preserved and explicitly flagged with `dq_flag = 'NEGATIVE_BALANCE'` in `fact_product_inventory` as synthetic deficit artefacts.
