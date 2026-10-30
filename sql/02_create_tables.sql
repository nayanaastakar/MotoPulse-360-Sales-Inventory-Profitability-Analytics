-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 02: Table Architecture (Staging Layer & Typed Analytical Layer)
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- DESIGN PRINCIPLES:
-- 1. STAGING LAYER (stg_*): Raw copy of clean CSV text data for traceability and audit.
--    All fields are VARCHAR/TEXT. Never modified in-place.
-- 2. ANALYTICAL LAYER (dim_*, fact_*): Strongly typed star-schema tables.
--    DECIMAL(19,4) for currency to eliminate floating-point rounding errors.
--    DATE and DATETIME for all temporal fields. Strict PK/FK constraints.
-- 3. UNIFIED SALES GRAIN (fact_sales_line): Stacking retail and wholesale lines
--    at grain (channel, SalesOrderNumber, SalesOrderLineNumber).
-- ==============================================================================

USE motopulse360;

SET foreign_key_checks = 0;

-- ==============================================================================
-- PART 1: STAGING TABLES (stg_*)
-- ==============================================================================

DROP TABLE IF EXISTS stg_dim_date;
CREATE TABLE stg_dim_date (
    DateKey VARCHAR(50),
    FullDateAlternateKey VARCHAR(50),
    DayNumberOfWeek VARCHAR(50),
    EnglishDayNameOfWeek VARCHAR(50),
    SpanishDayNameOfWeek VARCHAR(50),
    FrenchDayNameOfWeek VARCHAR(50),
    DayNumberOfMonth VARCHAR(50),
    DayNumberOfYear VARCHAR(50),
    WeekNumberOfYear VARCHAR(50),
    EnglishMonthName VARCHAR(50),
    SpanishMonthName VARCHAR(50),
    FrenchMonthName VARCHAR(50),
    MonthNumberOfYear VARCHAR(50),
    CalendarQuarter VARCHAR(50),
    CalendarYear VARCHAR(50),
    CalendarSemester VARCHAR(50),
    FiscalQuarter VARCHAR(50),
    FiscalYear VARCHAR(50),
    FiscalSemester VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_product_category;
CREATE TABLE stg_dim_product_category (
    ProductCategoryKey VARCHAR(50),
    ProductCategoryAlternateKey VARCHAR(50),
    EnglishProductCategoryName VARCHAR(100),
    SpanishProductCategoryName VARCHAR(100),
    FrenchProductCategoryName VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_product_subcategory;
CREATE TABLE stg_dim_product_subcategory (
    ProductSubcategoryKey VARCHAR(50),
    ProductSubcategoryAlternateKey VARCHAR(50),
    EnglishProductSubcategoryName VARCHAR(100),
    SpanishProductSubcategoryName VARCHAR(100),
    FrenchProductSubcategoryName VARCHAR(100),
    ProductCategoryKey VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_product;
CREATE TABLE stg_dim_product (
    ProductKey VARCHAR(50),
    ProductAlternateKey VARCHAR(50),
    ProductSubcategoryKey VARCHAR(50),
    WeightUnitMeasureCode VARCHAR(50),
    SizeUnitMeasureCode VARCHAR(50),
    EnglishProductName VARCHAR(100),
    SpanishProductName VARCHAR(100),
    FrenchProductName VARCHAR(100),
    StandardCost VARCHAR(50),
    FinishedGoodsFlag VARCHAR(50),
    Color VARCHAR(50),
    SafetyStockLevel VARCHAR(50),
    ReorderPoint VARCHAR(50),
    ListPrice VARCHAR(50),
    Size VARCHAR(50),
    SizeRange VARCHAR(50),
    Weight VARCHAR(50),
    DaysToManufacture VARCHAR(50),
    ProductLine VARCHAR(50),
    DealerPrice VARCHAR(50),
    Class VARCHAR(50),
    Style VARCHAR(50),
    ModelName VARCHAR(100),
    LargePhoto MEDIUMTEXT,
    EnglishDescription TEXT,
    FrenchDescription TEXT,
    ChineseDescription TEXT,
    ArabicDescription TEXT,
    HebrewDescription TEXT,
    ThaiDescription TEXT,
    GermanDescription TEXT,
    JapaneseDescription TEXT,
    TurkishDescription TEXT,
    StartDate VARCHAR(50),
    EndDate VARCHAR(50),
    Status VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_customer;
CREATE TABLE stg_dim_customer (
    CustomerKey VARCHAR(50),
    GeographyKey VARCHAR(50),
    CustomerAlternateKey VARCHAR(50),
    Title VARCHAR(50),
    FirstName VARCHAR(100),
    MiddleName VARCHAR(100),
    LastName VARCHAR(100),
    NameStyle VARCHAR(50),
    BirthDate VARCHAR(50),
    MaritalStatus VARCHAR(50),
    Suffix VARCHAR(50),
    Gender VARCHAR(50),
    EmailAddress VARCHAR(150),
    YearlyIncome VARCHAR(50),
    TotalChildren VARCHAR(50),
    NumberChildrenAtHome VARCHAR(50),
    EnglishEducation VARCHAR(100),
    SpanishEducation VARCHAR(100),
    FrenchEducation VARCHAR(100),
    EnglishOccupation VARCHAR(100),
    SpanishOccupation VARCHAR(100),
    FrenchOccupation VARCHAR(100),
    HouseOwnerFlag VARCHAR(50),
    NumberCarsOwned VARCHAR(50),
    AddressLine1 VARCHAR(255),
    AddressLine2 VARCHAR(255),
    Phone VARCHAR(50),
    DateFirstPurchase VARCHAR(50),
    CommuteDistance VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_reseller;
CREATE TABLE stg_dim_reseller (
    ResellerKey VARCHAR(50),
    GeographyKey VARCHAR(50),
    ResellerAlternateKey VARCHAR(50),
    Phone VARCHAR(50),
    BusinessType VARCHAR(100),
    ResellerName VARCHAR(150),
    NumberEmployees VARCHAR(50),
    OrderFrequency VARCHAR(50),
    OrderMonth VARCHAR(50),
    FirstOrderYear VARCHAR(50),
    LastOrderYear VARCHAR(50),
    ProductLine VARCHAR(100),
    AddressLine1 VARCHAR(255),
    AddressLine2 VARCHAR(255),
    AnnualSales VARCHAR(50),
    BankName VARCHAR(100),
    MinPaymentType VARCHAR(50),
    MinPaymentAmount VARCHAR(50),
    AnnualRevenue VARCHAR(50),
    YearOpened VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_sales_territory;
CREATE TABLE stg_dim_sales_territory (
    SalesTerritoryKey VARCHAR(50),
    SalesTerritoryAlternateKey VARCHAR(50),
    SalesTerritoryRegion VARCHAR(100),
    SalesTerritoryCountry VARCHAR(100),
    SalesTerritoryGroup VARCHAR(100),
    SalesTerritoryImage MEDIUMTEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_geography;
CREATE TABLE stg_dim_geography (
    GeographyKey VARCHAR(50),
    City VARCHAR(100),
    StateProvinceCode VARCHAR(50),
    StateProvinceName VARCHAR(100),
    CountryRegionCode VARCHAR(50),
    EnglishCountryRegionName VARCHAR(100),
    SpanishCountryRegionName VARCHAR(100),
    FrenchCountryRegionName VARCHAR(100),
    PostalCode VARCHAR(50),
    SalesTerritoryKey VARCHAR(50),
    IpAddressLocator VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_promotion;
CREATE TABLE stg_dim_promotion (
    PromotionKey VARCHAR(50),
    PromotionAlternateKey VARCHAR(50),
    EnglishPromotionName VARCHAR(255),
    SpanishPromotionName VARCHAR(255),
    FrenchPromotionName VARCHAR(255),
    DiscountPct VARCHAR(50),
    EnglishPromotionType VARCHAR(100),
    SpanishPromotionType VARCHAR(100),
    FrenchPromotionType VARCHAR(100),
    EnglishPromotionCategory VARCHAR(100),
    SpanishPromotionCategory VARCHAR(100),
    FrenchPromotionCategory VARCHAR(100),
    StartDate VARCHAR(50),
    EndDate VARCHAR(50),
    MinQty VARCHAR(50),
    MaxQty VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_dim_currency;
CREATE TABLE stg_dim_currency (
    CurrencyKey VARCHAR(50),
    CurrencyAlternateKey VARCHAR(50),
    CurrencyName VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_fact_internet_sales;
CREATE TABLE stg_fact_internet_sales (
    ProductKey VARCHAR(50),
    OrderDateKey VARCHAR(50),
    DueDateKey VARCHAR(50),
    ShipDateKey VARCHAR(50),
    CustomerKey VARCHAR(50),
    PromotionKey VARCHAR(50),
    CurrencyKey VARCHAR(50),
    SalesTerritoryKey VARCHAR(50),
    SalesOrderNumber VARCHAR(50),
    SalesOrderLineNumber VARCHAR(50),
    RevisionNumber VARCHAR(50),
    OrderQuantity VARCHAR(50),
    UnitPrice VARCHAR(50),
    ExtendedAmount VARCHAR(50),
    UnitPriceDiscountPct VARCHAR(50),
    DiscountAmount VARCHAR(50),
    ProductStandardCost VARCHAR(50),
    TotalProductCost VARCHAR(50),
    SalesAmount VARCHAR(50),
    TaxAmt VARCHAR(50),
    Freight VARCHAR(50),
    CarrierTrackingNumber VARCHAR(50),
    CustomerPONumber VARCHAR(50),
    OrderDate VARCHAR(50),
    DueDate VARCHAR(50),
    ShipDate VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_fact_reseller_sales;
CREATE TABLE stg_fact_reseller_sales (
    ProductKey VARCHAR(50),
    OrderDateKey VARCHAR(50),
    DueDateKey VARCHAR(50),
    ShipDateKey VARCHAR(50),
    ResellerKey VARCHAR(50),
    EmployeeKey VARCHAR(50),
    PromotionKey VARCHAR(50),
    CurrencyKey VARCHAR(50),
    SalesTerritoryKey VARCHAR(50),
    SalesOrderNumber VARCHAR(50),
    SalesOrderLineNumber VARCHAR(50),
    RevisionNumber VARCHAR(50),
    OrderQuantity VARCHAR(50),
    UnitPrice VARCHAR(50),
    ExtendedAmount VARCHAR(50),
    UnitPriceDiscountPct VARCHAR(50),
    DiscountAmount VARCHAR(50),
    ProductStandardCost VARCHAR(50),
    TotalProductCost VARCHAR(50),
    SalesAmount VARCHAR(50),
    TaxAmt VARCHAR(50),
    Freight VARCHAR(50),
    CarrierTrackingNumber VARCHAR(50),
    CustomerPONumber VARCHAR(50),
    OrderDate VARCHAR(50),
    DueDate VARCHAR(50),
    ShipDate VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_fact_product_inventory;
CREATE TABLE stg_fact_product_inventory (
    ProductKey VARCHAR(50),
    DateKey VARCHAR(50),
    MovementDate VARCHAR(50),
    UnitCost VARCHAR(50),
    UnitsIn VARCHAR(50),
    UnitsOut VARCHAR(50),
    UnitsBalance VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_fact_currency_rate;
CREATE TABLE stg_fact_currency_rate (
    CurrencyKey VARCHAR(50),
    DateKey VARCHAR(50),
    AverageRate VARCHAR(50),
    EndOfDayRate VARCHAR(50),
    Date VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stg_fact_sales_quota;
CREATE TABLE stg_fact_sales_quota (
    SalesQuotaKey VARCHAR(50),
    EmployeeKey VARCHAR(50),
    DateKey VARCHAR(50),
    CalendarYear VARCHAR(50),
    CalendarQuarter VARCHAR(50),
    SalesAmountQuota VARCHAR(50),
    Date VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- PART 2: TYPED ANALYTICAL TABLES (dim_*, fact_*)
-- ==============================================================================

DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    DateKey INT NOT NULL,
    FullDateAlternateKey DATE NOT NULL,
    DayNumberOfWeek TINYINT NOT NULL,
    EnglishDayNameOfWeek VARCHAR(10) NOT NULL,
    SpanishDayNameOfWeek VARCHAR(10) NOT NULL,
    FrenchDayNameOfWeek VARCHAR(10) NOT NULL,
    DayNumberOfMonth TINYINT NOT NULL,
    DayNumberOfYear SMALLINT NOT NULL,
    WeekNumberOfYear TINYINT NOT NULL,
    EnglishMonthName VARCHAR(10) NOT NULL,
    SpanishMonthName VARCHAR(10) NOT NULL,
    FrenchMonthName VARCHAR(10) NOT NULL,
    MonthNumberOfYear TINYINT NOT NULL,
    CalendarQuarter TINYINT NOT NULL,
    CalendarYear SMALLINT NOT NULL,
    CalendarSemester TINYINT NOT NULL,
    FiscalQuarter TINYINT NOT NULL,
    FiscalYear SMALLINT NOT NULL,
    FiscalSemester TINYINT NOT NULL,
    PRIMARY KEY (DateKey),
    UNIQUE KEY uq_dim_date_fulldate (FullDateAlternateKey),
    KEY idx_dim_date_year_month (CalendarYear, MonthNumberOfYear)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_product_category;
CREATE TABLE dim_product_category (
    ProductCategoryKey INT NOT NULL,
    ProductCategoryAlternateKey INT NOT NULL,
    EnglishProductCategoryName VARCHAR(50) NOT NULL,
    SpanishProductCategoryName VARCHAR(50) NOT NULL,
    FrenchProductCategoryName VARCHAR(50) NOT NULL,
    PRIMARY KEY (ProductCategoryKey),
    UNIQUE KEY uq_dim_product_category_alt (ProductCategoryAlternateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_product_subcategory;
CREATE TABLE dim_product_subcategory (
    ProductSubcategoryKey INT NOT NULL,
    ProductSubcategoryAlternateKey INT NOT NULL,
    EnglishProductSubcategoryName VARCHAR(50) NOT NULL,
    SpanishProductSubcategoryName VARCHAR(50) NOT NULL,
    FrenchProductSubcategoryName VARCHAR(50) NOT NULL,
    ProductCategoryKey INT NOT NULL,
    PRIMARY KEY (ProductSubcategoryKey),
    UNIQUE KEY uq_dim_product_subcat_alt (ProductSubcategoryAlternateKey),
    CONSTRAINT fk_subcat_category FOREIGN KEY (ProductCategoryKey) 
        REFERENCES dim_product_category (ProductCategoryKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    ProductKey INT NOT NULL,
    ProductAlternateKey VARCHAR(25) NOT NULL,
    ProductSubcategoryKey INT NULL,
    WeightUnitMeasureCode CHAR(3) NULL,
    SizeUnitMeasureCode CHAR(3) NULL,
    EnglishProductName VARCHAR(50) NOT NULL,
    SpanishProductName VARCHAR(50) NULL,
    FrenchProductName VARCHAR(50) NULL,
    StandardCost DECIMAL(19,4) NULL,
    FinishedGoodsFlag TINYINT(1) NOT NULL DEFAULT 1,
    Color VARCHAR(15) NULL,
    SafetyStockLevel SMALLINT NOT NULL,
    ReorderPoint SMALLINT NOT NULL,
    ListPrice DECIMAL(19,4) NULL,
    Size VARCHAR(50) NULL,
    SizeRange VARCHAR(50) NULL,
    Weight DECIMAL(10,2) NULL,
    DaysToManufacture INT NOT NULL,
    ProductLine CHAR(2) NULL,
    DealerPrice DECIMAL(19,4) NULL,
    Class CHAR(2) NULL,
    Style CHAR(2) NULL,
    ModelName VARCHAR(50) NULL,
    EnglishDescription VARCHAR(400) NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status VARCHAR(7) NULL,
    PRIMARY KEY (ProductKey),
    KEY idx_dim_product_alt_key (ProductAlternateKey),
    KEY idx_dim_product_model (ModelName),
    CONSTRAINT fk_product_subcategory FOREIGN KEY (ProductSubcategoryKey) 
        REFERENCES dim_product_subcategory (ProductSubcategoryKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_sales_territory;
CREATE TABLE dim_sales_territory (
    SalesTerritoryKey INT NOT NULL,
    SalesTerritoryAlternateKey INT NOT NULL,
    SalesTerritoryRegion VARCHAR(50) NOT NULL,
    SalesTerritoryCountry VARCHAR(50) NOT NULL,
    SalesTerritoryGroup VARCHAR(50) NOT NULL,
    PRIMARY KEY (SalesTerritoryKey),
    UNIQUE KEY uq_dim_territory_alt (SalesTerritoryAlternateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_geography;
CREATE TABLE dim_geography (
    GeographyKey INT NOT NULL,
    City VARCHAR(30) NOT NULL,
    StateProvinceCode VARCHAR(5) NOT NULL,
    StateProvinceName VARCHAR(50) NOT NULL,
    CountryRegionCode VARCHAR(3) NOT NULL,
    EnglishCountryRegionName VARCHAR(50) NOT NULL,
    SpanishCountryRegionName VARCHAR(50) NOT NULL,
    FrenchCountryRegionName VARCHAR(50) NOT NULL,
    PostalCode VARCHAR(15) NOT NULL,
    SalesTerritoryKey INT NOT NULL,
    IpAddressLocator VARCHAR(15) NULL,
    PRIMARY KEY (GeographyKey),
    CONSTRAINT fk_geography_territory FOREIGN KEY (SalesTerritoryKey) 
        REFERENCES dim_sales_territory (SalesTerritoryKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
    CustomerKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    CustomerAlternateKey VARCHAR(15) NOT NULL,
    Title VARCHAR(8) NULL,
    FirstName VARCHAR(50) NOT NULL,
    MiddleName VARCHAR(50) NULL,
    LastName VARCHAR(50) NOT NULL,
    NameStyle TINYINT(1) NOT NULL DEFAULT 0,
    BirthDate DATE NOT NULL,
    MaritalStatus CHAR(1) NOT NULL,
    Suffix VARCHAR(10) NULL,
    Gender CHAR(1) NOT NULL,
    EmailAddress VARCHAR(50) NULL,
    YearlyIncome DECIMAL(19,4) NULL,
    TotalChildren TINYINT NOT NULL DEFAULT 0,
    NumberChildrenAtHome TINYINT NOT NULL DEFAULT 0,
    EnglishEducation VARCHAR(40) NOT NULL,
    SpanishEducation VARCHAR(40) NOT NULL,
    FrenchEducation VARCHAR(40) NOT NULL,
    EnglishOccupation VARCHAR(100) NOT NULL,
    SpanishOccupation VARCHAR(100) NOT NULL,
    FrenchOccupation VARCHAR(100) NOT NULL,
    HouseOwnerFlag CHAR(1) NOT NULL,
    NumberCarsOwned TINYINT NOT NULL DEFAULT 0,
    AddressLine1 VARCHAR(120) NOT NULL,
    AddressLine2 VARCHAR(120) NULL,
    Phone VARCHAR(20) NULL,
    DateFirstPurchase DATE NOT NULL,
    CommuteDistance VARCHAR(15) NULL,
    PRIMARY KEY (CustomerKey),
    UNIQUE KEY uq_dim_customer_alt (CustomerAlternateKey),
    CONSTRAINT fk_customer_geography FOREIGN KEY (GeographyKey) 
        REFERENCES dim_geography (GeographyKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_reseller;
CREATE TABLE dim_reseller (
    ResellerKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    ResellerAlternateKey VARCHAR(15) NOT NULL,
    Phone VARCHAR(25) NULL,
    BusinessType VARCHAR(25) NOT NULL,
    ResellerName VARCHAR(50) NOT NULL,
    NumberEmployees INT NULL,
    OrderFrequency CHAR(1) NULL,
    OrderMonth TINYINT NULL,
    FirstOrderYear INT NULL,
    LastOrderYear INT NULL,
    ProductLine VARCHAR(50) NULL,
    AddressLine1 VARCHAR(60) NULL,
    AddressLine2 VARCHAR(60) NULL,
    AnnualSales DECIMAL(19,4) NULL,
    BankName VARCHAR(50) NULL,
    MinPaymentType TINYINT NULL,
    MinPaymentAmount DECIMAL(19,4) NULL,
    AnnualRevenue DECIMAL(19,4) NULL,
    YearOpened INT NULL,
    PRIMARY KEY (ResellerKey),
    UNIQUE KEY uq_dim_reseller_alt (ResellerAlternateKey),
    CONSTRAINT fk_reseller_geography FOREIGN KEY (GeographyKey) 
        REFERENCES dim_geography (GeographyKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_promotion;
CREATE TABLE dim_promotion (
    PromotionKey INT NOT NULL,
    PromotionAlternateKey INT NOT NULL,
    EnglishPromotionName VARCHAR(255) NOT NULL,
    SpanishPromotionName VARCHAR(255) NULL,
    FrenchPromotionName VARCHAR(255) NULL,
    DiscountPct DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    EnglishPromotionType VARCHAR(50) NOT NULL,
    EnglishPromotionCategory VARCHAR(50) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    MinQty INT NOT NULL DEFAULT 0,
    MaxQty INT NULL,
    PRIMARY KEY (PromotionKey),
    UNIQUE KEY uq_dim_promotion_alt (PromotionAlternateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS dim_currency;
CREATE TABLE dim_currency (
    CurrencyKey INT NOT NULL,
    CurrencyAlternateKey CHAR(3) NOT NULL,
    CurrencyName VARCHAR(50) NOT NULL,
    PRIMARY KEY (CurrencyKey),
    UNIQUE KEY uq_dim_currency_alt (CurrencyAlternateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS fact_internet_sales;
CREATE TABLE fact_internet_sales (
    SalesOrderNumber VARCHAR(20) NOT NULL,
    SalesOrderLineNumber TINYINT NOT NULL,
    ProductKey INT NOT NULL,
    OrderDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    ShipDateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    PromotionKey INT NOT NULL,
    CurrencyKey INT NOT NULL,
    SalesTerritoryKey INT NOT NULL,
    RevisionNumber TINYINT NOT NULL DEFAULT 1,
    OrderQuantity SMALLINT NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    ExtendedAmount DECIMAL(19,4) NOT NULL,
    UnitPriceDiscountPct DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    DiscountAmount DECIMAL(19,4) NOT NULL DEFAULT 0.0000,
    ProductStandardCost DECIMAL(19,4) NOT NULL,
    TotalProductCost DECIMAL(19,4) NOT NULL,
    SalesAmount DECIMAL(19,4) NOT NULL,
    TaxAmt DECIMAL(19,4) NOT NULL,
    Freight DECIMAL(19,4) NOT NULL,
    CarrierTrackingNumber VARCHAR(25) NULL,
    CustomerPONumber VARCHAR(25) NULL,
    OrderDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    ShipDate DATETIME NOT NULL,
    PRIMARY KEY (SalesOrderNumber, SalesOrderLineNumber),
    CONSTRAINT fk_fis_product FOREIGN KEY (ProductKey) REFERENCES dim_product (ProductKey),
    CONSTRAINT fk_fis_order_date FOREIGN KEY (OrderDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_fis_due_date FOREIGN KEY (DueDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_fis_ship_date FOREIGN KEY (ShipDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_fis_customer FOREIGN KEY (CustomerKey) REFERENCES dim_customer (CustomerKey),
    CONSTRAINT fk_fis_promotion FOREIGN KEY (PromotionKey) REFERENCES dim_promotion (PromotionKey),
    CONSTRAINT fk_fis_currency FOREIGN KEY (CurrencyKey) REFERENCES dim_currency (CurrencyKey),
    CONSTRAINT fk_fis_territory FOREIGN KEY (SalesTerritoryKey) REFERENCES dim_sales_territory (SalesTerritoryKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS fact_reseller_sales;
CREATE TABLE fact_reseller_sales (
    SalesOrderNumber VARCHAR(20) NOT NULL,
    SalesOrderLineNumber TINYINT NOT NULL,
    ProductKey INT NOT NULL,
    OrderDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    ShipDateKey INT NOT NULL,
    ResellerKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    PromotionKey INT NOT NULL,
    CurrencyKey INT NOT NULL,
    SalesTerritoryKey INT NOT NULL,
    RevisionNumber TINYINT NOT NULL DEFAULT 1,
    OrderQuantity SMALLINT NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    ExtendedAmount DECIMAL(19,4) NOT NULL,
    UnitPriceDiscountPct DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    DiscountAmount DECIMAL(19,4) NOT NULL DEFAULT 0.0000,
    ProductStandardCost DECIMAL(19,4) NOT NULL,
    TotalProductCost DECIMAL(19,4) NOT NULL,
    SalesAmount DECIMAL(19,4) NOT NULL,
    TaxAmt DECIMAL(19,4) NOT NULL,
    Freight DECIMAL(19,4) NOT NULL,
    CarrierTrackingNumber VARCHAR(25) NULL,
    CustomerPONumber VARCHAR(25) NULL,
    OrderDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    ShipDate DATETIME NOT NULL,
    PRIMARY KEY (SalesOrderNumber, SalesOrderLineNumber),
    CONSTRAINT fk_frs_product FOREIGN KEY (ProductKey) REFERENCES dim_product (ProductKey),
    CONSTRAINT fk_frs_order_date FOREIGN KEY (OrderDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_frs_due_date FOREIGN KEY (DueDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_frs_ship_date FOREIGN KEY (ShipDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_frs_reseller FOREIGN KEY (ResellerKey) REFERENCES dim_reseller (ResellerKey),
    CONSTRAINT fk_frs_promotion FOREIGN KEY (PromotionKey) REFERENCES dim_promotion (PromotionKey),
    CONSTRAINT fk_frs_currency FOREIGN KEY (CurrencyKey) REFERENCES dim_currency (CurrencyKey),
    CONSTRAINT fk_frs_territory FOREIGN KEY (SalesTerritoryKey) REFERENCES dim_sales_territory (SalesTerritoryKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS fact_product_inventory;
CREATE TABLE fact_product_inventory (
    ProductKey INT NOT NULL,
    DateKey INT NOT NULL,
    MovementDate DATE NOT NULL,
    UnitCost DECIMAL(19,4) NOT NULL,
    UnitsIn INT NOT NULL DEFAULT 0,
    UnitsOut INT NOT NULL DEFAULT 0,
    UnitsBalance INT NOT NULL,
    dq_flag VARCHAR(50) NULL,
    PRIMARY KEY (ProductKey, DateKey),
    KEY idx_inventory_movement_date (MovementDate),
    CONSTRAINT fk_fpi_product FOREIGN KEY (ProductKey) REFERENCES dim_product (ProductKey),
    CONSTRAINT fk_fpi_date FOREIGN KEY (DateKey) REFERENCES dim_date (DateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS fact_currency_rate;
CREATE TABLE fact_currency_rate (
    CurrencyKey INT NOT NULL,
    DateKey INT NOT NULL,
    AverageRate DECIMAL(12,6) NOT NULL,
    EndOfDayRate DECIMAL(12,6) NOT NULL,
    Date DATETIME NOT NULL,
    PRIMARY KEY (CurrencyKey, DateKey),
    CONSTRAINT fk_fcr_currency FOREIGN KEY (CurrencyKey) REFERENCES dim_currency (CurrencyKey),
    CONSTRAINT fk_fcr_date FOREIGN KEY (DateKey) REFERENCES dim_date (DateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS fact_sales_quota;
CREATE TABLE fact_sales_quota (
    SalesQuotaKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    DateKey INT NOT NULL,
    CalendarYear SMALLINT NOT NULL,
    CalendarQuarter TINYINT NOT NULL,
    SalesAmountQuota DECIMAL(19,4) NOT NULL,
    Date DATETIME NOT NULL,
    PRIMARY KEY (SalesQuotaKey),
    CONSTRAINT fk_fsq_date FOREIGN KEY (DateKey) REFERENCES dim_date (DateKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- PART 3: UNIFIED ANALYTICAL SALES FACT TABLE (fact_sales_line)
-- ==============================================================================
-- Consolidates retail (Internet) and wholesale (Reseller) order lines at single grain.
-- Exactly one of CustomerKey / ResellerKey is populated.
-- ==============================================================================

DROP TABLE IF EXISTS fact_sales_line;
CREATE TABLE fact_sales_line (
    channel VARCHAR(10) NOT NULL,
    SalesOrderNumber VARCHAR(20) NOT NULL,
    SalesOrderLineNumber TINYINT NOT NULL,
    ProductKey INT NOT NULL,
    OrderDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    ShipDateKey INT NOT NULL,
    CustomerKey INT NULL,
    ResellerKey INT NULL,
    EmployeeKey INT NULL,
    PromotionKey INT NOT NULL,
    CurrencyKey INT NOT NULL,
    SalesTerritoryKey INT NOT NULL,
    RevisionNumber TINYINT NOT NULL DEFAULT 1,
    OrderQuantity SMALLINT NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    ExtendedAmount DECIMAL(19,4) NOT NULL,
    UnitPriceDiscountPct DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    DiscountAmount DECIMAL(19,4) NOT NULL DEFAULT 0.0000,
    ProductStandardCost DECIMAL(19,4) NOT NULL,
    TotalProductCost DECIMAL(19,4) NOT NULL,
    SalesAmount DECIMAL(19,4) NOT NULL,
    TaxAmt DECIMAL(19,4) NOT NULL,
    Freight DECIMAL(19,4) NOT NULL,
    CarrierTrackingNumber VARCHAR(25) NULL,
    CustomerPONumber VARCHAR(25) NULL,
    OrderDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    ShipDate DATETIME NOT NULL,
    PRIMARY KEY (channel, SalesOrderNumber, SalesOrderLineNumber),
    KEY idx_fsl_order_date (OrderDateKey),
    KEY idx_fsl_product (ProductKey),
    KEY idx_fsl_customer (CustomerKey),
    KEY idx_fsl_reseller (ResellerKey),
    KEY idx_fsl_territory (SalesTerritoryKey),
    CONSTRAINT chk_channel_keys CHECK (
        (channel = 'Internet' AND CustomerKey IS NOT NULL AND ResellerKey IS NULL) OR
        (channel = 'Reseller' AND CustomerKey IS NULL AND ResellerKey IS NOT NULL)
    ),
    CONSTRAINT fk_fsl_product FOREIGN KEY (ProductKey) REFERENCES dim_product (ProductKey),
    CONSTRAINT fk_fsl_order_date FOREIGN KEY (OrderDateKey) REFERENCES dim_date (DateKey),
    CONSTRAINT fk_fsl_territory FOREIGN KEY (SalesTerritoryKey) REFERENCES dim_sales_territory (SalesTerritoryKey),
    CONSTRAINT fk_fsl_promotion FOREIGN KEY (PromotionKey) REFERENCES dim_promotion (PromotionKey),
    CONSTRAINT fk_fsl_currency FOREIGN KEY (CurrencyKey) REFERENCES dim_currency (CurrencyKey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks = 1;
