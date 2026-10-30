"""
MotoPulse 360 - Stage 4: Convert Raw Files to Clean CSVs.

Purpose
-------
Converts all 15 pipe-delimited, headerless AdventureWorksDW raw CSV files in data/raw/
into clean, comma-delimited, header-containing UTF-8 CSVs in data/processed/clean/.

Strict Integrity Guarantees:
1. Never modifies or deletes files in data/raw/.
2. Assigns exact verified column headers derived from official schema (instawdbdw.sql).
3. Reads and writes all data as raw text without lossy transformations or invented defaults.
4. Verifies that input row count == output row count for every file.
5. Saves a machine-readable conversion log to data/processed/clean_file_conversion_log.csv.

Usage:
    py python/01_convert_raw_to_clean_csv.py
"""

import csv
import os
import sys
import time
from pathlib import Path

import pandas as pd

RAW_DIR = Path("data/raw")
CLEAN_DIR = Path("data/processed/clean")
LOG_PATH = Path("data/processed/clean_file_conversion_log.csv")

# Verified column mappings from official Microsoft AdventureWorksDW schema
TABLE_COLUMNS = {
    "DimDate": [
        "DateKey", "FullDateAlternateKey", "DayNumberOfWeek", "EnglishDayNameOfWeek",
        "SpanishDayNameOfWeek", "FrenchDayNameOfWeek", "DayNumberOfMonth", "DayNumberOfYear",
        "WeekNumberOfYear", "EnglishMonthName", "SpanishMonthName", "FrenchMonthName",
        "MonthNumberOfYear", "CalendarQuarter", "CalendarYear", "CalendarSemester",
        "FiscalQuarter", "FiscalYear", "FiscalSemester"
    ],
    "DimProductCategory": [
        "ProductCategoryKey", "ProductCategoryAlternateKey", "EnglishProductCategoryName",
        "SpanishProductCategoryName", "FrenchProductCategoryName"
    ],
    "DimProductSubcategory": [
        "ProductSubcategoryKey", "ProductSubcategoryAlternateKey", "EnglishProductSubcategoryName",
        "SpanishProductSubcategoryName", "FrenchProductSubcategoryName", "ProductCategoryKey"
    ],
    "DimProduct": [
        "ProductKey", "ProductAlternateKey", "ProductSubcategoryKey", "WeightUnitMeasureCode",
        "SizeUnitMeasureCode", "EnglishProductName", "SpanishProductName", "FrenchProductName",
        "StandardCost", "FinishedGoodsFlag", "Color", "SafetyStockLevel", "ReorderPoint",
        "ListPrice", "Size", "SizeRange", "Weight", "DaysToManufacture", "ProductLine",
        "DealerPrice", "Class", "Style", "ModelName", "LargePhoto", "EnglishDescription",
        "FrenchDescription", "ChineseDescription", "ArabicDescription", "HebrewDescription",
        "ThaiDescription", "GermanDescription", "JapaneseDescription", "TurkishDescription",
        "StartDate", "EndDate", "Status"
    ],
    "DimCustomer": [
        "CustomerKey", "GeographyKey", "CustomerAlternateKey", "Title", "FirstName",
        "MiddleName", "LastName", "NameStyle", "BirthDate", "MaritalStatus", "Suffix",
        "Gender", "EmailAddress", "YearlyIncome", "TotalChildren", "NumberChildrenAtHome",
        "EnglishEducation", "SpanishEducation", "FrenchEducation", "EnglishOccupation",
        "SpanishOccupation", "FrenchOccupation", "HouseOwnerFlag", "NumberCarsOwned",
        "AddressLine1", "AddressLine2", "Phone", "DateFirstPurchase", "CommuteDistance"
    ],
    "DimReseller": [
        "ResellerKey", "GeographyKey", "ResellerAlternateKey", "Phone", "BusinessType",
        "ResellerName", "NumberEmployees", "OrderFrequency", "OrderMonth", "FirstOrderYear",
        "LastOrderYear", "ProductLine", "AddressLine1", "AddressLine2", "AnnualSales",
        "BankName", "MinPaymentType", "MinPaymentAmount", "AnnualRevenue", "YearOpened"
    ],
    "DimSalesTerritory": [
        "SalesTerritoryKey", "SalesTerritoryAlternateKey", "SalesTerritoryRegion",
        "SalesTerritoryCountry", "SalesTerritoryGroup", "SalesTerritoryImage"
    ],
    "DimGeography": [
        "GeographyKey", "City", "StateProvinceCode", "StateProvinceName", "CountryRegionCode",
        "EnglishCountryRegionName", "SpanishCountryRegionName", "FrenchCountryRegionName",
        "PostalCode", "SalesTerritoryKey", "IpAddressLocator"
    ],
    "DimPromotion": [
        "PromotionKey", "PromotionAlternateKey", "EnglishPromotionName", "SpanishPromotionName",
        "FrenchPromotionName", "DiscountPct", "EnglishPromotionType", "SpanishPromotionType",
        "FrenchPromotionType", "EnglishPromotionCategory", "SpanishPromotionCategory",
        "FrenchPromotionCategory", "StartDate", "EndDate", "MinQty", "MaxQty"
    ],
    "DimCurrency": [
        "CurrencyKey", "CurrencyAlternateKey", "CurrencyName"
    ],
    "FactInternetSales": [
        "ProductKey", "OrderDateKey", "DueDateKey", "ShipDateKey", "CustomerKey",
        "PromotionKey", "CurrencyKey", "SalesTerritoryKey", "SalesOrderNumber",
        "SalesOrderLineNumber", "RevisionNumber", "OrderQuantity", "UnitPrice",
        "ExtendedAmount", "UnitPriceDiscountPct", "DiscountAmount", "ProductStandardCost",
        "TotalProductCost", "SalesAmount", "TaxAmt", "Freight", "CarrierTrackingNumber",
        "CustomerPONumber", "OrderDate", "DueDate", "ShipDate"
    ],
    "FactResellerSales": [
        "ProductKey", "OrderDateKey", "DueDateKey", "ShipDateKey", "ResellerKey",
        "EmployeeKey", "PromotionKey", "CurrencyKey", "SalesTerritoryKey",
        "SalesOrderNumber", "SalesOrderLineNumber", "RevisionNumber", "OrderQuantity",
        "UnitPrice", "ExtendedAmount", "UnitPriceDiscountPct", "DiscountAmount",
        "ProductStandardCost", "TotalProductCost", "SalesAmount", "TaxAmt", "Freight",
        "CarrierTrackingNumber", "CustomerPONumber", "OrderDate", "DueDate", "ShipDate"
    ],
    "FactProductInventory": [
        "ProductKey", "DateKey", "MovementDate", "UnitCost", "UnitsIn", "UnitsOut", "UnitsBalance"
    ],
    "FactCurrencyRate": [
        "CurrencyKey", "DateKey", "AverageRate", "EndOfDayRate", "Date"
    ],
    "FactSalesQuota": [
        "SalesQuotaKey", "EmployeeKey", "DateKey", "CalendarYear", "CalendarQuarter",
        "SalesAmountQuota", "Date"
    ]
}


def count_raw_lines(path: Path) -> int:
    """Count lines in raw file using binary buffer to be 100% accurate."""
    with open(path, "rb") as f:
        return sum(1 for _ in f)


def convert_file(table_name: str, cols: list[str]) -> dict:
    raw_path = RAW_DIR / f"{table_name}.csv"
    clean_path = CLEAN_DIR / f"{table_name}.csv"

    if not raw_path.exists():
        return {
            "table": table_name,
            "status": "missing_raw",
            "raw_rows": 0,
            "clean_rows": 0,
            "columns": len(cols),
            "raw_bytes": 0,
            "clean_bytes": 0,
            "duration_sec": 0.0,
            "reconciliation": "FAILED"
        }

    start_time = time.time()
    raw_bytes = raw_path.stat().st_size
    expected_rows = count_raw_lines(raw_path)

    # Read raw pipe-delimited file as pure strings (no NaN substitution)
    df = pd.read_csv(
        raw_path,
        sep="|",
        header=None,
        names=cols,
        dtype=str,
        keep_default_na=False,
        encoding="utf-8",
        engine="c"
    )

    actual_raw_rows = len(df)
    if actual_raw_rows != expected_rows:
        raise ValueError(
            f"{table_name}: Line count mismatch! Raw lines={expected_rows}, parsed rows={actual_raw_rows}"
        )

    # Write clean comma-delimited CSV with headers and minimal quoting
    df.to_csv(
        clean_path,
        sep=",",
        header=True,
        index=False,
        encoding="utf-8",
        quoting=csv.QUOTE_MINIMAL
    )

    clean_bytes = clean_path.stat().st_size
    duration = round(time.time() - start_time, 2)

    # Verify output file lines = data rows + 1 header row
    clean_lines = count_raw_lines(clean_path)
    if clean_lines != actual_raw_rows + 1:
        raise ValueError(
            f"{table_name}: Clean file line count mismatch! Expected {actual_raw_rows + 1}, got {clean_lines}"
        )

    return {
        "table": table_name,
        "status": "success",
        "raw_rows": actual_raw_rows,
        "clean_rows": actual_raw_rows,
        "columns": len(cols),
        "raw_bytes": raw_bytes,
        "clean_bytes": clean_bytes,
        "duration_sec": duration,
        "reconciliation": "MATCH" if actual_raw_rows == expected_rows else "MISMATCH"
    }


def main():
    if not RAW_DIR.exists():
        print(f"ERROR: {RAW_DIR} does not exist. Run from project root.")
        sys.exit(1)

    CLEAN_DIR.mkdir(parents=True, exist_ok=True)
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

    print("=" * 80)
    print("MotoPulse 360: Converting Raw Pipe-Delimited CSVs to Clean Comma-Delimited CSVs")
    print(f"Source: {RAW_DIR} -> Destination: {CLEAN_DIR}")
    print("=" * 80)

    log_entries = []
    total_raw_rows = 0
    total_clean_rows = 0

    for table_name, cols in TABLE_COLUMNS.items():
        print(f"Processing {table_name:25} ({len(cols):2} cols)...", end=" ", flush=True)
        res = convert_file(table_name, cols)
        log_entries.append(res)
        total_raw_rows += res["raw_rows"]
        total_clean_rows += res["clean_rows"]
        print(f"OK: {res['clean_rows']:,} rows ({res['clean_bytes'] / (1024*1024):.2f} MB) in {res['duration_sec']}s")

    # Save log
    log_df = pd.DataFrame(log_entries)
    log_df.to_csv(LOG_PATH, index=False)

    print("=" * 80)
    print(f"Conversion Complete!")
    print(f"Total Tables Converted: {len(log_entries)}")
    print(f"Total Raw Rows Processed:   {total_raw_rows:,}")
    print(f"Total Clean Rows Generated: {total_clean_rows:,}")
    print(f"Reconciliation Match:       {total_raw_rows == total_clean_rows and all(r['reconciliation'] == 'MATCH' for r in log_entries)}")
    print(f"Audit Log Written to:       {LOG_PATH}")
    print("=" * 80)


if __name__ == "__main__":
    main()
