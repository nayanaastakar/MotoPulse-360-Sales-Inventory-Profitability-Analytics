# Raw File Inspection Findings: AdventureWorksDW Source Data

**Date of Inspection:** 2026-10-20  
**Inspector:** Antigravity (Pair Programming with User)  
**Project:** MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform  
**Branding Decision:** User decided to retain the project name **MotoPulse 360** with explicit disclosure that the underlying synthetic dataset is Microsoft AdventureWorksDW bicycle retail and commercial wholesale data.  
**Table Scope:** User approved expanding from the initial 10 core tables to include additional operational dimensions and facts (`DimPromotion`, `DimCurrency`, `FactCurrencyRate`, `FactSalesQuota`, `DimGeography`).  
**Inspection Script:** `python/00_inspect_raw_files.py`  
**Execution Environment:** Windows, Python 3.11.0, Pandas 2.1.3, NumPy 1.26.2  

---

## 1. Executive Summary & Data Source

The 15 AdventureWorksDW tables were sourced directly from the official Microsoft SQL Server Samples repository:
- **Repository:** [`microsoft/sql-server-samples`](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/adventure-works/data-warehouse-install-script)
- **Path:** `samples/databases/adventure-works/data-warehouse-install-script/`
- **Licence:** MIT License
- **Storage Location:** `data/raw/` (read-only source directory)
- **Schema Reference:** `instawdbdw.sql` (official Microsoft T-SQL installation script)

Every file was inspected using `python/00_inspect_raw_files.py` and validated with dedicated schema and delimiter parsing scripts. Across all **934,082 rows** analyzed across the 15 files, there are **zero malformed lines, zero field count mismatches, and zero encoding corruption errors**.

---

## 2. Validation of Pre-Inspection Risks and Hypotheses

| Risk / Hypothesis | Claude Pre-inspection Assumption | Empirical Finding on Real Files | Status |
|---|---|---|---|
| **Encoding** | UTF-16 with BOM suspected | UTF-8 without BOM across all 15 files | **Refuted** |
| **Delimiter** | `\t`, `\|`, or `+\|` suspected | `\|` (pipe) used consistently across all 15 files | **Confirmed (`\|`)** |
| **Multi-character `+\|`** | Suspected candidate | Not present in any file | **Refuted** |
| **Header Row** | Possible presence or absence | **No header row** in any of the 15 files | **Confirmed Absent** |
| **Header Heuristic** | Risk of misjudging headers with digits | Heuristic passed 100% (surrogate integer keys on col 0 correctly flagged `has_header=False`) | **Confirmed Robust** |
| **Slowly Changing Dimensions (SCD Type 2)** | Products & Customers suspected to have multiple versions | **DimProduct**: Confirmed SCD Type 2 (606 rows, 504 unique products, 77 multi-version products).<br>**DimCustomer**: Refuted SCD (18,484 rows, 18,484 unique CustomerAlternateKey, 1:1). | **Confirmed for Product; Refuted for Customer** |
| **Financial Consistency: Net Sales** | SalesAmount = ExtendedAmount - DiscountAmount? | **100.0% match** on all 60,398 Internet sales and all 60,855 Reseller sales | **Confirmed Exact** |
| **Financial Consistency: Cost** | TotalProductCost = ProductStandardCost * OrderQuantity? | **100.0% match** across all 121,253 sales lines | **Confirmed Exact** |
| **Discounts** | Discounts on both channels? | **Internet**: 0% discounts on all rows.<br>**Reseller**: 3,282 rows have discounts up to 40% (mean non-zero discount: 9.3%). | **Confirmed** |
| **Freight & Tax Allocation** | Lump-sum duplicated per line? | Line-level proportional calculation (Tax = 8.0%, Freight = 2.5% of SalesAmount). | **Clarified (Line-level allocated)** |
| **Line-Grain Uniqueness** | `(SalesOrderNumber, SalesOrderLineNumber)` unique? | **100.0% unique** within both FactInternetSales and FactResellerSales. Order numbers have 0 overlap between channels. | **Confirmed Exact** |
| **Inventory Grain & Semantics** | Product-date grain without warehouse? What does balance mean? | **606 products × 1,281 days = 776,286 rows**. Daily snapshot per product. No warehouse column. Balances range from -494 to +875. Transitions follow `UnitsBalance = UnitsBalance_prev + UnitsIn - UnitsOut`. | **Confirmed Exact** |

---

## 3. Comprehensive Per-File Inspection Profiles

### 3.1. DimDate.csv
- **Path:** `data/raw/DimDate.csv` (353,497 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 3,652 | **Columns:** 19
- **Date Coverage:** 2005-01-01 to 2014-12-31 (exactly 10 consecutive Gregorian calendar years, 3,652 days including leap years 2008 and 2012).
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `DateKey` (int, YYYYMMDD)
  2. `FullDateAlternateKey` (date, YYYY-MM-DD)
  3. `DayNumberOfWeek` (tinyint)
  4. `EnglishDayNameOfWeek` (varchar(10))
  5. `SpanishDayNameOfWeek` (varchar(10))
  6. `FrenchDayNameOfWeek` (varchar(10))
  7. `DayNumberOfMonth` (tinyint)
  8. `DayNumberOfYear` (smallint)
  9. `WeekNumberOfYear` (tinyint)
  10. `EnglishMonthName` (varchar(10))
  11. `SpanishMonthName` (varchar(10))
  12. `FrenchMonthName` (varchar(10))
  13. `MonthNumberOfYear` (tinyint)
  14. `CalendarQuarter` (tinyint)
  15. `CalendarYear` (smallint)
  16. `CalendarSemester` (tinyint)
  17. `FiscalQuarter` (tinyint)
  18. `FiscalYear` (smallint)
  19. `FiscalSemester` (tinyint)
- **Sample Row:** `20050101|2005-01-01|7|Saturday|Sábado|Samedi|1|1|1|January|Enero|Janvier|1|1|2005|1|3|2005|2`

---

### 3.2. DimProduct.csv
- **Path:** `data/raw/DimProduct.csv` (9,303,851 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 606 | **Columns:** 36
- **Unique Products (ProductAlternateKey):** 504
- **Products with SCD Type 2 History:** 77 products have multiple versions (e.g., `FR-M94S-38` has ProductKey 307, 308, 309).
- **Date Coverage:** `StartDate` (2003-07-01 to 2013-07-01), `EndDate` (2007-12-28 to 2008-12-27, NULL for current version).
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ProductKey` (int, PK)
  2. `ProductAlternateKey` (nvarchar(25))
  3. `ProductSubcategoryKey` (int, FK)
  4. `WeightUnitMeasureCode` (nchar(3))
  5. `SizeUnitMeasureCode` (nchar(3))
  6. `EnglishProductName` (nvarchar(50))
  7. `SpanishProductName` (nvarchar(50))
  8. `FrenchProductName` (nvarchar(50))
  9. `StandardCost` (money)
  10. `FinishedGoodsFlag` (bit)
  11. `Color` (nvarchar(15))
  12. `SafetyStockLevel` (smallint)
  13. `ReorderPoint` (smallint)
  14. `ListPrice` (money)
  15. `Size` (nvarchar(50))
  16. `SizeRange` (nvarchar(50))
  17. `Weight` (float)
  18. `DaysToManufacture` (int)
  19. `ProductLine` (nchar(2))
  20. `DealerPrice` (money)
  21. `Class` (nchar(2))
  22. `Style` (nchar(2))
  23. `ModelName` (nvarchar(50))
  24. `LargePhoto` (varbinary(max)) - hex encoded binary image
  25. `EnglishDescription` (nvarchar(400))
  26. `FrenchDescription` (nvarchar(400))
  27. `ChineseDescription` (nvarchar(400))
  28. `ArabicDescription` (nvarchar(400))
  29. `HebrewDescription` (nvarchar(400))
  30. `ThaiDescription` (nvarchar(400))
  31. `GermanDescription` (nvarchar(400))
  32. `JapaneseDescription` (nvarchar(400))
  33. `TurkishDescription` (nvarchar(400))
  34. `StartDate` (datetime)
  35. `EndDate` (datetime)
  36. `Status` (nvarchar(7))

---

### 3.3. DimProductSubcategory.csv
- **Path:** `data/raw/DimProductSubcategory.csv` (1,546 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 37 | **Columns:** 6
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ProductSubcategoryKey` (int, PK)
  2. `ProductSubcategoryAlternateKey` (int)
  3. `EnglishProductSubcategoryName` (nvarchar(50))
  4. `SpanishProductSubcategoryName` (nvarchar(50))
  5. `FrenchProductSubcategoryName` (nvarchar(50))
  6. `ProductCategoryKey` (int, FK)

---

### 3.4. DimProductCategory.csv
- **Path:** `data/raw/DimProductCategory.csv` (130 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 4 | **Columns:** 5
- **Categories:** Bikes (Key 1), Components (Key 2), Clothing (Key 3), Accessories (Key 4)
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ProductCategoryKey` (int, PK)
  2. `ProductCategoryAlternateKey` (int)
  3. `EnglishProductCategoryName` (nvarchar(50))
  4. `SpanishProductCategoryName` (nvarchar(50))
  5. `FrenchProductCategoryName` (nvarchar(50))

---

### 3.5. DimCustomer.csv
- **Path:** `data/raw/DimCustomer.csv` (4,462,011 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 18,484 | **Columns:** 29
- **Unique Customers (CustomerAlternateKey):** 18,484 (100.0% 1:1, non-SCD)
- **Date Coverage:** `BirthDate` (1916-02-10 to 1986-06-25), `DateFirstPurchase` (2010-12-29 to 2014-01-28)
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `CustomerKey` (int, PK)
  2. `GeographyKey` (int, FK)
  3. `CustomerAlternateKey` (nvarchar(15))
  4. `Title` (nvarchar(8))
  5. `FirstName` (nvarchar(50))
  6. `MiddleName` (nvarchar(50))
  7. `LastName` (nvarchar(50))
  8. `NameStyle` (bit)
  9. `BirthDate` (date)
  10. `MaritalStatus` (nchar(1))
  11. `Suffix` (nvarchar(10))
  12. `Gender` (nvarchar(1))
  13. `EmailAddress` (nvarchar(50))
  14. `YearlyIncome` (money)
  15. `TotalChildren` (tinyint)
  16. `NumberChildrenAtHome` (tinyint)
  17. `EnglishEducation` (nvarchar(40))
  18. `SpanishEducation` (nvarchar(40))
  19. `FrenchEducation` (nvarchar(40))
  20. `EnglishOccupation` (nvarchar(100))
  21. `SpanishOccupation` (nvarchar(100))
  22. `FrenchOccupation` (nvarchar(100))
  23. `HouseOwnerFlag` (nchar(1))
  24. `NumberCarsOwned` (tinyint)
  25. `AddressLine1` (nvarchar(120))
  26. `AddressLine2` (nvarchar(120))
  27. `Phone` (nvarchar(20))
  28. `DateFirstPurchase` (date)
  29. `CommuteDistance` (nvarchar(15))

---

### 3.6. DimReseller.csv
- **Path:** `data/raw/DimReseller.csv` (119,137 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 701 | **Columns:** 20
- **Unique Resellers:** 701
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ResellerKey` (int, PK)
  2. `GeographyKey` (int, FK)
  3. `ResellerAlternateKey` (nvarchar(15))
  4. `Phone` (nvarchar(25))
  5. `BusinessType` (varchar(20))
  6. `ResellerName` (nvarchar(50))
  7. `NumberEmployees` (int)
  8. `OrderFrequency` (char(1))
  9. `OrderMonth` (tinyint)
  10. `FirstOrderYear` (int)
  11. `LastOrderYear` (int)
  12. `ProductLine` (nvarchar(50))
  13. `AddressLine1` (nvarchar(60))
  14. `AddressLine2` (nvarchar(60))
  15. `AnnualSales` (money)
  16. `BankName` (nvarchar(50))
  17. `MinPaymentType` (tinyint)
  18. `MinPaymentAmount` (money)
  19. `AnnualRevenue` (money)
  20. `YearOpened` (int)

---

### 3.7. DimSalesTerritory.csv
- **Path:** `data/raw/DimSalesTerritory.csv` (878,402 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 11 | **Columns:** 6 (10 regions + 1 NA)
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `SalesTerritoryKey` (int, PK)
  2. `SalesTerritoryAlternateKey` (int)
  3. `SalesTerritoryRegion` (nvarchar(50))
  4. `SalesTerritoryCountry` (nvarchar(50))
  5. `SalesTerritoryGroup` (nvarchar(50))
  6. `SalesTerritoryImage` (varbinary(max))

---

### 3.8. FactInternetSales.csv
- **Path:** `data/raw/FactInternetSales.csv` (11,726,880 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 60,398 | **Columns:** 26
- **Unique Line Grain:** `(SalesOrderNumber, SalesOrderLineNumber)` is 100% unique across all 60,398 rows.
- **Distinct Orders:** 27,659 orders (~2.18 lines per order).
- **Date Coverage:** `OrderDate` (2010-12-29 to 2014-01-28), `DueDate` (2011-01-10 to 2014-02-09), `ShipDate` (2011-01-05 to 2014-02-04).
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ProductKey` (int, FK)
  2. `OrderDateKey` (int, FK)
  3. `DueDateKey` (int, FK)
  4. `ShipDateKey` (int, FK)
  5. `CustomerKey` (int, FK)
  6. `PromotionKey` (int, FK)
  7. `CurrencyKey` (int, FK)
  8. `SalesTerritoryKey` (int, FK)
  9. `SalesOrderNumber` (nvarchar(20))
  10. `SalesOrderLineNumber` (tinyint)
  11. `RevisionNumber` (tinyint)
  12. `OrderQuantity` (smallint)
  13. `UnitPrice` (money)
  14. `ExtendedAmount` (money)
  15. `UnitPriceDiscountPct` (float)
  16. `DiscountAmount` (float)
  17. `ProductStandardCost` (money)
  18. `TotalProductCost` (money)
  19. `SalesAmount` (money)
  20. `TaxAmt` (money)
  21. `Freight` (money)
  22. `CarrierTrackingNumber` (nvarchar(25))
  23. `CustomerPONumber` (nvarchar(25))
  24. `OrderDate` (datetime)
  25. `DueDate` (datetime)
  26. `ShipDate` (datetime)

---

### 3.9. FactResellerSales.csv
- **Path:** `data/raw/FactResellerSales.csv` (13,953,049 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 60,855 | **Columns:** 27
- **Unique Line Grain:** `(SalesOrderNumber, SalesOrderLineNumber)` is 100% unique across all 60,855 rows.
- **Distinct Orders:** 3,796 orders (~16.03 lines per order).
- **Date Coverage:** `OrderDate` (2010-12-29 to 2013-11-29), `DueDate` (2011-01-10 to 2013-12-11), `ShipDate` (2011-01-05 to 2013-12-06).
- **Key Difference with FactInternetSales:** Contains `EmployeeKey` at column index 5.
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ProductKey` (int, FK)
  2. `OrderDateKey` (int, FK)
  3. `DueDateKey` (int, FK)
  4. `ShipDateKey` (int, FK)
  5. `ResellerKey` (int, FK)
  6. `EmployeeKey` (int, FK)
  7. `PromotionKey` (int, FK)
  8. `CurrencyKey` (int, FK)
  9. `SalesTerritoryKey` (int, FK)
  10. `SalesOrderNumber` (nvarchar(20))
  11. `SalesOrderLineNumber` (tinyint)
  12. `RevisionNumber` (tinyint)
  13. `OrderQuantity` (smallint)
  14. `UnitPrice` (money)
  15. `ExtendedAmount` (money)
  16. `UnitPriceDiscountPct` (float)
  17. `DiscountAmount` (float)
  18. `ProductStandardCost` (money)
  19. `TotalProductCost` (money)
  20. `SalesAmount` (money)
  21. `TaxAmt` (money)
  22. `Freight` (money)
  23. `CarrierTrackingNumber` (nvarchar(25))
  24. `CustomerPONumber` (nvarchar(25))
  25. `OrderDate` (datetime)
  26. `DueDate` (datetime)
  27. `ShipDate` (datetime)

---

### 3.10. FactProductInventory.csv
- **Path:** `data/raw/FactProductInventory.csv` (30,300,532 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 776,286 | **Columns:** 7
- **Exact Grain:** 1 row per product per calendar day (606 products × 1,281 days = 776,286 rows).
- **Date Coverage:** `MovementDate` (2010-12-28 to 2014-06-30).
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `ProductKey` (int, FK)
  2. `DateKey` (int, FK)
  3. `MovementDate` (date)
  4. `UnitCost` (money)
  5. `UnitsIn` (int)
  6. `UnitsOut` (int)
  7. `UnitsBalance` (int)

---

### 3.11. DimPromotion.csv
- **Path:** `data/raw/DimPromotion.csv` (3,997 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 16 | **Columns:** 16
- **Date Coverage:** `StartDate` (2010-11-29 to 2013-10-29), `EndDate` (2011-12-28 to 2014-06-30)
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `PromotionKey` (int, PK)
  2. `PromotionAlternateKey` (int)
  3. `EnglishPromotionName` (nvarchar(255))
  4. `SpanishPromotionName` (nvarchar(255))
  5. `FrenchPromotionName` (nvarchar(255))
  6. `DiscountPct` (float)
  7. `EnglishPromotionType` (nvarchar(50))
  8. `SpanishPromotionType` (nvarchar(50))
  9. `FrenchPromotionType` (nvarchar(50))
  10. `EnglishPromotionCategory` (nvarchar(50))
  11. `SpanishPromotionCategory` (nvarchar(50))
  12. `FrenchPromotionCategory` (nvarchar(50))
  13. `StartDate` (datetime)
  14. `EndDate` (datetime)
  15. `MinQty` (int)
  16. `MaxQty` (int)

---

### 3.12. DimCurrency.csv
- **Path:** `data/raw/DimCurrency.csv` (2,104 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 105 | **Columns:** 3
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `CurrencyKey` (int, PK)
  2. `CurrencyAlternateKey` (nchar(3))
  3. `CurrencyName` (nvarchar(50))

---

### 3.13. FactCurrencyRate.csv
- **Path:** `data/raw/FactCurrencyRate.csv` (1,035,663 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 14,264 | **Columns:** 5
- **Date Coverage:** `Date` (2010-12-29 to 2014-02-28)
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `CurrencyKey` (int, FK)
  2. `DateKey` (int, FK)
  3. `AverageRate` (float)
  4. `EndOfDayRate` (float)
  5. `Date` (datetime)

---

### 3.14. FactSalesQuota.csv
- **Path:** `data/raw/FactSalesQuota.csv` (9,681 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 163 | **Columns:** 7
- **Date Coverage:** `Date` (2010-12-29 to 2013-09-29)
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `SalesQuotaKey` (int, PK)
  2. `EmployeeKey` (int, FK)
  3. `DateKey` (int, FK)
  4. `CalendarYear` (smallint)
  5. `CalendarQuarter` (tinyint)
  6. `SalesAmountQuota` (money)
  7. `Date` (datetime)

---

### 3.15. DimGeography.csv
- **Path:** `data/raw/DimGeography.csv` (56,424 bytes)
- **Encoding:** UTF-8 | **Delimiter:** `|` | **Header Row:** False
- **Rows:** 655 | **Columns:** 11
- **Derived Column Names (from `instawdbdw.sql`):**
  1. `GeographyKey` (int, PK)
  2. `City` (nvarchar(30))
  3. `StateProvinceCode` (nvarchar(3))
  4. `StateProvinceName` (nvarchar(50))
  5. `CountryRegionCode` (nvarchar(3))
  6. `EnglishCountryRegionName` (nvarchar(50))
  7. `SpanishCountryRegionName` (nvarchar(50))
  8. `FrenchCountryRegionName` (nvarchar(50))
  9. `PostalCode` (nvarchar(15))
  10. `SalesTerritoryKey` (int, FK)
  11. `IpAddressLocator` (nvarchar(15))

---

## 4. Key Data Insights for Subsequent Stages

1. **Clean CSV Conversion (Stage 4b):**
   - The conversion script (`python/01_convert_raw_to_clean_csv.py`) will read with `sep='|'`, `encoding='utf-8'`, and assign the derived column names listed above, writing comma-delimited UTF-8 CSVs to `data/processed/clean/`.
   - Large photo binaries in `DimProduct` and `DimSalesTerritory` are long hex strings; they should be parsed as text or omitted from analytics tables if unneeded.
2. **Unified Fact Grain & Stacking (Stage 3 & Stage 4):**
   - In `fact_sales_line`, we stack `FactInternetSales` and `FactResellerSales`.
   - Add `channel` column: `'Internet'` vs `'Reseller'`.
   - For `CustomerKey` and `ResellerKey`, store as nullable columns with the validation constraint: `(CustomerKey IS NOT NULL AND ResellerKey IS NULL) OR (CustomerKey IS NULL AND ResellerKey IS NOT NULL)`.
   - The sales order numbers are already disjoint (`SO43697...` for Internet, `SO43659...` for Reseller), but the natural composite key `(channel, SalesOrderNumber, SalesOrderLineNumber)` guarantees 100% uniqueness.
3. **Product Dimension Modeling (Stage 3):**
   - Because 77 products have SCD Type 2 history (multiple `ProductKey` values for one `ProductAlternateKey`), rollups by product name or alternate key should group by `ProductAlternateKey` / `EnglishProductName`, while fact transactions link directly to the historical `ProductKey` in effect at purchase.
4. **Inventory Modeling (Stage 3 & Stage 5):**
   - Inventory does not have warehouse granularity. Replenishment priority will compare the latest `UnitsBalance` against `DimProduct.SafetyStockLevel` and `DimProduct.ReorderPoint`.
   - Negative balances observed in raw data (down to -494) must be flagged and documented as synthetic data artefacts in `dq_summary`.
