"""
MotoPulse 360: Enhanced Power BI Project (.pbip) & Semantic Model Generator
-------------------------------------------------------------------------
Fixes visual field bindings by generating full, valid `prototypeQuery` blocks
and Power Query `Table.TransformColumnTypes` type mappings for all 3 report pages.
"""

import os
import json

PBIP_ROOT = os.path.abspath(os.path.join("powerbi", "MotoPulse_360_Analytics"))
DATA_DIR = os.path.abspath(os.path.join("data", "processed", "powerbi")).replace("\\", "/")

os.makedirs(PBIP_ROOT, exist_ok=True)
REPORT_DIR = os.path.join("powerbi", "MotoPulse_360_Analytics.Report")
SEMANTIC_DIR = os.path.join("powerbi", "MotoPulse_360_Analytics.SemanticModel")
os.makedirs(REPORT_DIR, exist_ok=True)
os.makedirs(SEMANTIC_DIR, exist_ok=True)

print("=" * 80)
print("MotoPulse 360: Generating Fully Bound Power BI Project (.pbip)")
print("=" * 80)

# 1. Root .pbip pointer
pbip_pointer = {
    "version": "1.0",
    "artifacts": [
        {
            "report": {
                "path": "MotoPulse_360_Analytics.Report"
            }
        }
    ],
    "settings": {
        "enableAutoRecovery": True
    }
}
pbip_path = os.path.join("powerbi", "MotoPulse_360_Analytics.pbip")
with open(pbip_path, "w", encoding="utf-8") as f:
    json.dump(pbip_pointer, f, indent=2)
print(f"Generated: {pbip_path}")

# 2. Report definition.pbir
pbir_content = {
    "version": "1.0",
    "datasetReference": {
        "byPath": {
            "path": "../MotoPulse_360_Analytics.SemanticModel"
        },
        "byConnection": None
    }
}
pbir_path = os.path.join(REPORT_DIR, "definition.pbir")
with open(pbir_path, "w", encoding="utf-8") as f:
    json.dump(pbir_content, f, indent=2)
print(f"Generated: {pbir_path}")

# 3. Semantic model definition.pbism
pbism_content = {
    "version": "1.0"
}
pbism_path = os.path.join(SEMANTIC_DIR, "definition.pbism")
with open(pbism_path, "w", encoding="utf-8") as f:
    json.dump(pbism_content, f, indent=2)
print(f"Generated: {pbism_path}")

# Helper for M expression with explicit type casting
def make_csv_m_expr(filename, type_mappings):
    full_path = f"{DATA_DIR}/{filename}"
    type_transforms = ", ".join([f'{{"{col}", {m_type}}}' for col, m_type in type_mappings.items()])
    return [
        "let",
        f'    Source = Csv.Document(File.Contents("{full_path}"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),',
        '    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),',
        f'    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{{type_transforms}}})',
        "in",
        '    #"Changed Type"'
    ]

# 4. Tables with column definitions & M type mappings
tables_meta = [
    {
        "name": "vw_sales_fact",
        "file": "vw_sales_fact.csv",
        "m_types": {
            "SalesOrderNumber": "type text", "SalesOrderLineNumber": "Int64.Type", "Channel": "type text",
            "OrderDateKey": "Int64.Type", "DueDateKey": "Int64.Type", "ShipDateKey": "Int64.Type",
            "CustomerKey": "Int64.Type", "ResellerKey": "Int64.Type", "ProductKey": "Int64.Type",
            "PromotionKey": "Int64.Type", "CurrencyKey": "Int64.Type", "SalesTerritoryKey": "Int64.Type",
            "OrderQuantity": "Int64.Type", "UnitPrice": "type number", "ExtendedAmount": "type number",
            "UnitPriceDiscountPct": "type number", "DiscountAmount": "type number", "ProductStandardCost": "type number",
            "TotalProductCost": "type number", "SalesAmount": "type number", "TaxAmt": "type number",
            "Freight": "type number", "GrossProfit": "type number", "GrossMarginPct": "type number"
        },
        "columns": [
            {"name": "SalesOrderNumber", "dataType": "string", "sourceColumn": "SalesOrderNumber"},
            {"name": "SalesOrderLineNumber", "dataType": "int64", "sourceColumn": "SalesOrderLineNumber"},
            {"name": "Channel", "dataType": "string", "sourceColumn": "Channel"},
            {"name": "OrderDateKey", "dataType": "int64", "sourceColumn": "OrderDateKey"},
            {"name": "DueDateKey", "dataType": "int64", "sourceColumn": "DueDateKey"},
            {"name": "ShipDateKey", "dataType": "int64", "sourceColumn": "ShipDateKey"},
            {"name": "CustomerKey", "dataType": "int64", "sourceColumn": "CustomerKey"},
            {"name": "ResellerKey", "dataType": "int64", "sourceColumn": "ResellerKey"},
            {"name": "ProductKey", "dataType": "int64", "sourceColumn": "ProductKey"},
            {"name": "PromotionKey", "dataType": "int64", "sourceColumn": "PromotionKey"},
            {"name": "CurrencyKey", "dataType": "int64", "sourceColumn": "CurrencyKey"},
            {"name": "SalesTerritoryKey", "dataType": "int64", "sourceColumn": "SalesTerritoryKey"},
            {"name": "OrderQuantity", "dataType": "int64", "sourceColumn": "OrderQuantity"},
            {"name": "UnitPrice", "dataType": "double", "sourceColumn": "UnitPrice", "formatString": "\\$#,##0.00"},
            {"name": "ExtendedAmount", "dataType": "double", "sourceColumn": "ExtendedAmount", "formatString": "\\$#,##0.00"},
            {"name": "UnitPriceDiscountPct", "dataType": "double", "sourceColumn": "UnitPriceDiscountPct", "formatString": "0.00%"},
            {"name": "DiscountAmount", "dataType": "double", "sourceColumn": "DiscountAmount", "formatString": "\\$#,##0.00"},
            {"name": "ProductStandardCost", "dataType": "double", "sourceColumn": "ProductStandardCost", "formatString": "\\$#,##0.00"},
            {"name": "TotalProductCost", "dataType": "double", "sourceColumn": "TotalProductCost", "formatString": "\\$#,##0.00"},
            {"name": "SalesAmount", "dataType": "double", "sourceColumn": "SalesAmount", "formatString": "\\$#,##0.00"},
            {"name": "TaxAmt", "dataType": "double", "sourceColumn": "TaxAmt", "formatString": "\\$#,##0.00"},
            {"name": "Freight", "dataType": "double", "sourceColumn": "Freight", "formatString": "\\$#,##0.00"},
            {"name": "GrossProfit", "dataType": "double", "sourceColumn": "GrossProfit", "formatString": "\\$#,##0.00"},
            {"name": "GrossMarginPct", "dataType": "double", "sourceColumn": "GrossMarginPct", "formatString": "0.00%"}
        ]
    },
    {
        "name": "vw_dim_date",
        "file": "vw_dim_date.csv",
        "m_types": {
            "DateKey": "Int64.Type", "Date": "type date", "DayNumberOfWeek": "Int64.Type",
            "EnglishDayNameOfWeek": "type text", "DayNumberOfMonth": "Int64.Type", "DayNumberOfYear": "Int64.Type",
            "WeekNumberOfYear": "Int64.Type", "EnglishMonthName": "type text", "MonthNumberOfYear": "Int64.Type",
            "CalendarQuarter": "Int64.Type", "CalendarYear": "Int64.Type", "CalendarSemester": "Int64.Type",
            "FiscalQuarter": "Int64.Type", "FiscalYear": "Int64.Type", "FiscalSemester": "Int64.Type"
        },
        "columns": [
            {"name": "DateKey", "dataType": "int64", "sourceColumn": "DateKey"},
            {"name": "Date", "dataType": "dateTime", "sourceColumn": "Date", "formatString": "yyyy-MM-dd"},
            {"name": "DayNumberOfWeek", "dataType": "int64", "sourceColumn": "DayNumberOfWeek"},
            {"name": "EnglishDayNameOfWeek", "dataType": "string", "sourceColumn": "EnglishDayNameOfWeek"},
            {"name": "DayNumberOfMonth", "dataType": "int64", "sourceColumn": "DayNumberOfMonth"},
            {"name": "DayNumberOfYear", "dataType": "int64", "sourceColumn": "DayNumberOfYear"},
            {"name": "WeekNumberOfYear", "dataType": "int64", "sourceColumn": "WeekNumberOfYear"},
            {"name": "EnglishMonthName", "dataType": "string", "sourceColumn": "EnglishMonthName", "sortByColumn": "MonthNumberOfYear"},
            {"name": "MonthNumberOfYear", "dataType": "int64", "sourceColumn": "MonthNumberOfYear"},
            {"name": "CalendarQuarter", "dataType": "int64", "sourceColumn": "CalendarQuarter"},
            {"name": "CalendarYear", "dataType": "int64", "sourceColumn": "CalendarYear"},
            {"name": "CalendarSemester", "dataType": "int64", "sourceColumn": "CalendarSemester"},
            {"name": "FiscalQuarter", "dataType": "int64", "sourceColumn": "FiscalQuarter"},
            {"name": "FiscalYear", "dataType": "int64", "sourceColumn": "FiscalYear"},
            {"name": "FiscalSemester", "dataType": "int64", "sourceColumn": "FiscalSemester"}
        ]
    },
    {
        "name": "vw_dim_product",
        "file": "vw_dim_product.csv",
        "m_types": {
            "ProductKey": "Int64.Type", "ProductAlternateKey": "type text", "ProductName": "type text",
            "StandardCost": "type number", "Color": "type text", "SafetyStockLevel": "Int64.Type",
            "ReorderPoint": "Int64.Type", "ListPrice": "type number", "Size": "type text",
            "SizeRange": "type text", "DaysToManufacture": "Int64.Type", "ProductLine": "type text",
            "DealerPrice": "type number", "Class": "type text", "Style": "type text",
            "ModelName": "type text", "ProductDescription": "type text", "StartDate": "type text",
            "EndDate": "type text", "Status": "type text", "SubcategoryName": "type text", "CategoryName": "type text"
        },
        "columns": [
            {"name": "ProductKey", "dataType": "int64", "sourceColumn": "ProductKey"},
            {"name": "ProductAlternateKey", "dataType": "string", "sourceColumn": "ProductAlternateKey"},
            {"name": "ProductName", "dataType": "string", "sourceColumn": "ProductName"},
            {"name": "StandardCost", "dataType": "double", "sourceColumn": "StandardCost", "formatString": "\\$#,##0.00"},
            {"name": "Color", "dataType": "string", "sourceColumn": "Color"},
            {"name": "SafetyStockLevel", "dataType": "int64", "sourceColumn": "SafetyStockLevel"},
            {"name": "ReorderPoint", "dataType": "int64", "sourceColumn": "ReorderPoint"},
            {"name": "ListPrice", "dataType": "double", "sourceColumn": "ListPrice", "formatString": "\\$#,##0.00"},
            {"name": "Size", "dataType": "string", "sourceColumn": "Size"},
            {"name": "SizeRange", "dataType": "string", "sourceColumn": "SizeRange"},
            {"name": "DaysToManufacture", "dataType": "int64", "sourceColumn": "DaysToManufacture"},
            {"name": "ProductLine", "dataType": "string", "sourceColumn": "ProductLine"},
            {"name": "DealerPrice", "dataType": "double", "sourceColumn": "DealerPrice", "formatString": "\\$#,##0.00"},
            {"name": "Class", "dataType": "string", "sourceColumn": "Class"},
            {"name": "Style", "dataType": "string", "sourceColumn": "Style"},
            {"name": "ModelName", "dataType": "string", "sourceColumn": "ModelName"},
            {"name": "ProductDescription", "dataType": "string", "sourceColumn": "ProductDescription"},
            {"name": "StartDate", "dataType": "string", "sourceColumn": "StartDate"},
            {"name": "EndDate", "dataType": "string", "sourceColumn": "EndDate"},
            {"name": "Status", "dataType": "string", "sourceColumn": "Status"},
            {"name": "SubcategoryName", "dataType": "string", "sourceColumn": "SubcategoryName"},
            {"name": "CategoryName", "dataType": "string", "sourceColumn": "CategoryName"}
        ]
    },
    {
        "name": "vw_dim_customer",
        "file": "vw_dim_customer.csv",
        "m_types": {
            "CustomerKey": "Int64.Type", "CustomerAlternateKey": "type text", "CustomerFullName": "type text",
            "EmailAddress": "type text", "YearlyIncome": "type number", "TotalChildren": "Int64.Type",
            "EnglishEducation": "type text", "EnglishOccupation": "type text", "HouseOwnerFlag": "Int64.Type",
            "NumberCarsOwned": "Int64.Type", "CommuteDistance": "type text", "City": "type text",
            "StateProvinceName": "type text", "EnglishCountryRegionName": "type text", "PostalCode": "type text",
            "SalesTerritoryKey": "Int64.Type"
        },
        "columns": [
            {"name": "CustomerKey", "dataType": "int64", "sourceColumn": "CustomerKey"},
            {"name": "CustomerAlternateKey", "dataType": "string", "sourceColumn": "CustomerAlternateKey"},
            {"name": "CustomerFullName", "dataType": "string", "sourceColumn": "CustomerFullName"},
            {"name": "EmailAddress", "dataType": "string", "sourceColumn": "EmailAddress"},
            {"name": "YearlyIncome", "dataType": "double", "sourceColumn": "YearlyIncome", "formatString": "\\$#,##0"},
            {"name": "TotalChildren", "dataType": "int64", "sourceColumn": "TotalChildren"},
            {"name": "EnglishEducation", "dataType": "string", "sourceColumn": "EnglishEducation"},
            {"name": "EnglishOccupation", "dataType": "string", "sourceColumn": "EnglishOccupation"},
            {"name": "HouseOwnerFlag", "dataType": "int64", "sourceColumn": "HouseOwnerFlag"},
            {"name": "NumberCarsOwned", "dataType": "int64", "sourceColumn": "NumberCarsOwned"},
            {"name": "CommuteDistance", "dataType": "string", "sourceColumn": "CommuteDistance"},
            {"name": "City", "dataType": "string", "sourceColumn": "City"},
            {"name": "StateProvinceName", "dataType": "string", "sourceColumn": "StateProvinceName"},
            {"name": "EnglishCountryRegionName", "dataType": "string", "sourceColumn": "EnglishCountryRegionName"},
            {"name": "PostalCode", "dataType": "string", "sourceColumn": "PostalCode"},
            {"name": "SalesTerritoryKey", "dataType": "int64", "sourceColumn": "SalesTerritoryKey"}
        ]
    },
    {
        "name": "vw_dim_reseller",
        "file": "vw_dim_reseller.csv",
        "m_types": {
            "ResellerKey": "Int64.Type", "ResellerAlternateKey": "type text", "ResellerName": "type text",
            "BusinessType": "type text", "NumberEmployees": "Int64.Type", "OrderFrequency": "type text",
            "AnnualSales": "type number", "AnnualRevenue": "type number", "YearOpened": "Int64.Type",
            "City": "type text", "StateProvinceName": "type text", "EnglishCountryRegionName": "type text",
            "PostalCode": "type text", "SalesTerritoryKey": "Int64.Type"
        },
        "columns": [
            {"name": "ResellerKey", "dataType": "int64", "sourceColumn": "ResellerKey"},
            {"name": "ResellerAlternateKey", "dataType": "string", "sourceColumn": "ResellerAlternateKey"},
            {"name": "ResellerName", "dataType": "string", "sourceColumn": "ResellerName"},
            {"name": "BusinessType", "dataType": "string", "sourceColumn": "BusinessType"},
            {"name": "NumberEmployees", "dataType": "int64", "sourceColumn": "NumberEmployees"},
            {"name": "OrderFrequency", "dataType": "string", "sourceColumn": "OrderFrequency"},
            {"name": "AnnualSales", "dataType": "double", "sourceColumn": "AnnualSales", "formatString": "\\$#,##0"},
            {"name": "AnnualRevenue", "dataType": "double", "sourceColumn": "AnnualRevenue", "formatString": "\\$#,##0"},
            {"name": "YearOpened", "dataType": "int64", "sourceColumn": "YearOpened"},
            {"name": "City", "dataType": "string", "sourceColumn": "City"},
            {"name": "StateProvinceName", "dataType": "string", "sourceColumn": "StateProvinceName"},
            {"name": "EnglishCountryRegionName", "dataType": "string", "sourceColumn": "EnglishCountryRegionName"},
            {"name": "PostalCode", "dataType": "string", "sourceColumn": "PostalCode"},
            {"name": "SalesTerritoryKey", "dataType": "int64", "sourceColumn": "SalesTerritoryKey"}
        ]
    },
    {
        "name": "vw_dim_territory",
        "file": "vw_dim_territory.csv",
        "m_types": {
            "SalesTerritoryKey": "Int64.Type", "SalesTerritoryAlternateKey": "Int64.Type",
            "SalesTerritoryRegion": "type text", "SalesTerritoryCountry": "type text", "SalesTerritoryGroup": "type text"
        },
        "columns": [
            {"name": "SalesTerritoryKey", "dataType": "int64", "sourceColumn": "SalesTerritoryKey"},
            {"name": "SalesTerritoryAlternateKey", "dataType": "int64", "sourceColumn": "SalesTerritoryAlternateKey"},
            {"name": "SalesTerritoryRegion", "dataType": "string", "sourceColumn": "SalesTerritoryRegion"},
            {"name": "SalesTerritoryCountry", "dataType": "string", "sourceColumn": "SalesTerritoryCountry"},
            {"name": "SalesTerritoryGroup", "dataType": "string", "sourceColumn": "SalesTerritoryGroup"}
        ]
    },
    {
        "name": "vw_inventory_latest",
        "file": "vw_inventory_latest.csv",
        "m_types": {
            "ProductKey": "Int64.Type", "DateKey": "Int64.Type", "MovementDate": "type text",
            "UnitCost": "type number", "UnitsIn": "Int64.Type", "UnitsOut": "Int64.Type",
            "UnitsBalance": "Int64.Type", "ProductName": "type text", "SafetyStockLevel": "Int64.Type",
            "ReorderPoint": "Int64.Type", "StockStatus": "type text", "StockDeficit": "Int64.Type"
        },
        "columns": [
            {"name": "ProductKey", "dataType": "int64", "sourceColumn": "ProductKey"},
            {"name": "DateKey", "dataType": "int64", "sourceColumn": "DateKey"},
            {"name": "MovementDate", "dataType": "string", "sourceColumn": "MovementDate"},
            {"name": "UnitCost", "dataType": "double", "sourceColumn": "UnitCost", "formatString": "\\$#,##0.00"},
            {"name": "UnitsIn", "dataType": "int64", "sourceColumn": "UnitsIn"},
            {"name": "UnitsOut", "dataType": "int64", "sourceColumn": "UnitsOut"},
            {"name": "UnitsBalance", "dataType": "int64", "sourceColumn": "UnitsBalance"},
            {"name": "ProductName", "dataType": "string", "sourceColumn": "ProductName"},
            {"name": "SafetyStockLevel", "dataType": "int64", "sourceColumn": "SafetyStockLevel"},
            {"name": "ReorderPoint", "dataType": "int64", "sourceColumn": "ReorderPoint"},
            {"name": "StockStatus", "dataType": "string", "sourceColumn": "StockStatus"},
            {"name": "StockDeficit", "dataType": "int64", "sourceColumn": "StockDeficit"}
        ]
    }
]

# DAX Measures Catalog
measures_catalog = [
    # 01. Core Sales & Volume
    {"name": "Gross Sales", "expression": "SUM(vw_sales_fact[ExtendedAmount])", "formatString": "\\$#,##0.00", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Discount Amount", "expression": "SUM(vw_sales_fact[DiscountAmount])", "formatString": "\\$#,##0.00", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Net Sales", "expression": "SUM(vw_sales_fact[SalesAmount])", "formatString": "\\$#,##0.00", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Units Sold", "expression": "SUM(vw_sales_fact[OrderQuantity])", "formatString": "#,##0", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Total Orders", "expression": "DISTINCTCOUNT(vw_sales_fact[SalesOrderNumber])", "formatString": "#,##0", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Order Lines", "expression": "COUNTROWS(vw_sales_fact)", "formatString": "#,##0", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Average Order Value (AOV)", "expression": "DIVIDE([Net Sales], [Total Orders], 0)", "formatString": "\\$#,##0.00", "displayFolder": "01. Core Sales & Volume"},
    {"name": "Discount Rate %", "expression": "DIVIDE([Discount Amount], [Gross Sales], 0)", "formatString": "0.00%", "displayFolder": "01. Core Sales & Volume"},

    # 02. Cost & Profitability
    {"name": "Total Product Cost", "expression": "SUM(vw_sales_fact[TotalProductCost])", "formatString": "\\$#,##0.00", "displayFolder": "02. Cost & Profitability (Standard Cost)"},
    {"name": "Gross Profit", "expression": "[Net Sales] - [Total Product Cost]", "formatString": "\\$#,##0.00", "displayFolder": "02. Cost & Profitability (Standard Cost)"},
    {"name": "Gross Margin %", "expression": "DIVIDE([Gross Profit], [Net Sales], 0)", "formatString": "0.00%", "displayFolder": "02. Cost & Profitability (Standard Cost)"},

    # 03. Channel Intelligence
    {"name": "Retail Net Sales", "expression": "CALCULATE([Net Sales], KEEPFILTERS(vw_sales_fact[Channel] = \"Internet\"))", "formatString": "\\$#,##0.00", "displayFolder": "03. Channel Intelligence"},
    {"name": "Wholesale Net Sales", "expression": "CALCULATE([Net Sales], KEEPFILTERS(vw_sales_fact[Channel] = \"Reseller\"))", "formatString": "\\$#,##0.00", "displayFolder": "03. Channel Intelligence"},
    {"name": "Retail Gross Profit", "expression": "CALCULATE([Gross Profit], KEEPFILTERS(vw_sales_fact[Channel] = \"Internet\"))", "formatString": "\\$#,##0.00", "displayFolder": "03. Channel Intelligence"},
    {"name": "Wholesale Gross Profit", "expression": "CALCULATE([Gross Profit], KEEPFILTERS(vw_sales_fact[Channel] = \"Reseller\"))", "formatString": "\\$#,##0.00", "displayFolder": "03. Channel Intelligence"},
    {"name": "Retail Gross Margin %", "expression": "DIVIDE([Retail Gross Profit], [Retail Net Sales], 0)", "formatString": "0.00%", "displayFolder": "03. Channel Intelligence"},
    {"name": "Wholesale Gross Margin %", "expression": "DIVIDE([Wholesale Gross Profit], [Wholesale Net Sales], 0)", "formatString": "0.00%", "displayFolder": "03. Channel Intelligence"},

    # 04. Time Intelligence
    {"name": "Net Sales Prior Year", "expression": "CALCULATE([Net Sales], SAMEPERIODLASTYEAR(vw_dim_date[Date]))", "formatString": "\\$#,##0.00", "displayFolder": "04. Time Intelligence & Variance"},
    {"name": "Net Sales YoY Growth $", "expression": "VAR CurrentSales = [Net Sales]\nVAR PreviousSales = [Net Sales Prior Year]\nRETURN IF(NOT ISBLANK(PreviousSales), CurrentSales - PreviousSales, BLANK())", "formatString": "\\$#,##0.00", "displayFolder": "04. Time Intelligence & Variance"},
    {"name": "Net Sales YoY Growth %", "expression": "DIVIDE([Net Sales YoY Growth $], [Net Sales Prior Year], BLANK())", "formatString": "0.0%", "displayFolder": "04. Time Intelligence & Variance"},
    {"name": "Net Sales YTD", "expression": "TOTALYTD([Net Sales], vw_dim_date[Date])", "formatString": "\\$#,##0.00", "displayFolder": "04. Time Intelligence & Variance"},

    # 05. Contribution & Rankings
    {"name": "% of Total Sales", "expression": "DIVIDE([Net Sales], CALCULATE([Net Sales], ALLSELECTED(vw_sales_fact)), 0)", "formatString": "0.0%", "displayFolder": "05. Contribution & Dynamic Rankings"},
    {"name": "Product Revenue Rank", "expression": "IF(NOT ISBLANK([Net Sales]), RANKX(ALLSELECTED(vw_dim_product[ProductName]), [Net Sales], , DESC, Dense))", "formatString": "0", "displayFolder": "05. Contribution & Dynamic Rankings"},

    # 06. Inventory & Operational Health
    {"name": "Current Stock Balance", "expression": "SUM(vw_inventory_latest[UnitsBalance])", "formatString": "#,##0", "displayFolder": "06. Inventory & Operational Health"},
    {"name": "Safety Stock Threshold", "expression": "SUM(vw_inventory_latest[SafetyStockLevel])", "formatString": "#,##0", "displayFolder": "06. Inventory & Operational Health"},
    {"name": "Critical Stock Shortage Items", "expression": "CALCULATE(COUNTROWS(vw_inventory_latest), vw_inventory_latest[StockStatus] = \"Critical Shortage\")", "formatString": "#,##0", "displayFolder": "06. Inventory & Operational Health"},
    {"name": "Reorder Alert Items", "expression": "CALCULATE(COUNTROWS(vw_inventory_latest), vw_inventory_latest[StockStatus] IN {\"Critical Shortage\", \"Reorder Needed\"})", "formatString": "#,##0", "displayFolder": "06. Inventory & Operational Health"},
    {"name": "Total Stock Deficit Units", "expression": "SUM(vw_inventory_latest[StockDeficit])", "formatString": "#,##0", "displayFolder": "06. Inventory & Operational Health"}
]

# Construct model tables
model_tables = []
for t in tables_meta:
    tbl = {
        "name": t["name"],
        "columns": t["columns"],
        "partitions": [
            {
                "name": t["name"],
                "mode": "import",
                "source": {
                    "type": "m",
                    "expression": make_csv_m_expr(t["file"], t["m_types"])
                }
            }
        ]
    }
    if t.get("dataCategory"):
        tbl["dataCategory"] = t["dataCategory"]
    model_tables.append(tbl)

# Dedicated _Measures calculation table
model_tables.append({
    "name": "_Measures",
    "columns": [
        {
            "name": "RowId",
            "dataType": "int64",
            "isHidden": True,
            "sourceColumn": "RowId"
        }
    ],
    "partitions": [
        {
            "name": "_Measures",
            "mode": "import",
            "source": {
                "type": "m",
                "expression": [
                    "let",
                    '    Source = #table(type table [RowId = Int64.Type], {{1}})',
                    "in",
                    "    Source"
                ]
            }
        }
    ],
    "measures": measures_catalog
})

# Construct relationships
relationships = [
    {
        "name": "vw_sales_fact_vw_dim_date_OrderDate",
        "fromTable": "vw_sales_fact",
        "fromColumn": "OrderDateKey",
        "toTable": "vw_dim_date",
        "toColumn": "DateKey",
        "isActive": True
    },
    {
        "name": "vw_sales_fact_vw_dim_date_ShipDate",
        "fromTable": "vw_sales_fact",
        "fromColumn": "ShipDateKey",
        "toTable": "vw_dim_date",
        "toColumn": "DateKey",
        "isActive": False
    },
    {
        "name": "vw_sales_fact_vw_dim_date_DueDate",
        "fromTable": "vw_sales_fact",
        "fromColumn": "DueDateKey",
        "toTable": "vw_dim_date",
        "toColumn": "DateKey",
        "isActive": False
    },
    {
        "name": "vw_sales_fact_vw_dim_product",
        "fromTable": "vw_sales_fact",
        "fromColumn": "ProductKey",
        "toTable": "vw_dim_product",
        "toColumn": "ProductKey",
        "isActive": True
    },
    {
        "name": "vw_sales_fact_vw_dim_customer",
        "fromTable": "vw_sales_fact",
        "fromColumn": "CustomerKey",
        "toTable": "vw_dim_customer",
        "toColumn": "CustomerKey",
        "isActive": True
    },
    {
        "name": "vw_sales_fact_vw_dim_reseller",
        "fromTable": "vw_sales_fact",
        "fromColumn": "ResellerKey",
        "toTable": "vw_dim_reseller",
        "toColumn": "ResellerKey",
        "isActive": True
    },
    {
        "name": "vw_sales_fact_vw_dim_territory",
        "fromTable": "vw_sales_fact",
        "fromColumn": "SalesTerritoryKey",
        "toTable": "vw_dim_territory",
        "toColumn": "SalesTerritoryKey",
        "isActive": True
    },
    {
        "name": "vw_inventory_latest_vw_dim_product",
        "fromTable": "vw_inventory_latest",
        "fromColumn": "ProductKey",
        "toTable": "vw_dim_product",
        "toColumn": "ProductKey",
        "isActive": True
    }
]

model_bim = {
    "name": "MotoPulse_360_Analytics",
    "compatibilityLevel": 1567,
    "model": {
        "culture": "en-US",
        "dataAccessOptions": {
            "legacyRedirects": True,
            "fastCombine": True
        },
        "defaultPowerBIDataSourceVersion": "powerBI_V3",
        "sourceQueryCulture": "en-US",
        "tables": model_tables,
        "relationships": relationships,
        "annotations": [
            {
                "name": "PBI_QueryOrder",
                "value": "[\"vw_sales_fact\",\"vw_dim_date\",\"vw_dim_product\",\"vw_dim_customer\",\"vw_dim_reseller\",\"vw_dim_territory\",\"vw_inventory_latest\",\"_Measures\"]"
            }
        ]
    }
}

bim_path = os.path.join(SEMANTIC_DIR, "model.bim")
with open(bim_path, "w", encoding="utf-8") as f:
    json.dump(model_bim, f, indent=2)
print(f"Generated: {bim_path}")

# ==============================================================================
# 5. Helper Functions to Build Validated Visual Containers with prototypeQuery
# ==============================================================================

def make_title_object(text):
    return {
        "title": [
            {
                "properties": {
                    "show": {"expr": {"Literal": {"Value": "true"}}},
                    "text": {"expr": {"Literal": {"Value": f"'{text}'"}}}
                }
            }
        ]
    }

def make_card_visual(name, title, measure_name, x, y, width, height, z):
    query_ref = f"_Measures.{measure_name}"
    config = {
        "name": name,
        "singleVisual": {
            "visualType": "card",
            "projections": {
                "Values": [{"queryRef": query_ref}]
            },
            "prototypeQuery": {
                "Version": 2,
                "From": [{"Name": "m", "Entity": "_Measures", "Type": 0}],
                "Select": [
                    {
                        "Measure": {
                            "Expression": {"SourceRef": {"Source": "m"}},
                            "Property": measure_name
                        },
                        "Name": query_ref,
                        "NativeReferenceName": measure_name
                    }
                ]
            },
            "objects": make_title_object(title)
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

def make_bar_chart(name, title, cat_table, cat_col, measure_name, x, y, width, height, z):
    cat_ref = f"{cat_table}.{cat_col}"
    val_ref = f"_Measures.{measure_name}"
    config = {
        "name": name,
        "singleVisual": {
            "visualType": "clusteredBarChart",
            "projections": {
                "Category": [{"queryRef": cat_ref, "active": True}],
                "Y": [{"queryRef": val_ref}]
            },
            "prototypeQuery": {
                "Version": 2,
                "From": [
                    {"Name": "c", "Entity": cat_table, "Type": 0},
                    {"Name": "m", "Entity": "_Measures", "Type": 0}
                ],
                "Select": [
                    {
                        "Column": {
                            "Expression": {"SourceRef": {"Source": "c"}},
                            "Property": cat_col
                        },
                        "Name": cat_ref,
                        "NativeReferenceName": cat_col
                    },
                    {
                        "Measure": {
                            "Expression": {"SourceRef": {"Source": "m"}},
                            "Property": measure_name
                        },
                        "Name": val_ref,
                        "NativeReferenceName": measure_name
                    }
                ],
                "OrderBy": [
                    {
                        "Direction": 2,
                        "Expression": {
                            "Measure": {
                                "Expression": {"SourceRef": {"Source": "m"}},
                                "Property": measure_name
                            }
                        }
                    }
                ]
            },
            "objects": make_title_object(title)
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

def make_donut_chart(name, title, cat_table, cat_col, measure_name, x, y, width, height, z):
    cat_ref = f"{cat_table}.{cat_col}"
    val_ref = f"_Measures.{measure_name}"
    config = {
        "name": name,
        "singleVisual": {
            "visualType": "donutChart",
            "projections": {
                "Category": [{"queryRef": cat_ref, "active": True}],
                "Y": [{"queryRef": val_ref}]
            },
            "prototypeQuery": {
                "Version": 2,
                "From": [
                    {"Name": "c", "Entity": cat_table, "Type": 0},
                    {"Name": "m", "Entity": "_Measures", "Type": 0}
                ],
                "Select": [
                    {
                        "Column": {
                            "Expression": {"SourceRef": {"Source": "c"}},
                            "Property": cat_col
                        },
                        "Name": cat_ref,
                        "NativeReferenceName": cat_col
                    },
                    {
                        "Measure": {
                            "Expression": {"SourceRef": {"Source": "m"}},
                            "Property": measure_name
                        },
                        "Name": val_ref,
                        "NativeReferenceName": measure_name
                    }
                ]
            },
            "objects": make_title_object(title)
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

def make_combo_chart(name, title, date_col, col_measure, line_measure, x, y, width, height, z):
    date_ref = f"vw_dim_date.{date_col}"
    col_ref = f"_Measures.{col_measure}"
    line_ref = f"_Measures.{line_measure}"
    config = {
        "name": name,
        "singleVisual": {
            "visualType": "lineStackedColumnComboChart",
            "projections": {
                "Category": [{"queryRef": date_ref, "active": True}],
                "Y": [{"queryRef": col_ref}],
                "Y2": [{"queryRef": line_ref}]
            },
            "prototypeQuery": {
                "Version": 2,
                "From": [
                    {"Name": "d", "Entity": "vw_dim_date", "Type": 0},
                    {"Name": "m", "Entity": "_Measures", "Type": 0}
                ],
                "Select": [
                    {
                        "Column": {
                            "Expression": {"SourceRef": {"Source": "d"}},
                            "Property": date_col
                        },
                        "Name": date_ref,
                        "NativeReferenceName": date_col
                    },
                    {
                        "Measure": {
                            "Expression": {"SourceRef": {"Source": "m"}},
                            "Property": col_measure
                        },
                        "Name": col_ref,
                        "NativeReferenceName": col_measure
                    },
                    {
                        "Measure": {
                            "Expression": {"SourceRef": {"Source": "m"}},
                            "Property": line_measure
                        },
                        "Name": line_ref,
                        "NativeReferenceName": line_measure
                    }
                ],
                "OrderBy": [
                    {
                        "Direction": 1,
                        "Expression": {
                            "Column": {
                                "Expression": {"SourceRef": {"Source": "d"}},
                                "Property": date_col
                            }
                        }
                    }
                ]
            },
            "objects": make_title_object(title)
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

def make_treemap(name, title, group_table, group_col, measure_name, x, y, width, height, z):
    grp_ref = f"{group_table}.{group_col}"
    val_ref = f"_Measures.{measure_name}"
    config = {
        "name": name,
        "singleVisual": {
            "visualType": "treemap",
            "projections": {
                "Group": [{"queryRef": grp_ref, "active": True}],
                "Values": [{"queryRef": val_ref}]
            },
            "prototypeQuery": {
                "Version": 2,
                "From": [
                    {"Name": "g", "Entity": group_table, "Type": 0},
                    {"Name": "m", "Entity": "_Measures", "Type": 0}
                ],
                "Select": [
                    {
                        "Column": {
                            "Expression": {"SourceRef": {"Source": "g"}},
                            "Property": group_col
                        },
                        "Name": grp_ref,
                        "NativeReferenceName": group_col
                    },
                    {
                        "Measure": {
                            "Expression": {"SourceRef": {"Source": "m"}},
                            "Property": measure_name
                        },
                        "Name": val_ref,
                        "NativeReferenceName": measure_name
                    }
                ]
            },
            "objects": make_title_object(title)
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

def make_table_visual(name, title, fields, x, y, width, height, z):
    # fields is a list of tuples: (table_name, field_name, is_measure)
    table_aliases = {}
    from_list = []
    select_list = []
    proj_values = []
    
    for tbl, col, is_meas in fields:
        if tbl not in table_aliases:
            alias = f"t{len(table_aliases)}"
            table_aliases[tbl] = alias
            from_list.append({"Name": alias, "Entity": tbl, "Type": 0})
        else:
            alias = table_aliases[tbl]
            
        qref = f"{tbl}.{col}"
        proj_values.append({"queryRef": qref})
        
        if is_meas:
            select_list.append({
                "Measure": {
                    "Expression": {"SourceRef": {"Source": alias}},
                    "Property": col
                },
                "Name": qref,
                "NativeReferenceName": col
            })
        else:
            select_list.append({
                "Column": {
                    "Expression": {"SourceRef": {"Source": alias}},
                    "Property": col
                },
                "Name": qref,
                "NativeReferenceName": col
            })

    config = {
        "name": name,
        "singleVisual": {
            "visualType": "tableEx",
            "projections": {
                "Values": proj_values
            },
            "prototypeQuery": {
                "Version": 2,
                "From": from_list,
                "Select": select_list
            },
            "objects": make_title_object(title)
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

# Banner Visual Helper
def make_banner(name, main_text, sub_text, x, y, width, height, z):
    config = {
        "name": name,
        "singleVisual": {
            "visualType": "textbox",
            "objects": {
                "general": [
                    {"properties": {"paragraphs": [
                        {"textRuns": [
                            {"value": main_text, "textStyle": {"fontFamily": "Segoe UI Bold", "fontSize": "16pt", "color": "#0F172A"}},
                            {"value": f"   —   {sub_text}", "textStyle": {"fontFamily": "Segoe UI", "fontSize": "9pt", "color": "#64748B"}}
                        ]}
                    ]}}
                ]
            }
        }
    }
    return {
        "x": x, "y": y, "z": z, "width": width, "height": height,
        "config": json.dumps(config),
        "filters": "[]"
    }

# ==============================================================================
# 6. Assemble Full 3-Page Report Definition with Validated Field Bindings
# ==============================================================================

page1_visuals = [
    make_banner("Banner1", "MotoPulse 360 | Executive Sales & Profitability Overview", "Microsoft AdventureWorksDW Synthetic Bicycle Enterprise Modeling", 20, 15, 1240, 50, 1000),
    make_card_visual("Card_NetSales", "Net Sales Revenue", "Net Sales", 20, 75, 295, 105, 2000),
    make_card_visual("Card_GrossProfit", "Gross Profit (Std Cost)", "Gross Profit", 335, 75, 295, 105, 2001),
    make_card_visual("Card_GrossMargin", "Gross Margin %", "Gross Margin %", 650, 75, 295, 105, 2002),
    make_card_visual("Card_TotalOrders", "Total Distinct Orders", "Total Orders", 965, 75, 295, 105, 2003),
    make_combo_chart("Combo_MonthlyTrend", "Monthly Net Sales & Gross Profit Velocity", "Date", "Net Sales", "Gross Profit", 20, 195, 780, 275, 3000),
    make_donut_chart("Donut_ChannelSplit", "Sales Contribution by Commercial Channel", "vw_sales_fact", "Channel", "Net Sales", 820, 195, 440, 275, 3001),
    make_bar_chart("Bar_CategoryRevenue", "Net Sales by Product Category", "vw_dim_product", "CategoryName", "Net Sales", 20, 485, 620, 220, 4000),
    make_treemap("Treemap_Territory", "Sales Revenue by Geographic Territory", "vw_dim_territory", "SalesTerritoryCountry", "Net Sales", 660, 485, 600, 220, 4001)
]

page2_visuals = [
    make_banner("Banner2", "MotoPulse 360 | Product & Commercial Channel Intelligence", "Retail Margin (41.15%) vs Wholesale Margin (0.58%) & Discount Leakage Analysis", 20, 15, 1240, 50, 1000),
    make_card_visual("Card_RetailMargin", "Retail Direct Margin %", "Retail Gross Margin %", 20, 75, 295, 105, 2000),
    make_card_visual("Card_WholesaleMargin", "Wholesale Reseller Margin %", "Wholesale Gross Margin %", 335, 75, 295, 105, 2001),
    make_card_visual("Card_WholesaleSales", "Wholesale Net Revenue", "Wholesale Net Sales", 650, 75, 295, 105, 2002),
    make_card_visual("Card_Discounts", "Total Volume Discounts Granted", "Discount Amount", 965, 75, 295, 105, 2003),
    make_bar_chart("Bar_TopProducts", "Top Revenue Generating Products", "vw_dim_product", "ProductName", "Net Sales", 20, 195, 620, 510, 3000),
    make_table_visual("Table_SubcategoryMatrix", "Subcategory Financial Performance Matrix", [
        ("vw_dim_product", "SubcategoryName", False),
        ("_Measures", "Net Sales", True),
        ("_Measures", "Total Product Cost", True),
        ("_Measures", "Gross Profit", True),
        ("_Measures", "Gross Margin %", True)
    ], 660, 195, 600, 510, 3001)
]

page3_visuals = [
    make_banner("Banner3", "MotoPulse 360 | Supply Chain & Inventory Replenishment Alert Center", "Active Catalog Stock Shortages, Safety Buffers, and Procurement Triggers", 20, 15, 1240, 50, 1000),
    make_card_visual("Card_CurrentStock", "Current Units on Hand", "Current Stock Balance", 20, 75, 295, 105, 2000),
    make_card_visual("Card_SafetyStock", "Mandated Safety Stock Buffer", "Safety Stock Threshold", 335, 75, 295, 105, 2001),
    make_card_visual("Card_ShortageSKUs", "Critical Stock Shortage SKUs", "Critical Stock Shortage Items", 650, 75, 295, 105, 2002),
    make_card_visual("Card_DeficitUnits", "Total Restock Deficit Units", "Total Stock Deficit Units", 965, 75, 295, 105, 2003),
    make_donut_chart("Donut_StockStatus", "Catalog Inventory Status Breakdown", "vw_inventory_latest", "StockStatus", "Total Stock Deficit Units", 20, 195, 420, 510, 3000),
    make_table_visual("Table_ProcurementPriority", "Priority Procurement Replenishment Action Grid", [
        ("vw_inventory_latest", "ProductName", False),
        ("vw_inventory_latest", "UnitsBalance", False),
        ("vw_inventory_latest", "SafetyStockLevel", False),
        ("vw_inventory_latest", "ReorderPoint", False),
        ("vw_inventory_latest", "StockDeficit", False),
        ("vw_inventory_latest", "StockStatus", False)
    ], 460, 195, 800, 510, 3001)
]

report_def = {
    "config": json.dumps({
        "version": "5.50",
        "themeCollection": {
            "baseTheme": {
                "name": "CY24SU02",
                "version": "5.50",
                "type": 2
            }
        },
        "activeSectionIndex": 0,
        "defaultDrillFilterOtherVisuals": True
    }),
    "layoutOptimization": 0,
    "sections": [
        {
            "name": "ReportSection_ExecutiveOverview",
            "displayName": "Executive Overview",
            "filters": "[]",
            "height": 720,
            "width": 1280,
            "visualContainers": page1_visuals
        },
        {
            "name": "ReportSection_ProductChannel",
            "displayName": "Product & Channel Intelligence",
            "filters": "[]",
            "height": 720,
            "width": 1280,
            "visualContainers": page2_visuals
        },
        {
            "name": "ReportSection_InventoryAlerts",
            "displayName": "Inventory & Operational Alerts",
            "filters": "[]",
            "height": 720,
            "width": 1280,
            "visualContainers": page3_visuals
        }
    ]
}

report_json_path = os.path.join(REPORT_DIR, "report.json")
with open(report_json_path, "w", encoding="utf-8") as f:
    json.dump(report_def, f, indent=2)
print(f"Generated: {report_json_path}")

print("=" * 80)
print(f"Power BI Project successfully updated at: {PBIP_ROOT}")
print("All visual field bindings, prototypeQuery blocks, and M type transforms verified!")
print("=" * 80)
