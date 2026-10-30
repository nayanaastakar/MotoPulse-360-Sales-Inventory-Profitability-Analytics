# MotoPulse 360: Comprehensive Data Dictionary

**Project:** MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform  
**Underlying Data Source:** Microsoft AdventureWorksDW (Official Sample Data Warehouse)  
**Dataset Disclosure:** Fictional synthetic bicycle manufacturing, retail, and commercial wholesale data.  
**Scope:** All 15 available tables (10 Core + 5 Extended Dimensions/Facts)  
**Target RDBMS:** MySQL 8.x Community Server  
**Date:** 2026-10-20  

---

## 1. Dimensional Tables

### 1.1. `dim_date` (`DimDate.csv`)
- **Row Count:** 3,652 rows (2005-01-01 to 2014-12-31, 10 full calendar years)
- **Natural Grain:** Exactly one calendar day
- **Primary Key:** `DateKey` (integer YYYYMMDD)

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `DateKey` | `int` | `INT` | NO | PK | Surrogate primary key formatted as YYYYMMDD (e.g. 20101229). |
| `FullDateAlternateKey` | `date` | `DATE` | NO | Natural Key | Actual Gregorian calendar date (YYYY-MM-DD). Used for time intelligence. |
| `DayNumberOfWeek` | `tinyint` | `TINYINT` | NO | Attribute | Day number of week (1 = Sunday, 7 = Saturday). |
| `EnglishDayNameOfWeek` | `nvarchar(10)` | `VARCHAR(10)` | NO | Attribute | English day name (e.g., 'Monday', 'Tuesday'). |
| `SpanishDayNameOfWeek` | `nvarchar(10)` | `VARCHAR(10)` | NO | Attribute | Spanish day name (e.g., 'Lunes', 'Martes'). |
| `FrenchDayNameOfWeek` | `nvarchar(10)` | `VARCHAR(10)` | NO | Attribute | French day name (e.g., 'Lundi', 'Mardi'). |
| `DayNumberOfMonth` | `tinyint` | `TINYINT` | NO | Attribute | Calendar day of month (1 to 31). |
| `DayNumberOfYear` | `smallint` | `SMALLINT` | NO | Attribute | Day of year (1 to 366). |
| `WeekNumberOfYear` | `tinyint` | `TINYINT` | NO | Attribute | ISO calendar week number (1 to 53). |
| `EnglishMonthName` | `nvarchar(10)` | `VARCHAR(10)` | NO | Attribute | English month name (e.g., 'January'). |
| `SpanishMonthName` | `nvarchar(10)` | `VARCHAR(10)` | NO | Attribute | Spanish month name (e.g., 'Enero'). |
| `FrenchMonthName` | `nvarchar(10)` | `VARCHAR(10)` | NO | Attribute | French month name (e.g., 'Janvier'). |
| `MonthNumberOfYear` | `tinyint` | `TINYINT` | NO | Attribute | Month number (1 to 12). Used for chronological sorting. |
| `CalendarQuarter` | `tinyint` | `TINYINT` | NO | Attribute | Calendar quarter (1 to 4). |
| `CalendarYear` | `smallint` | `SMALLINT` | NO | Attribute | Gregorian calendar year (2005 to 2014). |
| `CalendarSemester` | `tinyint` | `TINYINT` | NO | Attribute | Half-year period (1 = Jan-Jun, 2 = Jul-Dec). |
| `FiscalQuarter` | `tinyint` | `TINYINT` | NO | Attribute | Company fiscal quarter (offset by 6 months). |
| `FiscalYear` | `smallint` | `SMALLINT` | NO | Attribute | Company fiscal year. |
| `FiscalSemester` | `tinyint` | `TINYINT` | NO | Attribute | Company fiscal semester. |

---

### 1.2. `dim_product_category` (`DimProductCategory.csv`)
- **Row Count:** 4 rows
- **Natural Grain:** Top-level product category
- **Primary Key:** `ProductCategoryKey`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `ProductCategoryKey` | `int` | `INT` | NO | PK | Surrogate primary key (1=Bikes, 2=Components, 3=Clothing, 4=Accessories). |
| `ProductCategoryAlternateKey` | `int` | `INT` | NO | Natural Key | Source operational system category ID. |
| `EnglishProductCategoryName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Primary category reporting label in English. |
| `SpanishProductCategoryName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Spanish category translation. |
| `FrenchProductCategoryName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | French category translation. |

---

### 1.3. `dim_product_subcategory` (`DimProductSubcategory.csv`)
- **Row Count:** 37 rows
- **Natural Grain:** Granular product subcategory (e.g., Mountain Bikes, Road Frames, Helmets)
- **Primary Key:** `ProductSubcategoryKey`
- **Foreign Key:** `ProductCategoryKey` -> `dim_product_category(ProductCategoryKey)`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `ProductSubcategoryKey` | `int` | `INT` | NO | PK | Surrogate primary key for subcategory. |
| `ProductSubcategoryAlternateKey` | `int` | `INT` | NO | Natural Key | Operational subcategory business ID. |
| `EnglishProductSubcategoryName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Primary subcategory reporting label in English. |
| `SpanishProductSubcategoryName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Spanish subcategory translation. |
| `FrenchProductSubcategoryName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | French subcategory translation. |
| `ProductCategoryKey` | `int` | `INT` | NO | FK | References parent `dim_product_category`. 0 orphans. |

---

### 1.4. `dim_product` (`DimProduct.csv`)
- **Row Count:** 606 rows (504 unique products; 77 products have SCD Type 2 historical records)
- **Natural Grain:** Product version (point-in-time state of an inventory item)
- **Primary Key:** `ProductKey` (Surrogate version key)
- **Natural Business Key:** `ProductAlternateKey` (e.g., 'BK-M68B-42')

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `ProductKey` | `int` | `INT` | NO | PK | Surrogate key identifying a specific historical product version. |
| `ProductAlternateKey` | `nvarchar(25)` | `VARCHAR(25)` | NO | Natural Key | SKU / Part number. Shared across multiple historical versions. |
| `ProductSubcategoryKey` | `int` | `INT` | YES | FK | Foreign key to `dim_product_subcategory`. NULL for raw materials/unassigned items. |
| `WeightUnitMeasureCode` | `nchar(3)` | `CHAR(3)` | YES | Attribute | Unit of weight measurement (e.g., 'LB', 'G'). |
| `SizeUnitMeasureCode` | `nchar(3)` | `CHAR(3)` | YES | Attribute | Unit of size measurement (e.g., 'CM'). |
| `EnglishProductName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Canonical product name in English. |
| `SpanishProductName` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | Spanish product name. |
| `FrenchProductName` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | French product name. |
| `StandardCost` | `money` | `DECIMAL(19,4)` | YES | Metric/Cost | Standard cost model value. Point-in-time cost for inventory & gross profit. |
| `FinishedGoodsFlag` | `bit` | `TINYINT(1)` | NO | Flag | 1 = Saleable finished good; 0 = Raw material / component. |
| `Color` | `nvarchar(15)` | `VARCHAR(15)` | YES | Attribute | Product color (e.g., 'Black', 'Silver', 'Red'). |
| `SafetyStockLevel` | `smallint` | `SMALLINT` | NO | Threshold | Minimum inventory threshold before stockout risk occurs. |
| `ReorderPoint` | `smallint` | `SMALLINT` | NO | Threshold | Inventory level that triggers reorder replenishment. |
| `ListPrice` | `money` | `DECIMAL(19,4)` | YES | Metric/Price | Suggested retail price for this product version. |
| `Size` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | Frame size or apparel size (e.g., '42', 'L'). |
| `SizeRange` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | Size grouping range. |
| `Weight` | `float` | `DECIMAL(10,2)` | YES | Attribute | Item weight in specified unit. |
| `DaysToManufacture` | `int` | `INT` | NO | Attribute | Required production lead time in days. |
| `ProductLine` | `nchar(2)` | `CHAR(2)` | YES | Attribute | Product line code ('M'=Mountain, 'R'=Road, 'T'=Touring, 'S'=Standard). |
| `DealerPrice` | `money` | `DECIMAL(19,4)` | YES | Metric/Price | Wholesale price offered to commercial resellers. |
| `Class` | `nchar(2)` | `CHAR(2)` | YES | Attribute | Quality class ('H'=High, 'M'=Medium, 'L'=Low). |
| `Style` | `nchar(2)` | `CHAR(2)` | YES | Attribute | Style code ('M'=Men, 'W'=Women, 'U'=Universal). |
| `ModelName` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | Marketing model family name (e.g. 'Mountain-100'). |
| `LargePhoto` | `varbinary(max)` | `TEXT` | YES | Metadata | Hex-encoded product image thumbnail. Excluded from analytical views. |
| `EnglishDescription` | `nvarchar(400)` | `VARCHAR(400)` | YES | Attribute | Product catalog marketing description. |
| `StartDate` | `datetime` | `DATETIME` | NO | SCD Range | Effective start date of this product version. |
| `EndDate` | `datetime` | `DATETIME` | YES | SCD Range | Effective end date. NULL indicates the currently active version. |
| `Status` | `nvarchar(7)` | `VARCHAR(7)` | YES | SCD Flag | 'Current' for active version; NULL for retired historical versions. |

---

### 1.5. `dim_customer` (`DimCustomer.csv`)
- **Row Count:** 18,484 rows (100% 1:1, non-SCD)
- **Natural Grain:** Exactly one retail consumer
- **Primary Key:** `CustomerKey`
- **Foreign Key:** `GeographyKey` -> `dim_geography(GeographyKey)`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `CustomerKey` | `int` | `INT` | NO | PK | Surrogate primary key for retail consumers. |
| `GeographyKey` | `int` | `INT` | NO | FK | References customer residential location in `dim_geography`. |
| `CustomerAlternateKey` | `nvarchar(15)` | `VARCHAR(15)` | NO | Natural Key | Business customer account number (e.g., 'AW00011000'). |
| `Title` | `nvarchar(8)` | `VARCHAR(8)` | YES | Attribute | Customer title (e.g., 'Mr.', 'Ms.'). |
| `FirstName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Customer first name. |
| `MiddleName` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | Customer middle name or initial. |
| `LastName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Customer surname. |
| `NameStyle` | `bit` | `TINYINT(1)` | NO | Flag | 0 = Western order (First Last), 1 = Eastern order. |
| `BirthDate` | `date` | `DATE` | NO | Demographic | Date of birth (1916-02-10 to 1986-06-25). Used for age grouping. |
| `MaritalStatus` | `nchar(1)` | `CHAR(1)` | NO | Demographic | 'M' = Married, 'S' = Single. |
| `Suffix` | `nvarchar(10)` | `VARCHAR(10)` | YES | Attribute | Name suffix (e.g., 'Jr.', 'Sr.'). |
| `Gender` | `nvarchar(1)` | `CHAR(1)` | NO | Demographic | 'M' = Male, 'F' = Female. |
| `EmailAddress` | `nvarchar(50)` | `VARCHAR(50)` | YES | Contact | Customer primary email address. |
| `YearlyIncome` | `money` | `DECIMAL(19,4)` | YES | Demographic | Customer stated annual household income. |
| `TotalChildren` | `tinyint` | `TINYINT` | NO | Demographic | Total number of children. |
| `NumberChildrenAtHome` | `tinyint` | `TINYINT` | NO | Demographic | Number of children residing at home. |
| `EnglishEducation` | `nvarchar(40)` | `VARCHAR(40)` | NO | Demographic | Educational level (e.g., 'Bachelors', 'Graduate Degree'). |
| `EnglishOccupation` | `nvarchar(100)` | `VARCHAR(100)` | NO | Demographic | Occupation category (e.g., 'Professional', 'Management'). |
| `HouseOwnerFlag` | `nchar(1)` | `CHAR(1)` | NO | Demographic | '1' = Homeowner, '0' = Renter. |
| `NumberCarsOwned` | `tinyint` | `TINYINT` | NO | Demographic | Count of personal vehicles owned. |
| `AddressLine1` | `nvarchar(120)` | `VARCHAR(120)` | NO | Address | Primary street address. |
| `AddressLine2` | `nvarchar(120)` | `VARCHAR(120)` | YES | Address | Secondary address unit/suite. |
| `Phone` | `nvarchar(20)` | `VARCHAR(20)` | YES | Contact | Contact telephone number. |
| `DateFirstPurchase` | `date` | `DATE` | NO | Cohort Date | Date of initial purchase (2010-12-29 to 2014-01-28). Used for cohort retention. |
| `CommuteDistance` | `nvarchar(15)` | `VARCHAR(15)` | YES | Demographic | Distance bracket to workplace (e.g., '0-1 Miles', '10+ Miles'). |

---

### 1.6. `dim_reseller` (`DimReseller.csv`)
- **Row Count:** 701 rows
- **Natural Grain:** Exactly one commercial B2B account / reseller business
- **Primary Key:** `ResellerKey`
- **Foreign Key:** `GeographyKey` -> `dim_geography(GeographyKey)`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `ResellerKey` | `int` | `INT` | NO | PK | Surrogate primary key for commercial resellers. |
| `GeographyKey` | `int` | `INT` | NO | FK | References business headquarters location in `dim_geography`. |
| `ResellerAlternateKey` | `nvarchar(15)` | `VARCHAR(15)` | NO | Natural Key | Business partner account number (e.g., 'AW00000001'). |
| `Phone` | `nvarchar(25)` | `VARCHAR(25)` | YES | Contact | Business main phone line. |
| `BusinessType` | `varchar(20)` | `VARCHAR(25)` | NO | Segmentation | Customer business classification: 'Value Added Reseller', 'Specialty Bike Shop', or 'Warehouse'. |
| `ResellerName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Legal trade name of the reseller account. |
| `NumberEmployees` | `int` | `INT` | YES | Demographic | Total workforce count. |
| `OrderFrequency` | `char(1)` | `CHAR(1)` | YES | Behavioral | Order pattern code ('A'=Annual, 'Q'=Quarterly, 'S'=Seasonal). |
| `OrderMonth` | `tinyint` | `TINYINT` | YES | Behavioral | Primary purchasing calendar month. |
| `FirstOrderYear` | `int` | `INT` | YES | Cohort Year | Year of first recorded purchase order. |
| `LastOrderYear` | `int` | `INT` | YES | Recency | Year of most recent purchase order. |
| `ProductLine` | `nvarchar(50)` | `VARCHAR(50)` | YES | Attribute | Reseller focus category (e.g., 'Mountain', 'Road'). |
| `AddressLine1` | `nvarchar(60)` | `VARCHAR(60)` | YES | Address | Business primary street address. |
| `AddressLine2` | `nvarchar(60)` | `VARCHAR(60)` | YES | Address | Business suite / building address. |
| `AnnualSales` | `money` | `DECIMAL(19,4)` | YES | Financial | Reseller's self-reported annual business revenue. |
| `BankName` | `nvarchar(50)` | `VARCHAR(50)` | YES | Commercial | Primary commercial banking partner. |
| `AnnualRevenue` | `money` | `DECIMAL(19,4)` | YES | Financial | Annual turnover estimate. |
| `YearOpened` | `int` | `INT` | YES | Attribute | Year the reseller entity was founded. |

---

### 1.7. `dim_sales_territory` (`DimSalesTerritory.csv`)
- **Row Count:** 11 rows (10 operational regions + 1 NA / Corporate territory)
- **Natural Grain:** Regional sales territory
- **Primary Key:** `SalesTerritoryKey`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `SalesTerritoryKey` | `int` | `INT` | NO | PK | Surrogate primary key for sales territories. |
| `SalesTerritoryAlternateKey` | `int` | `INT` | NO | Natural Key | Operational territory ID. |
| `SalesTerritoryRegion` | `nvarchar(50)` | `VARCHAR(50)` | NO | Hierarchy L1 | Specific regional territory (e.g., 'Northwest', 'United Kingdom', 'Australia'). |
| `SalesTerritoryCountry` | `nvarchar(50)` | `VARCHAR(50)` | NO | Hierarchy L2 | Sovereign country name (e.g., 'United States', 'Canada', 'France'). |
| `SalesTerritoryGroup` | `nvarchar(50)` | `VARCHAR(50)` | NO | Hierarchy L3 | Macro continental theater ('North America', 'Europe', 'Pacific'). |
| `SalesTerritoryImage` | `varbinary(max)` | `TEXT` | YES | Metadata | Hex-encoded boundary image. Excluded from SQL analytical views. |

---

### 1.8. `dim_geography` (`DimGeography.csv`)
- **Row Count:** 655 rows
- **Natural Grain:** Postal / Municipal geography zone
- **Primary Key:** `GeographyKey`
- **Foreign Key:** `SalesTerritoryKey` -> `dim_sales_territory(SalesTerritoryKey)`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `GeographyKey` | `int` | `INT` | NO | PK | Surrogate primary key for postal geography records. |
| `City` | `nvarchar(30)` | `VARCHAR(30)` | NO | Attribute | City or municipality name. |
| `StateProvinceCode` | `nvarchar(3)` | `VARCHAR(5)` | NO | Attribute | State/Province abbreviation code (e.g., 'WA', 'CA', 'NSW'). |
| `StateProvinceName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Full state or province name. |
| `CountryRegionCode` | `nvarchar(3)` | `VARCHAR(3)` | NO | Attribute | Two/three letter ISO country code (e.g., 'US', 'CA', 'AU'). |
| `EnglishCountryRegionName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Full country name in English. |
| `PostalCode` | `nvarchar(15)` | `VARCHAR(15)` | NO | Attribute | Postal or ZIP code. |
| `SalesTerritoryKey` | `int` | `INT` | NO | FK | References parent territory in `dim_sales_territory`. 0 orphans. |
| `IpAddressLocator` | `nvarchar(15)` | `VARCHAR(15)` | YES | Attribute | Simulated network gateway IP range. |

---

### 1.9. `dim_promotion` (`DimPromotion.csv`)
- **Row Count:** 16 rows
- **Natural Grain:** Promotional campaign / discount policy
- **Primary Key:** `PromotionKey`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `PromotionKey` | `int` | `INT` | NO | PK | Surrogate primary key (1 = 'No Discount'). |
| `PromotionAlternateKey` | `int` | `INT` | NO | Natural Key | Operational promotion ID. |
| `EnglishPromotionName` | `nvarchar(255)` | `VARCHAR(255)` | NO | Attribute | Name of the promotion (e.g., 'Volume Discount 11 to 14'). |
| `DiscountPct` | `float` | `DECIMAL(5,4)` | NO | Rate | Standard discount percentage (e.g., 0.02 = 2.0%, 0.05 = 5.0%). |
| `EnglishPromotionType` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Type of promotion ('No Discount', 'Volume Discount', 'Discontinued'). |
| `EnglishPromotionCategory` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Target customer channel ('No Discount', 'Reseller', 'Customer'). |
| `StartDate` | `datetime` | `DATETIME` | NO | Date Range | Campaign eligibility start date. |
| `EndDate` | `datetime` | `DATETIME` | NO | Date Range | Campaign eligibility expiration date. |
| `MinQty` | `int` | `INT` | NO | Rule | Minimum purchase quantity threshold required to trigger discount. |
| `MaxQty` | `int` | `INT` | YES | Rule | Maximum qualifying quantity threshold. |

---

### 1.10. `dim_currency` (`DimCurrency.csv`)
- **Row Count:** 105 rows
- **Natural Grain:** Currency code and denomination
- **Primary Key:** `CurrencyKey`

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `CurrencyKey` | `int` | `INT` | NO | PK | Surrogate primary key for ISO currencies. |
| `CurrencyAlternateKey` | `nchar(3)` | `CHAR(3)` | NO | Natural Key | Three-character ISO 4217 currency code (e.g., 'USD', 'EUR', 'GBP', 'AUD'). |
| `CurrencyName` | `nvarchar(50)` | `VARCHAR(50)` | NO | Attribute | Full currency denomination name (e.g., 'US Dollar', 'Euro'). |

---

## 2. Fact Tables

### 2.1. `FactInternetSales` (`FactInternetSales.csv`)
- **Row Count:** 60,398 rows
- **Natural Grain:** Exactly one sales order line `(SalesOrderNumber, SalesOrderLineNumber)`
- **Composite Primary Key:** `(SalesOrderNumber, SalesOrderLineNumber)`
- **Date Coverage:** 2010-12-29 to 2014-01-28

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `SalesOrderNumber` | `nvarchar(20)` | `VARCHAR(20)` | NO | PK | Sales order document header number (e.g., 'SO43697'). |
| `SalesOrderLineNumber` | `tinyint` | `TINYINT` | NO | PK | Line item position index within the order (e.g., 1, 2, 3). |
| `ProductKey` | `int` | `INT` | NO | FK | References purchased product version in `dim_product`. 0 orphans. |
| `OrderDateKey` | `int` | `INT` | NO | FK | References order creation date in `dim_date`. |
| `DueDateKey` | `int` | `INT` | NO | FK | References invoice due date in `dim_date`. |
| `ShipDateKey` | `int` | `INT` | NO | FK | References fulfillment ship date in `dim_date`. |
| `CustomerKey` | `int` | `INT` | NO | FK | References retail consumer in `dim_customer`. 0 orphans. |
| `PromotionKey` | `int` | `INT` | NO | FK | References applied promotion in `dim_promotion` (1 = No Discount). |
| `CurrencyKey` | `int` | `INT` | NO | FK | References transaction currency in `dim_currency`. |
| `SalesTerritoryKey` | `int` | `INT` | NO | FK | References order fulfillment territory in `dim_sales_territory`. |
| `RevisionNumber` | `tinyint` | `TINYINT` | NO | Metadata | Order revision sequence. |
| `OrderQuantity` | `smallint` | `SMALLINT` | NO | Metric/Qty | Number of units purchased on this line. |
| `UnitPrice` | `money` | `DECIMAL(19,4)` | NO | Metric/Price | Actual unit selling price charged to customer. |
| `ExtendedAmount` | `money` | `DECIMAL(19,4)` | NO | Metric/Gross | Gross line amount before discounts = `OrderQuantity * UnitPrice`. |
| `UnitPriceDiscountPct` | `float` | `DECIMAL(5,4)` | NO | Rate | Line discount percentage (0.00 in Internet sales). |
| `DiscountAmount` | `float` | `DECIMAL(19,4)` | NO | Metric/Disc | Total discount value deducted = `ExtendedAmount * UnitPriceDiscountPct` (0.00). |
| `ProductStandardCost` | `money` | `DECIMAL(19,4)` | NO | Metric/Cost | Standard cost per unit from `dim_product`. Model value, not observed cost. |
| `TotalProductCost` | `money` | `DECIMAL(19,4)` | NO | Metric/Cost | Total manufacturing/standard cost = `OrderQuantity * ProductStandardCost`. |
| `SalesAmount` | `money` | `DECIMAL(19,4)` | NO | Metric/Net | **Net Sales Revenue** = `ExtendedAmount - DiscountAmount`. Core revenue metric. |
| `TaxAmt` | `money` | `DECIMAL(19,4)` | NO | Metric/Tax | Value-added / sales tax allocated to this line (exactly 8.0% of SalesAmount). |
| `Freight` | `money` | `DECIMAL(19,4)` | NO | Metric/Freight | Shipping and freight fee allocated to this line (exactly 2.5% of SalesAmount). |
| `CarrierTrackingNumber` | `nvarchar(25)` | `VARCHAR(25)` | YES | Logistics | Package tracking ID from carrier. |
| `CustomerPONumber` | `nvarchar(25)` | `VARCHAR(25)` | YES | Commercial | Customer purchase order reference. |
| `OrderDate` | `datetime` | `DATETIME` | NO | Timestamp | Full order timestamp. |
| `DueDate` | `datetime` | `DATETIME` | NO | Timestamp | Full due date timestamp. |
| `ShipDate` | `datetime` | `DATETIME` | NO | Timestamp | Full shipping dispatch timestamp. |

---

### 2.2. `FactResellerSales` (`FactResellerSales.csv`)
- **Row Count:** 60,855 rows
- **Natural Grain:** Exactly one sales order line `(SalesOrderNumber, SalesOrderLineNumber)`
- **Composite Primary Key:** `(SalesOrderNumber, SalesOrderLineNumber)`
- **Date Coverage:** 2010-12-29 to 2013-11-29

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `SalesOrderNumber` | `nvarchar(20)` | `VARCHAR(20)` | NO | PK | Wholesale sales order document number (e.g., 'SO43659'). |
| `SalesOrderLineNumber` | `tinyint` | `TINYINT` | NO | PK | Line item sequence position index (e.g., 1, 2, ... 12). |
| `ProductKey` | `int` | `INT` | NO | FK | References purchased product version in `dim_product`. 0 orphans. |
| `OrderDateKey` | `int` | `INT` | NO | FK | References order creation date in `dim_date`. |
| `DueDateKey` | `int` | `INT` | NO | FK | References invoice payment due date in `dim_date`. |
| `ShipDateKey` | `int` | `INT` | NO | FK | References logistics shipping date in `dim_date`. |
| `ResellerKey` | `int` | `INT` | NO | FK | References commercial reseller business in `dim_reseller`. 0 orphans. |
| `EmployeeKey` | `int` | `INT` | NO | FK | References internal sales representative credited with the deal. |
| `PromotionKey` | `int` | `INT` | NO | FK | References applied promotion in `dim_promotion` (volume discount). |
| `CurrencyKey` | `int` | `INT` | NO | FK | References contract currency in `dim_currency`. |
| `SalesTerritoryKey` | `int` | `INT` | NO | FK | References territory in `dim_sales_territory`. |
| `RevisionNumber` | `tinyint` | `TINYINT` | NO | Metadata | Contract revision number. |
| `OrderQuantity` | `smallint` | `SMALLINT` | NO | Metric/Qty | Wholesale purchase volume in units. |
| `UnitPrice` | `money` | `DECIMAL(19,4)` | NO | Metric/Price | Contract unit wholesale price charged to reseller. |
| `ExtendedAmount` | `money` | `DECIMAL(19,4)` | NO | Metric/Gross | Gross wholesale amount before discount = `OrderQuantity * UnitPrice`. |
| `UnitPriceDiscountPct` | `float` | `DECIMAL(5,4)` | NO | Rate | Contract volume discount percentage (up to 40% on 3,282 rows). |
| `DiscountAmount` | `float` | `DECIMAL(19,4)` | NO | Metric/Disc | Total discount value deducted = `ExtendedAmount * UnitPriceDiscountPct`. |
| `ProductStandardCost` | `money` | `DECIMAL(19,4)` | NO | Metric/Cost | Standard cost per unit from `dim_product`. Model value, not observed cost. |
| `TotalProductCost` | `money` | `DECIMAL(19,4)` | NO | Metric/Cost | Total standard cost = `OrderQuantity * ProductStandardCost`. |
| `SalesAmount` | `money` | `DECIMAL(19,4)` | NO | Metric/Net | **Net Sales Revenue** = `ExtendedAmount - DiscountAmount`. Core revenue metric. |
| `TaxAmt` | `money` | `DECIMAL(19,4)` | NO | Metric/Tax | Commercial tax allocated to this line (8.0% of SalesAmount). |
| `Freight` | `money` | `DECIMAL(19,4)` | NO | Metric/Freight | Logistics shipping fee allocated to this line (2.5% of SalesAmount). |
| `CarrierTrackingNumber` | `nvarchar(25)` | `VARCHAR(25)` | YES | Logistics | Freight tracking number. |
| `CustomerPONumber` | `nvarchar(25)` | `VARCHAR(25)` | YES | Commercial | Reseller internal purchase order document ID. |
| `OrderDate` | `datetime` | `DATETIME` | NO | Timestamp | Full wholesale order placement timestamp. |
| `DueDate` | `datetime` | `DATETIME` | NO | Timestamp | Full payment terms due timestamp. |
| `ShipDate` | `datetime` | `DATETIME` | NO | Timestamp | Full shipping dispatch timestamp. |

---

### 2.3. `FactProductInventory` (`FactProductInventory.csv`)
- **Row Count:** 776,286 rows (606 products × 1,281 days)
- **Natural Grain:** Exactly one product on one calendar date `(ProductKey, DateKey)`
- **Composite Primary Key:** `(ProductKey, DateKey)`
- **Date Coverage:** 2010-12-28 to 2014-06-30

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `ProductKey` | `int` | `INT` | NO | PK, FK | References product version in `dim_product`. 0 orphans. |
| `DateKey` | `int` | `INT` | NO | PK, FK | References snapshot date in `dim_date`. 0 orphans. |
| `MovementDate` | `date` | `DATE` | NO | Natural Key | Calendar date of inventory ledger snapshot. |
| `UnitCost` | `money` | `DECIMAL(19,4)` | NO | Metric/Cost | Carrying unit cost of inventory on that date. |
| `UnitsIn` | `int` | `INT` | NO | Metric/Movement| Quantity of units received from manufacturing/supplier on this date. |
| `UnitsOut` | `int` | `INT` | NO | Metric/Movement| Quantity of units dispatched for customer orders on this date. |
| `UnitsBalance` | `int` | `INT` | NO | Metric/Stock | Ending inventory balance = `UnitsBalance_prev + UnitsIn - UnitsOut`. Values range from -494 to +875. |

---

### 2.4. `FactCurrencyRate` (`FactCurrencyRate.csv`)
- **Row Count:** 14,264 rows
- **Natural Grain:** Exactly one foreign currency on one calendar date `(CurrencyKey, DateKey)`
- **Composite Primary Key:** `(CurrencyKey, DateKey)`
- **Date Coverage:** 2010-12-29 to 2014-02-28

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `CurrencyKey` | `int` | `INT` | NO | PK, FK | References target foreign currency in `dim_currency`. 0 orphans. |
| `DateKey` | `int` | `INT` | NO | PK, FK | References calendar date in `dim_date`. 0 orphans. |
| `AverageRate` | `float` | `DECIMAL(12,6)` | NO | Metric/Rate | Average exchange rate against USD during the trading day. |
| `EndOfDayRate` | `float` | `DECIMAL(12,6)` | NO | Metric/Rate | Closing exchange rate against USD at end of day. |
| `Date` | `datetime` | `DATETIME` | NO | Timestamp | Exchange rate quote timestamp. |

---

### 2.5. `FactSalesQuota` (`FactSalesQuota.csv`)
- **Row Count:** 163 rows
- **Natural Grain:** Exactly one sales representative per calendar quarter `(EmployeeKey, DateKey)`
- **Primary Key:** `SalesQuotaKey` (Surrogate)
- **Date Coverage:** 2010-12-29 to 2013-09-29

| Column Name | Raw Type | Target MySQL Type | Nullable | Key Class | Business Definition & Transformation Rules |
|---|---|---|---|---|---|
| `SalesQuotaKey` | `int` | `INT` | NO | PK | Surrogate primary key for sales quota records. |
| `EmployeeKey` | `int` | `INT` | NO | FK | Operational employee ID for the sales representative. |
| `DateKey` | `int` | `INT` | NO | FK | References start date of quota quarter in `dim_date`. 0 orphans. |
| `CalendarYear` | `smallint` | `SMALLINT` | NO | Time Attribute| Calendar year of quota assignment (2010 to 2013). |
| `CalendarQuarter` | `tinyint` | `TINYINT` | NO | Time Attribute| Calendar quarter (1 to 4). |
| `SalesAmountQuota` | `money` | `DECIMAL(19,4)` | NO | Metric/Target | Target sales revenue assigned to the sales representative. |
| `Date` | `datetime` | `DATETIME` | NO | Timestamp | Quota effective assignment date. |

---

## 3. Staging vs Production Transformation Rules

1. **Staging Schema (`stg_*` tables):**
   - Each staging table mirrors the exact column layout of its raw CSV file with all columns typed as `VARCHAR(255)` or `TEXT`.
   - Populated directly via clean CSV import in Stage 4.
   - Preserves raw input data without destructive in-place transforms for full auditability.
2. **Type Casting and Cleansing Rules:**
   - **Strings:** Truncate trailing whitespace via `TRIM()`. Replace empty strings `''` with `NULL` using `NULLIF(TRIM(col), '')`.
   - **Dates:** DateKeys are stored as integers (e.g. 20101229) and cast to dates using `STR_TO_DATE(DateKey, '%Y%m%d')`. Datetime strings containing fractional milliseconds (e.g. `2010-12-29 00:00:00.000`) are converted via `STR_TO_DATE(SUBSTRING(col, 1, 19), '%Y-%m-%d %H:%i:%s')`.
   - **Financial Decimals:** All monetary figures (`SalesAmount`, `ExtendedAmount`, `UnitPrice`, `TotalProductCost`, `ProductStandardCost`, `TaxAmt`, `Freight`) are strictly mapped to `DECIMAL(19,4)` in MySQL to eliminate binary floating-point rounding errors.
   - **Binary Photos:** Large hex strings in `LargePhoto` and `SalesTerritoryImage` are omitted from high-performance analytical views and stored as `MEDIUMTEXT` in dimension staging tables.
