-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 04: Data Cleaning, Transformation & Analytical Table Population
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- PRINCIPLES:
-- 1. Strictly non-destructive: zero silent dropping of questionable records.
-- 2. Casts raw text strings into typed MySQL dates, integers, and DECIMAL(19,4).
-- 3. Handles empty strings using NULLIF(TRIM(col), '').
-- 4. Flags synthetic artefacts (e.g. negative inventory balances) in `dq_flag`.
-- 5. Populates `fact_sales_line` with channel indicator and disjoint keys.
-- ==============================================================================

USE motopulse360;

SET foreign_key_checks = 0;

-- ------------------------------------------------------------------------------
-- 1. POPULATE DIMENSIONS
-- ------------------------------------------------------------------------------

-- DimDate
TRUNCATE TABLE dim_date;
INSERT INTO dim_date (
    DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek,
    SpanishDayNameOfWeek, FrenchDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear,
    WeekNumberOfYear, EnglishMonthName, SpanishMonthName, FrenchMonthName,
    MonthNumberOfYear, CalendarQuarter, CalendarYear, CalendarSemester,
    FiscalQuarter, FiscalYear, FiscalSemester
)
SELECT 
    CAST(DateKey AS SIGNED),
    STR_TO_DATE(FullDateAlternateKey, '%Y-%m-%d'),
    CAST(DayNumberOfWeek AS SIGNED),
    TRIM(EnglishDayNameOfWeek),
    TRIM(SpanishDayNameOfWeek),
    TRIM(FrenchDayNameOfWeek),
    CAST(DayNumberOfMonth AS SIGNED),
    CAST(DayNumberOfYear AS SIGNED),
    CAST(WeekNumberOfYear AS SIGNED),
    TRIM(EnglishMonthName),
    TRIM(SpanishMonthName),
    TRIM(FrenchMonthName),
    CAST(MonthNumberOfYear AS SIGNED),
    CAST(CalendarQuarter AS SIGNED),
    CAST(CalendarYear AS SIGNED),
    CAST(CalendarSemester AS SIGNED),
    CAST(FiscalQuarter AS SIGNED),
    CAST(FiscalYear AS SIGNED),
    CAST(FiscalSemester AS SIGNED)
FROM stg_dim_date;

-- DimProductCategory
TRUNCATE TABLE dim_product_category;
INSERT INTO dim_product_category (
    ProductCategoryKey, ProductCategoryAlternateKey, EnglishProductCategoryName,
    SpanishProductCategoryName, FrenchProductCategoryName
)
SELECT 
    CAST(ProductCategoryKey AS SIGNED),
    CAST(ProductCategoryAlternateKey AS SIGNED),
    TRIM(EnglishProductCategoryName),
    TRIM(SpanishProductCategoryName),
    TRIM(FrenchProductCategoryName)
FROM stg_dim_product_category;

-- DimProductSubcategory
TRUNCATE TABLE dim_product_subcategory;
INSERT INTO dim_product_subcategory (
    ProductSubcategoryKey, ProductSubcategoryAlternateKey, EnglishProductSubcategoryName,
    SpanishProductSubcategoryName, FrenchProductSubcategoryName, ProductCategoryKey
)
SELECT 
    CAST(ProductSubcategoryKey AS SIGNED),
    CAST(ProductSubcategoryAlternateKey AS SIGNED),
    TRIM(EnglishProductSubcategoryName),
    TRIM(SpanishProductSubcategoryName),
    TRIM(FrenchProductSubcategoryName),
    CAST(ProductCategoryKey AS SIGNED)
FROM stg_dim_product_subcategory;

-- DimProduct (SCD Type 2 Preserved)
TRUNCATE TABLE dim_product;
INSERT INTO dim_product (
    ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode,
    SizeUnitMeasureCode, EnglishProductName, SpanishProductName, FrenchProductName,
    StandardCost, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint,
    ListPrice, Size, SizeRange, Weight, DaysToManufacture, ProductLine,
    DealerPrice, Class, Style, ModelName, EnglishDescription, StartDate, EndDate, Status
)
SELECT 
    CAST(ProductKey AS SIGNED),
    TRIM(ProductAlternateKey),
    CAST(NULLIF(TRIM(ProductSubcategoryKey), '') AS SIGNED),
    NULLIF(TRIM(WeightUnitMeasureCode), ''),
    NULLIF(TRIM(SizeUnitMeasureCode), ''),
    TRIM(EnglishProductName),
    NULLIF(TRIM(SpanishProductName), ''),
    NULLIF(TRIM(FrenchProductName), ''),
    CAST(NULLIF(TRIM(StandardCost), '') AS DECIMAL(19,4)),
    CAST(FinishedGoodsFlag AS SIGNED),
    NULLIF(TRIM(Color), ''),
    CAST(SafetyStockLevel AS SIGNED),
    CAST(ReorderPoint AS SIGNED),
    CAST(NULLIF(TRIM(ListPrice), '') AS DECIMAL(19,4)),
    NULLIF(TRIM(Size), ''),
    NULLIF(TRIM(SizeRange), ''),
    CAST(NULLIF(TRIM(Weight), '') AS DECIMAL(10,2)),
    CAST(DaysToManufacture AS SIGNED),
    NULLIF(TRIM(ProductLine), ''),
    CAST(NULLIF(TRIM(DealerPrice), '') AS DECIMAL(19,4)),
    NULLIF(TRIM(Class), ''),
    NULLIF(TRIM(Style), ''),
    NULLIF(TRIM(ModelName), ''),
    NULLIF(TRIM(EnglishDescription), ''),
    STR_TO_DATE(SUBSTRING(StartDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(SUBSTRING(NULLIF(TRIM(EndDate), ''), 1, 19), '%Y-%m-%d %H:%i:%s'),
    NULLIF(TRIM(Status), '')
FROM stg_dim_product;

-- DimSalesTerritory
TRUNCATE TABLE dim_sales_territory;
INSERT INTO dim_sales_territory (
    SalesTerritoryKey, SalesTerritoryAlternateKey, SalesTerritoryRegion,
    SalesTerritoryCountry, SalesTerritoryGroup
)
SELECT 
    CAST(SalesTerritoryKey AS SIGNED),
    CAST(SalesTerritoryAlternateKey AS SIGNED),
    TRIM(SalesTerritoryRegion),
    TRIM(SalesTerritoryCountry),
    TRIM(SalesTerritoryGroup)
FROM stg_dim_sales_territory;

-- DimGeography
TRUNCATE TABLE dim_geography;
INSERT INTO dim_geography (
    GeographyKey, City, StateProvinceCode, StateProvinceName, CountryRegionCode,
    EnglishCountryRegionName, SpanishCountryRegionName, FrenchCountryRegionName,
    PostalCode, SalesTerritoryKey, IpAddressLocator
)
SELECT 
    CAST(GeographyKey AS SIGNED),
    TRIM(City),
    TRIM(StateProvinceCode),
    TRIM(StateProvinceName),
    TRIM(CountryRegionCode),
    TRIM(EnglishCountryRegionName),
    TRIM(SpanishCountryRegionName),
    TRIM(FrenchCountryRegionName),
    TRIM(PostalCode),
    CAST(SalesTerritoryKey AS SIGNED),
    NULLIF(TRIM(IpAddressLocator), '')
FROM stg_dim_geography;

-- DimCustomer
TRUNCATE TABLE dim_customer;
INSERT INTO dim_customer (
    CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName,
    MiddleName, LastName, NameStyle, BirthDate, MaritalStatus, Suffix,
    Gender, EmailAddress, YearlyIncome, TotalChildren, NumberChildrenAtHome,
    EnglishEducation, SpanishEducation, FrenchEducation, EnglishOccupation,
    SpanishOccupation, FrenchOccupation, HouseOwnerFlag, NumberCarsOwned,
    AddressLine1, AddressLine2, Phone, DateFirstPurchase, CommuteDistance
)
SELECT 
    CAST(CustomerKey AS SIGNED),
    CAST(GeographyKey AS SIGNED),
    TRIM(CustomerAlternateKey),
    NULLIF(TRIM(Title), ''),
    TRIM(FirstName),
    NULLIF(TRIM(MiddleName), ''),
    TRIM(LastName),
    CAST(NameStyle AS SIGNED),
    STR_TO_DATE(BirthDate, '%Y-%m-%d'),
    TRIM(MaritalStatus),
    NULLIF(TRIM(Suffix), ''),
    TRIM(Gender),
    NULLIF(TRIM(EmailAddress), ''),
    CAST(NULLIF(TRIM(YearlyIncome), '') AS DECIMAL(19,4)),
    CAST(TotalChildren AS SIGNED),
    CAST(NumberChildrenAtHome AS SIGNED),
    TRIM(EnglishEducation),
    TRIM(SpanishEducation),
    TRIM(FrenchEducation),
    TRIM(EnglishOccupation),
    TRIM(SpanishOccupation),
    TRIM(FrenchOccupation),
    TRIM(HouseOwnerFlag),
    CAST(NumberCarsOwned AS SIGNED),
    TRIM(AddressLine1),
    NULLIF(TRIM(AddressLine2), ''),
    NULLIF(TRIM(Phone), ''),
    STR_TO_DATE(DateFirstPurchase, '%Y-%m-%d'),
    NULLIF(TRIM(CommuteDistance), '')
FROM stg_dim_customer;

-- DimReseller
TRUNCATE TABLE dim_reseller;
INSERT INTO dim_reseller (
    ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType,
    ResellerName, NumberEmployees, OrderFrequency, OrderMonth, FirstOrderYear,
    LastOrderYear, ProductLine, AddressLine1, AddressLine2, AnnualSales,
    BankName, MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened
)
SELECT 
    CAST(ResellerKey AS SIGNED),
    CAST(GeographyKey AS SIGNED),
    TRIM(ResellerAlternateKey),
    NULLIF(TRIM(Phone), ''),
    TRIM(BusinessType),
    TRIM(ResellerName),
    CAST(NULLIF(TRIM(NumberEmployees), '') AS SIGNED),
    NULLIF(TRIM(OrderFrequency), ''),
    CAST(NULLIF(TRIM(OrderMonth), '') AS SIGNED),
    CAST(NULLIF(TRIM(FirstOrderYear), '') AS SIGNED),
    CAST(NULLIF(TRIM(LastOrderYear), '') AS SIGNED),
    NULLIF(TRIM(ProductLine), ''),
    NULLIF(TRIM(AddressLine1), ''),
    NULLIF(TRIM(AddressLine2), ''),
    CAST(NULLIF(TRIM(AnnualSales), '') AS DECIMAL(19,4)),
    NULLIF(TRIM(BankName), ''),
    CAST(NULLIF(TRIM(MinPaymentType), '') AS SIGNED),
    CAST(NULLIF(TRIM(MinPaymentAmount), '') AS DECIMAL(19,4)),
    CAST(NULLIF(TRIM(AnnualRevenue), '') AS DECIMAL(19,4)),
    CAST(NULLIF(TRIM(YearOpened), '') AS SIGNED)
FROM stg_dim_reseller;

-- DimPromotion
TRUNCATE TABLE dim_promotion;
INSERT INTO dim_promotion (
    PromotionKey, PromotionAlternateKey, EnglishPromotionName, SpanishPromotionName,
    FrenchPromotionName, DiscountPct, EnglishPromotionType, EnglishPromotionCategory,
    StartDate, EndDate, MinQty, MaxQty
)
SELECT 
    CAST(PromotionKey AS SIGNED),
    CAST(PromotionAlternateKey AS SIGNED),
    TRIM(EnglishPromotionName),
    NULLIF(TRIM(SpanishPromotionName), ''),
    NULLIF(TRIM(FrenchPromotionName), ''),
    CAST(DiscountPct AS DECIMAL(5,4)),
    TRIM(EnglishPromotionType),
    TRIM(EnglishPromotionCategory),
    STR_TO_DATE(SUBSTRING(StartDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(SUBSTRING(EndDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    CAST(MinQty AS SIGNED),
    CAST(NULLIF(TRIM(MaxQty), '') AS SIGNED)
FROM stg_dim_promotion;

-- DimCurrency
TRUNCATE TABLE dim_currency;
INSERT INTO dim_currency (CurrencyKey, CurrencyAlternateKey, CurrencyName)
SELECT 
    CAST(CurrencyKey AS SIGNED),
    TRIM(CurrencyAlternateKey),
    TRIM(CurrencyName)
FROM stg_dim_currency;

-- ------------------------------------------------------------------------------
-- 2. POPULATE FACTS
-- ------------------------------------------------------------------------------

-- FactInternetSales
TRUNCATE TABLE fact_internet_sales;
INSERT INTO fact_internet_sales (
    SalesOrderNumber, SalesOrderLineNumber, ProductKey, OrderDateKey, DueDateKey,
    ShipDateKey, CustomerKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
    RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct,
    DiscountAmount, ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt,
    Freight, CarrierTrackingNumber, CustomerPONumber, OrderDate, DueDate, ShipDate
)
SELECT 
    TRIM(SalesOrderNumber),
    CAST(SalesOrderLineNumber AS SIGNED),
    CAST(ProductKey AS SIGNED),
    CAST(OrderDateKey AS SIGNED),
    CAST(DueDateKey AS SIGNED),
    CAST(ShipDateKey AS SIGNED),
    CAST(CustomerKey AS SIGNED),
    CAST(PromotionKey AS SIGNED),
    CAST(CurrencyKey AS SIGNED),
    CAST(SalesTerritoryKey AS SIGNED),
    CAST(RevisionNumber AS SIGNED),
    CAST(OrderQuantity AS SIGNED),
    CAST(UnitPrice AS DECIMAL(19,4)),
    CAST(ExtendedAmount AS DECIMAL(19,4)),
    CAST(UnitPriceDiscountPct AS DECIMAL(5,4)),
    CAST(DiscountAmount AS DECIMAL(19,4)),
    CAST(ProductStandardCost AS DECIMAL(19,4)),
    CAST(TotalProductCost AS DECIMAL(19,4)),
    CAST(SalesAmount AS DECIMAL(19,4)),
    CAST(TaxAmt AS DECIMAL(19,4)),
    CAST(Freight AS DECIMAL(19,4)),
    NULLIF(TRIM(CarrierTrackingNumber), ''),
    NULLIF(TRIM(CustomerPONumber), ''),
    STR_TO_DATE(SUBSTRING(OrderDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(SUBSTRING(DueDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(SUBSTRING(ShipDate, 1, 19), '%Y-%m-%d %H:%i:%s')
FROM stg_fact_internet_sales;

-- FactResellerSales
TRUNCATE TABLE fact_reseller_sales;
INSERT INTO fact_reseller_sales (
    SalesOrderNumber, SalesOrderLineNumber, ProductKey, OrderDateKey, DueDateKey,
    ShipDateKey, ResellerKey, EmployeeKey, PromotionKey, CurrencyKey,
    SalesTerritoryKey, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount,
    UnitPriceDiscountPct, DiscountAmount, ProductStandardCost, TotalProductCost,
    SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, CustomerPONumber,
    OrderDate, DueDate, ShipDate
)
SELECT 
    TRIM(SalesOrderNumber),
    CAST(SalesOrderLineNumber AS SIGNED),
    CAST(ProductKey AS SIGNED),
    CAST(OrderDateKey AS SIGNED),
    CAST(DueDateKey AS SIGNED),
    CAST(ShipDateKey AS SIGNED),
    CAST(ResellerKey AS SIGNED),
    CAST(EmployeeKey AS SIGNED),
    CAST(PromotionKey AS SIGNED),
    CAST(CurrencyKey AS SIGNED),
    CAST(SalesTerritoryKey AS SIGNED),
    CAST(RevisionNumber AS SIGNED),
    CAST(OrderQuantity AS SIGNED),
    CAST(UnitPrice AS DECIMAL(19,4)),
    CAST(ExtendedAmount AS DECIMAL(19,4)),
    CAST(UnitPriceDiscountPct AS DECIMAL(5,4)),
    CAST(DiscountAmount AS DECIMAL(19,4)),
    CAST(ProductStandardCost AS DECIMAL(19,4)),
    CAST(TotalProductCost AS DECIMAL(19,4)),
    CAST(SalesAmount AS DECIMAL(19,4)),
    CAST(TaxAmt AS DECIMAL(19,4)),
    CAST(Freight AS DECIMAL(19,4)),
    NULLIF(TRIM(CarrierTrackingNumber), ''),
    NULLIF(TRIM(CustomerPONumber), ''),
    STR_TO_DATE(SUBSTRING(OrderDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(SUBSTRING(DueDate, 1, 19), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(SUBSTRING(ShipDate, 1, 19), '%Y-%m-%d %H:%i:%s')
FROM stg_fact_reseller_sales;

-- FactProductInventory (Flagging Negative Stock Artefacts)
TRUNCATE TABLE fact_product_inventory;
INSERT INTO fact_product_inventory (
    ProductKey, DateKey, MovementDate, UnitCost, UnitsIn, UnitsOut, UnitsBalance, dq_flag
)
SELECT 
    CAST(ProductKey AS SIGNED),
    CAST(DateKey AS SIGNED),
    STR_TO_DATE(MovementDate, '%Y-%m-%d'),
    CAST(UnitCost AS DECIMAL(19,4)),
    CAST(UnitsIn AS SIGNED),
    CAST(UnitsOut AS SIGNED),
    CAST(UnitsBalance AS SIGNED),
    IF(CAST(UnitsBalance AS SIGNED) < 0, 'NEGATIVE_BALANCE', 'NORMAL')
FROM stg_fact_product_inventory;

-- FactCurrencyRate
TRUNCATE TABLE fact_currency_rate;
INSERT INTO fact_currency_rate (
    CurrencyKey, DateKey, AverageRate, EndOfDayRate, Date
)
SELECT 
    CAST(CurrencyKey AS SIGNED),
    CAST(DateKey AS SIGNED),
    CAST(AverageRate AS DECIMAL(12,6)),
    CAST(EndOfDayRate AS DECIMAL(12,6)),
    STR_TO_DATE(SUBSTRING(Date, 1, 19), '%Y-%m-%d %H:%i:%s')
FROM stg_fact_currency_rate;

-- FactSalesQuota
TRUNCATE TABLE fact_sales_quota;
INSERT INTO fact_sales_quota (
    SalesQuotaKey, EmployeeKey, DateKey, CalendarYear, CalendarQuarter, SalesAmountQuota, Date
)
SELECT 
    CAST(SalesQuotaKey AS SIGNED),
    CAST(EmployeeKey AS SIGNED),
    CAST(DateKey AS SIGNED),
    CAST(CalendarYear AS SIGNED),
    CAST(CalendarQuarter AS SIGNED),
    CAST(SalesAmountQuota AS DECIMAL(19,4)),
    STR_TO_DATE(SUBSTRING(Date, 1, 19), '%Y-%m-%d %H:%i:%s')
FROM stg_fact_sales_quota;

-- ------------------------------------------------------------------------------
-- 3. POPULATE UNIFIED SALES FACT TABLE (fact_sales_line)
-- ------------------------------------------------------------------------------
-- Combines retail and wholesale order lines.
-- 60,398 (Internet) + 60,855 (Reseller) = 121,253 total sales lines.
-- ------------------------------------------------------------------------------

TRUNCATE TABLE fact_sales_line;

INSERT INTO fact_sales_line (
    channel, SalesOrderNumber, SalesOrderLineNumber, ProductKey, OrderDateKey,
    DueDateKey, ShipDateKey, CustomerKey, ResellerKey, EmployeeKey,
    PromotionKey, CurrencyKey, SalesTerritoryKey, RevisionNumber, OrderQuantity,
    UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount,
    ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt, Freight,
    CarrierTrackingNumber, CustomerPONumber, OrderDate, DueDate, ShipDate
)
SELECT 
    'Internet' AS channel,
    SalesOrderNumber,
    SalesOrderLineNumber,
    ProductKey,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    CustomerKey,
    NULL AS ResellerKey,
    NULL AS EmployeeKey,
    PromotionKey,
    CurrencyKey,
    SalesTerritoryKey,
    RevisionNumber,
    OrderQuantity,
    UnitPrice,
    ExtendedAmount,
    UnitPriceDiscountPct,
    DiscountAmount,
    ProductStandardCost,
    TotalProductCost,
    SalesAmount,
    TaxAmt,
    Freight,
    CarrierTrackingNumber,
    CustomerPONumber,
    OrderDate,
    DueDate,
    ShipDate
FROM fact_internet_sales
UNION ALL
SELECT 
    'Reseller' AS channel,
    SalesOrderNumber,
    SalesOrderLineNumber,
    ProductKey,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    NULL AS CustomerKey,
    ResellerKey,
    EmployeeKey,
    PromotionKey,
    CurrencyKey,
    SalesTerritoryKey,
    RevisionNumber,
    OrderQuantity,
    UnitPrice,
    ExtendedAmount,
    UnitPriceDiscountPct,
    DiscountAmount,
    ProductStandardCost,
    TotalProductCost,
    SalesAmount,
    TaxAmt,
    Freight,
    CarrierTrackingNumber,
    CustomerPONumber,
    OrderDate,
    DueDate,
    ShipDate
FROM fact_reseller_sales;

SET foreign_key_checks = 1;

-- ------------------------------------------------------------------------------
-- 4. RECONCILIATION AUDIT: STAGING VS ANALYTICAL ROW COUNTS
-- ------------------------------------------------------------------------------

SELECT 
    'DimDate' AS table_entity,
    (SELECT COUNT(*) FROM stg_dim_date) AS staging_rows,
    (SELECT COUNT(*) FROM dim_date) AS analytical_rows,
    IF((SELECT COUNT(*) FROM stg_dim_date) = (SELECT COUNT(*) FROM dim_date), 'RECONCILED', 'MISMATCH') AS status
UNION ALL
SELECT 'DimProductCategory', (SELECT COUNT(*) FROM stg_dim_product_category), (SELECT COUNT(*) FROM dim_product_category),
    IF((SELECT COUNT(*) FROM stg_dim_product_category) = (SELECT COUNT(*) FROM dim_product_category), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimProductSubcategory', (SELECT COUNT(*) FROM stg_dim_product_subcategory), (SELECT COUNT(*) FROM dim_product_subcategory),
    IF((SELECT COUNT(*) FROM stg_dim_product_subcategory) = (SELECT COUNT(*) FROM dim_product_subcategory), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimProduct', (SELECT COUNT(*) FROM stg_dim_product), (SELECT COUNT(*) FROM dim_product),
    IF((SELECT COUNT(*) FROM stg_dim_product) = (SELECT COUNT(*) FROM dim_product), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimCustomer', (SELECT COUNT(*) FROM stg_dim_customer), (SELECT COUNT(*) FROM dim_customer),
    IF((SELECT COUNT(*) FROM stg_dim_customer) = (SELECT COUNT(*) FROM dim_customer), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimReseller', (SELECT COUNT(*) FROM stg_dim_reseller), (SELECT COUNT(*) FROM dim_reseller),
    IF((SELECT COUNT(*) FROM stg_dim_reseller) = (SELECT COUNT(*) FROM dim_reseller), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimSalesTerritory', (SELECT COUNT(*) FROM stg_dim_sales_territory), (SELECT COUNT(*) FROM dim_sales_territory),
    IF((SELECT COUNT(*) FROM stg_dim_sales_territory) = (SELECT COUNT(*) FROM dim_sales_territory), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimGeography', (SELECT COUNT(*) FROM stg_dim_geography), (SELECT COUNT(*) FROM dim_geography),
    IF((SELECT COUNT(*) FROM stg_dim_geography) = (SELECT COUNT(*) FROM dim_geography), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimPromotion', (SELECT COUNT(*) FROM stg_dim_promotion), (SELECT COUNT(*) FROM dim_promotion),
    IF((SELECT COUNT(*) FROM stg_dim_promotion) = (SELECT COUNT(*) FROM dim_promotion), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'DimCurrency', (SELECT COUNT(*) FROM stg_dim_currency), (SELECT COUNT(*) FROM dim_currency),
    IF((SELECT COUNT(*) FROM stg_dim_currency) = (SELECT COUNT(*) FROM dim_currency), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'FactInternetSales', (SELECT COUNT(*) FROM stg_fact_internet_sales), (SELECT COUNT(*) FROM fact_internet_sales),
    IF((SELECT COUNT(*) FROM stg_fact_internet_sales) = (SELECT COUNT(*) FROM fact_internet_sales), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'FactResellerSales', (SELECT COUNT(*) FROM stg_fact_reseller_sales), (SELECT COUNT(*) FROM fact_reseller_sales),
    IF((SELECT COUNT(*) FROM stg_fact_reseller_sales) = (SELECT COUNT(*) FROM fact_reseller_sales), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'FactProductInventory', (SELECT COUNT(*) FROM stg_fact_product_inventory), (SELECT COUNT(*) FROM fact_product_inventory),
    IF((SELECT COUNT(*) FROM stg_fact_product_inventory) = (SELECT COUNT(*) FROM fact_product_inventory), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'FactCurrencyRate', (SELECT COUNT(*) FROM stg_fact_currency_rate), (SELECT COUNT(*) FROM fact_currency_rate),
    IF((SELECT COUNT(*) FROM stg_fact_currency_rate) = (SELECT COUNT(*) FROM fact_currency_rate), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 'FactSalesQuota', (SELECT COUNT(*) FROM stg_fact_sales_quota), (SELECT COUNT(*) FROM fact_sales_quota),
    IF((SELECT COUNT(*) FROM stg_fact_sales_quota) = (SELECT COUNT(*) FROM fact_sales_quota), 'RECONCILED', 'MISMATCH')
UNION ALL
SELECT 
    'fact_sales_line (Unified)',
    (SELECT COUNT(*) FROM stg_fact_internet_sales) + (SELECT COUNT(*) FROM stg_fact_reseller_sales),
    (SELECT COUNT(*) FROM fact_sales_line),
    IF((SELECT COUNT(*) FROM fact_sales_line) = ((SELECT COUNT(*) FROM stg_fact_internet_sales) + (SELECT COUNT(*) FROM stg_fact_reseller_sales)), 'RECONCILED', 'MISMATCH');

-- Financial Total Revenue Reconciliation: Staging vs fact_sales_line
SELECT 
    'Internet Sales Revenue' AS stream,
    ROUND(SUM(CAST(SalesAmount AS DECIMAL(19,4))), 2) AS staging_sales_amt,
    ROUND((SELECT SUM(SalesAmount) FROM fact_sales_line WHERE channel = 'Internet'), 2) AS analytical_sales_amt
FROM stg_fact_internet_sales
UNION ALL
SELECT 
    'Reseller Sales Revenue',
    ROUND(SUM(CAST(SalesAmount AS DECIMAL(19,4))), 2),
    ROUND((SELECT SUM(SalesAmount) FROM fact_sales_line WHERE channel = 'Reseller'), 2)
FROM stg_fact_reseller_sales;
