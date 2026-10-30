"""
MotoPulse 360: Power BI Dataset Export Utility
---------------------------------------------
Generates clean, pre-modeled dimensional CSV datasets optimized for Power BI Desktop.
This utility enables instant Power BI model creation without requiring a live MySQL server.

Datasets exported:
1. vw_sales_fact.csv          - 121,253 transaction lines (stacked Retail + Wholesale)
2. vw_dim_date.csv            - Standardized calendar dimension
3. vw_dim_product.csv         - Product hierarchy (Product -> Subcategory -> Category)
4. vw_dim_customer.csv        - Retail individual consumers with geography
5. vw_dim_reseller.csv        - Commercial wholesale partners with geography
6. vw_dim_territory.csv       - Sales territories (Region, Country, Group)
7. vw_inventory_latest.csv    - Latest product inventory snapshot with replenishment signals
8. vw_monthly_channel_kpis.csv- Pre-aggregated monthly financial benchmarks
"""

import os
import pandas as pd
import numpy as np

CLEAN_DIR = os.path.join("data", "processed", "clean")
OUTPUT_DIR = os.path.join("data", "processed", "powerbi")
os.makedirs(OUTPUT_DIR, exist_ok=True)

print("=" * 80)
print("MotoPulse 360: Exporting Datasets for Power BI Desktop")
print("=" * 80)

# 1. DimDate
print("Exporting DimDate...")
dim_date = pd.read_csv(os.path.join(CLEAN_DIR, "DimDate.csv"))
date_cols = [
    "DateKey", "FullDateAlternateKey", "DayNumberOfWeek", "EnglishDayNameOfWeek",
    "DayNumberOfMonth", "DayNumberOfYear", "WeekNumberOfYear", "EnglishMonthName",
    "MonthNumberOfYear", "CalendarQuarter", "CalendarYear", "CalendarSemester",
    "FiscalQuarter", "FiscalYear", "FiscalSemester"
]
dim_date_export = dim_date[date_cols].copy()
dim_date_export.rename(columns={"FullDateAlternateKey": "Date"}, inplace=True)
dim_date_export.to_csv(os.path.join(OUTPUT_DIR, "vw_dim_date.csv"), index=False)
print(f" -> vw_dim_date.csv: {len(dim_date_export):,} rows")

# 2. DimSalesTerritory
print("Exporting DimSalesTerritory...")
dim_terr = pd.read_csv(os.path.join(CLEAN_DIR, "DimSalesTerritory.csv"))
terr_cols = [
    "SalesTerritoryKey", "SalesTerritoryAlternateKey", "SalesTerritoryRegion",
    "SalesTerritoryCountry", "SalesTerritoryGroup"
]
dim_terr_export = dim_terr[terr_cols].copy()
dim_terr_export.to_csv(os.path.join(OUTPUT_DIR, "vw_dim_territory.csv"), index=False)
print(f" -> vw_dim_territory.csv: {len(dim_terr_export):,} rows")

# 3. DimGeography (helper for Customer & Reseller)
dim_geo = pd.read_csv(os.path.join(CLEAN_DIR, "DimGeography.csv"))
geo_cols_to_merge = ["GeographyKey", "City", "StateProvinceName", "EnglishCountryRegionName", "PostalCode", "SalesTerritoryKey"]

# 4. DimCustomer
print("Exporting DimCustomer (enriched with Geography)...")
dim_cust = pd.read_csv(os.path.join(CLEAN_DIR, "DimCustomer.csv"))
cust_merged = dim_cust.merge(
    dim_geo[geo_cols_to_merge],
    on="GeographyKey",
    how="left"
)
cust_merged["CustomerFullName"] = cust_merged["FirstName"].fillna("") + " " + cust_merged["LastName"].fillna("")
cust_merged["CustomerFullName"] = cust_merged["CustomerFullName"].str.strip()
cust_cols = [
    "CustomerKey", "CustomerAlternateKey", "CustomerFullName", "EmailAddress",
    "YearlyIncome", "TotalChildren", "EnglishEducation", "EnglishOccupation",
    "HouseOwnerFlag", "NumberCarsOwned", "CommuteDistance", "City",
    "StateProvinceName", "EnglishCountryRegionName", "PostalCode", "SalesTerritoryKey"
]
dim_cust_export = cust_merged[cust_cols].copy()
dim_cust_export.to_csv(os.path.join(OUTPUT_DIR, "vw_dim_customer.csv"), index=False)
print(f" -> vw_dim_customer.csv: {len(dim_cust_export):,} rows")

# 5. DimReseller
print("Exporting DimReseller (enriched with Geography)...")
dim_reseller = pd.read_csv(os.path.join(CLEAN_DIR, "DimReseller.csv"))
reseller_merged = dim_reseller.merge(
    dim_geo[geo_cols_to_merge],
    on="GeographyKey",
    how="left"
)
reseller_cols = [
    "ResellerKey", "ResellerAlternateKey", "ResellerName", "BusinessType",
    "NumberEmployees", "OrderFrequency", "AnnualSales", "AnnualRevenue",
    "YearOpened", "City", "StateProvinceName", "EnglishCountryRegionName", "PostalCode", "SalesTerritoryKey"
]
dim_reseller_export = reseller_merged[reseller_cols].copy()
dim_reseller_export.to_csv(os.path.join(OUTPUT_DIR, "vw_dim_reseller.csv"), index=False)
print(f" -> vw_dim_reseller.csv: {len(dim_reseller_export):,} rows")

# 6. DimProduct (Enriched Hierarchy)
print("Exporting DimProduct (enriched with Subcategory and Category)...")
dim_prod = pd.read_csv(os.path.join(CLEAN_DIR, "DimProduct.csv"))
dim_subcat = pd.read_csv(os.path.join(CLEAN_DIR, "DimProductSubcategory.csv"))
dim_cat = pd.read_csv(os.path.join(CLEAN_DIR, "DimProductCategory.csv"))

sub_cat = dim_subcat.merge(dim_cat, on="ProductCategoryKey", how="left")
prod_hierarchy = dim_prod.merge(sub_cat, on="ProductSubcategoryKey", how="left")

prod_cols = [
    "ProductKey", "ProductAlternateKey", "EnglishProductName", "StandardCost",
    "Color", "SafetyStockLevel", "ReorderPoint", "ListPrice", "Size",
    "SizeRange", "DaysToManufacture", "ProductLine", "DealerPrice", "Class",
    "Style", "ModelName", "EnglishDescription", "StartDate", "EndDate", "Status",
    "EnglishProductSubcategoryName", "EnglishProductCategoryName"
]
dim_prod_export = prod_hierarchy[prod_cols].copy()
dim_prod_export.rename(columns={
    "EnglishProductName": "ProductName",
    "EnglishProductSubcategoryName": "SubcategoryName",
    "EnglishProductCategoryName": "CategoryName",
    "EnglishDescription": "ProductDescription"
}, inplace=True)
dim_prod_export["CategoryName"] = dim_prod_export["CategoryName"].fillna("Unassigned")
dim_prod_export["SubcategoryName"] = dim_prod_export["SubcategoryName"].fillna("Unassigned")
dim_prod_export.to_csv(os.path.join(OUTPUT_DIR, "vw_dim_product.csv"), index=False)
print(f" -> vw_dim_product.csv: {len(dim_prod_export):,} rows")

# 7. FactSalesLine (Unified Fact)
print("Exporting FactSalesLine (Unified Sales Fact)...")
fis = pd.read_csv(os.path.join(CLEAN_DIR, "FactInternetSales.csv"))
frs = pd.read_csv(os.path.join(CLEAN_DIR, "FactResellerSales.csv"))

fis["Channel"] = "Internet"
fis["ResellerKey"] = np.nan
fis["DiscountAmount"] = 0.0

frs["Channel"] = "Reseller"
frs["CustomerKey"] = np.nan

common_cols = [
    "SalesOrderNumber", "SalesOrderLineNumber", "Channel", "OrderDateKey",
    "DueDateKey", "ShipDateKey", "CustomerKey", "ResellerKey", "ProductKey",
    "PromotionKey", "CurrencyKey", "SalesTerritoryKey", "OrderQuantity",
    "UnitPrice", "ExtendedAmount", "UnitPriceDiscountPct", "DiscountAmount",
    "ProductStandardCost", "TotalProductCost", "SalesAmount", "TaxAmt", "Freight"
]

fact_sales = pd.concat([fis[common_cols], frs[common_cols]], ignore_index=True)
fact_sales["CustomerKey"] = fact_sales["CustomerKey"].astype("Int64")
fact_sales["ResellerKey"] = fact_sales["ResellerKey"].astype("Int64")
fact_sales["GrossProfit"] = fact_sales["SalesAmount"] - fact_sales["TotalProductCost"]
fact_sales["GrossMarginPct"] = np.where(
    fact_sales["SalesAmount"] > 0,
    (fact_sales["GrossProfit"] / fact_sales["SalesAmount"]) * 100,
    0.0
)

fact_sales.to_csv(os.path.join(OUTPUT_DIR, "vw_sales_fact.csv"), index=False)
print(f" -> vw_sales_fact.csv: {len(fact_sales):,} rows")

# 8. FactProductInventory (Latest Snapshot)
print("Exporting vw_inventory_latest (Latest Snapshot & Reorder Alerts)...")
fpi = pd.read_csv(os.path.join(CLEAN_DIR, "FactProductInventory.csv"))
fpi_clean = fpi[fpi["UnitsBalance"] >= 0].copy()

# Latest date per product
latest_idx = fpi_clean.groupby("ProductKey")["DateKey"].idxmax()
fpi_latest = fpi_clean.loc[latest_idx].copy()

# Enrich with product reorder and safety stock
inv_enriched = fpi_latest.merge(
    dim_prod[["ProductKey", "EnglishProductName", "SafetyStockLevel", "ReorderPoint"]],
    on="ProductKey",
    how="left"
)
inv_enriched["StockStatus"] = np.where(
    inv_enriched["UnitsBalance"] < inv_enriched["SafetyStockLevel"],
    "Critical Shortage",
    np.where(
        inv_enriched["UnitsBalance"] <= inv_enriched["ReorderPoint"],
        "Reorder Needed",
        "Adequate Stock"
    )
)
inv_enriched["StockDeficit"] = np.maximum(0, inv_enriched["ReorderPoint"] - inv_enriched["UnitsBalance"])
inv_enriched.rename(columns={"EnglishProductName": "ProductName"}, inplace=True)
inv_enriched.to_csv(os.path.join(OUTPUT_DIR, "vw_inventory_latest.csv"), index=False)
print(f" -> vw_inventory_latest.csv: {len(inv_enriched):,} rows")

# 9. vw_monthly_channel_kpis (Monthly Pre-Aggregated View)
print("Exporting vw_monthly_channel_kpis (Monthly Pre-Aggregated Benchmarks)...")
fact_sales["YearMonth"] = fact_sales["OrderDateKey"].astype(str).str[:6]
monthly_kpis = fact_sales.groupby(["YearMonth", "Channel"]).agg(
    OrderCount=("SalesOrderNumber", "nunique"),
    LineCount=("SalesOrderLineNumber", "count"),
    UnitsSold=("OrderQuantity", "sum"),
    GrossSales=("ExtendedAmount", "sum"),
    DiscountAmount=("DiscountAmount", "sum"),
    NetSales=("SalesAmount", "sum"),
    TotalCost=("TotalProductCost", "sum"),
    GrossProfit=("GrossProfit", "sum")
).reset_index()

monthly_kpis["GrossMarginPct"] = (monthly_kpis["GrossProfit"] / monthly_kpis["NetSales"]) * 100
monthly_kpis["AOV"] = monthly_kpis["NetSales"] / monthly_kpis["OrderCount"]
monthly_kpis.to_csv(os.path.join(OUTPUT_DIR, "vw_monthly_channel_kpis.csv"), index=False)
print(f" -> vw_monthly_channel_kpis.csv: {len(monthly_kpis):,} rows")

print("=" * 80)
print(f"All 8 Power BI datasets exported successfully to: {OUTPUT_DIR}")
print("=" * 80)
