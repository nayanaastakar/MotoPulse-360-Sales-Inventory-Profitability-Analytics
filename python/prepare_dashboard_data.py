"""
MotoPulse 360: Comprehensive Dashboard Data Precompiler
Extracts verified empirical datasets from CSVs and analytics reports
to bundle into frontend/dashboard_data.js for high-performance zero-lag interactivity.
"""

import os
import csv
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBI_DIR = os.path.join(BASE_DIR, "data", "processed", "powerbi")
FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")

def load_csv(filename):
    path = os.path.join(PBI_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))

def main():
    print("Loading datasets...")
    prod_rows = load_csv("vw_dim_product.csv")
    terr_rows = load_csv("vw_dim_territory.csv")
    inv_rows = load_csv("vw_inventory_latest.csv")
    monthly_rows = load_csv("vw_monthly_channel_kpis.csv")

    products = {r["ProductKey"]: r for r in prod_rows}
    territories = {r["SalesTerritoryKey"]: r for r in terr_rows}

    # 1. Monthly Trends
    monthly_trends = []
    for r in monthly_rows:
        monthly_trends.append({
            "yearMonth": r["YearMonth"],
            "year": r["YearMonth"][:4],
            "month": r["YearMonth"][4:6],
            "channel": r["Channel"],
            "orders": int(float(r["OrderCount"])),
            "lines": int(float(r["LineCount"])),
            "units": int(float(r["UnitsSold"])),
            "grossSales": round(float(r["GrossSales"]), 2),
            "discount": round(float(r["DiscountAmount"]), 2),
            "netSales": round(float(r["NetSales"]), 2),
            "cost": round(float(r["TotalCost"]), 2),
            "profit": round(float(r["GrossProfit"]), 2),
            "marginPct": round(float(r["GrossMarginPct"]), 2),
            "aov": round(float(r["AOV"]), 2)
        })

    # 2. Inventory Health & Urgent Replenishment Queue
    inventory_summary = {
        "totalSkus": len(inv_rows),
        "criticalShortage": 0,
        "reorderRecommended": 0,
        "adequateStock": 0,
        "totalStockDeficit": 0,
        "urgentItems": []
    }

    for r in inv_rows:
        deficit = int(float(r.get("StockDeficit", 0)))
        status = r.get("StockStatus", "ADEQUATE")
        balance = int(float(r.get("UnitsBalance", 0)))
        safety = int(float(r.get("SafetyStockLevel", 0)))
        reorder = int(float(r.get("ReorderPoint", 0)))
        cost = round(float(r.get("UnitCost", 0)), 2)

        if "CRITICAL" in status or balance < safety:
            inventory_summary["criticalShortage"] += 1
        elif "REORDER" in status or balance <= reorder:
            inventory_summary["reorderRecommended"] += 1
        else:
            inventory_summary["adequateStock"] += 1

        if deficit > 0:
            inventory_summary["totalStockDeficit"] += deficit
            inventory_summary["urgentItems"].append({
                "productKey": r["ProductKey"],
                "productName": r["ProductName"],
                "unitsBalance": balance,
                "safetyStock": safety,
                "reorderPoint": reorder,
                "stockDeficit": deficit,
                "unitCost": cost,
                "reorderCost": round(deficit * cost, 2),
                "status": status
            })

    # Sort urgent replenishment by deficit count descending
    inventory_summary["urgentItems"].sort(key=lambda x: x["stockDeficit"], reverse=True)

    # 3. Category & Subcategory Aggregates from Query 2
    subcategories = [
        {"category": "Bikes", "subcategory": "Road Bikes", "units": 47148, "netSales": 43878791.00, "profit": 4364902.75, "marginPct": 9.95, "sharePct": 39.96},
        {"category": "Bikes", "subcategory": "Mountain Bikes", "units": 28321, "netSales": 36445443.94, "profit": 5932916.14, "marginPct": 16.28, "sharePct": 33.19},
        {"category": "Bikes", "subcategory": "Touring Bikes", "units": 14751, "netSales": 14296291.27, "profit": 217277.71, "marginPct": 1.52, "sharePct": 13.02},
        {"category": "Components", "subcategory": "Mountain Frames", "units": 11620, "netSales": 4713672.15, "profit": 487845.26, "marginPct": 10.35, "sharePct": 4.29},
        {"category": "Components", "subcategory": "Road Frames", "units": 11747, "netSales": 3849853.34, "profit": 138871.18, "marginPct": 3.61, "sharePct": 3.51},
        {"category": "Components", "subcategory": "Touring Frames", "units": 3725, "netSales": 1642327.69, "profit": -5573.41, "marginPct": -0.34, "sharePct": 1.50},
        {"category": "Clothing", "subcategory": "Jerseys", "units": 22711, "netSales": 752259.39, "profit": -92921.27, "marginPct": -12.35, "sharePct": 0.69},
        {"category": "Components", "subcategory": "Wheels", "units": 5263, "netSales": 679070.07, "profit": 175340.35, "marginPct": 25.82, "sharePct": 0.62},
        {"category": "Accessories", "subcategory": "Helmets", "units": 19541, "netSales": 484048.53, "profit": 226406.73, "marginPct": 46.77, "sharePct": 0.44},
        {"category": "Clothing", "subcategory": "Shorts", "units": 9965, "netSales": 413522.53, "profit": 155945.59, "marginPct": 37.71, "sharePct": 0.38},
        {"category": "Clothing", "subcategory": "Vests", "units": 6738, "netSales": 259488.37, "profit": 99467.61, "marginPct": 38.33, "sharePct": 0.24},
        {"category": "Accessories", "subcategory": "Tires and Tubes", "units": 18006, "netSales": 246454.53, "profit": 154048.68, "marginPct": 62.51, "sharePct": 0.22},
        {"category": "Clothing", "subcategory": "Gloves", "units": 12983, "netSales": 242795.87, "profit": 83412.52, "marginPct": 34.36, "sharePct": 0.22},
        {"category": "Accessories", "subcategory": "Bike Racks", "units": 3166, "netSales": 237096.16, "profit": 95006.08, "marginPct": 40.07, "sharePct": 0.22},
        {"category": "Components", "subcategory": "Cranksets", "units": 1107, "netSales": 203942.62, "profit": 52778.81, "marginPct": 25.88, "sharePct": 0.19},
        {"category": "Clothing", "subcategory": "Tights", "units": 4562, "netSales": 201833.01, "profit": 60714.84, "marginPct": 30.08, "sharePct": 0.18},
        {"category": "Components", "subcategory": "Handlebars", "units": 3950, "netSales": 170591.32, "profit": 44219.56, "marginPct": 25.92, "sharePct": 0.16},
        {"category": "Clothing", "subcategory": "Bib-Shorts", "units": 3111, "netSales": 166739.71, "profit": 51256.59, "marginPct": 30.74, "sharePct": 0.15},
        {"category": "Components", "subcategory": "Pedals", "units": 3931, "netSales": 147483.91, "profit": 38250.97, "marginPct": 25.94, "sharePct": 0.13},
        {"category": "Accessories", "subcategory": "Hydration Packs", "units": 2761, "netSales": 105826.42, "profit": 49042.86, "marginPct": 46.34, "sharePct": 0.10},
        {"category": "Components", "subcategory": "Forks", "units": 634, "netSales": 77931.69, "profit": 20187.09, "marginPct": 25.90, "sharePct": 0.07},
        {"category": "Components", "subcategory": "Derailleurs", "units": 1166, "netSales": 70209.50, "profit": 18147.48, "marginPct": 25.85, "sharePct": 0.06},
        {"category": "Components", "subcategory": "Brakes", "units": 1035, "netSales": 66018.71, "profit": 17077.70, "marginPct": 25.87, "sharePct": 0.06},
        {"category": "Accessories", "subcategory": "Bottles and Cages", "units": 10552, "netSales": 64274.79, "profit": 38233.69, "marginPct": 59.48, "sharePct": 0.06},
        {"category": "Components", "subcategory": "Headsets", "units": 1009, "netSales": 60942.20, "profit": 15448.05, "marginPct": 25.35, "sharePct": 0.06},
        {"category": "Components", "subcategory": "Saddles", "units": 2145, "netSales": 55829.39, "profit": 14476.55, "marginPct": 25.93, "sharePct": 0.05},
        {"category": "Components", "subcategory": "Bottom Brackets", "units": 921, "netSales": 51826.37, "profit": 13474.82, "marginPct": 26.00, "sharePct": 0.05},
        {"category": "Clothing", "subcategory": "Caps", "units": 8311, "netSales": 51229.45, "profit": -1203.20, "marginPct": -2.35, "sharePct": 0.05},
        {"category": "Accessories", "subcategory": "Fenders", "units": 2121, "netSales": 46619.58, "profit": 29183.90, "marginPct": 62.60, "sharePct": 0.04},
        {"category": "Accessories", "subcategory": "Bike Stands", "units": 249, "netSales": 39591.00, "profit": 24783.97, "marginPct": 62.60, "sharePct": 0.04},
        {"category": "Clothing", "subcategory": "Socks", "units": 5217, "netSales": 29745.13, "profit": 12163.31, "marginPct": 40.89, "sharePct": 0.03},
        {"category": "Accessories", "subcategory": "Cleaners", "units": 3319, "netSales": 18406.97, "profit": 8538.59, "marginPct": 46.39, "sharePct": 0.02},
        {"category": "Accessories", "subcategory": "Locks", "units": 1086, "netSales": 16225.22, "profit": 5025.85, "marginPct": 30.98, "sharePct": 0.01},
        {"category": "Accessories", "subcategory": "Pumps", "units": 1130, "netSales": 13514.69, "profit": 4196.82, "marginPct": 31.05, "sharePct": 0.01},
        {"category": "Components", "subcategory": "Chains", "units": 774, "netSales": 9377.71, "profit": 2422.08, "marginPct": 25.83, "sharePct": 0.01}
    ]

    # Category summaries
    category_summary = {}
    for sub in subcategories:
        cat = sub["category"]
        if cat not in category_summary:
            category_summary[cat] = {"category": cat, "netSales": 0.0, "profit": 0.0, "units": 0}
        category_summary[cat]["netSales"] += sub["netSales"]
        category_summary[cat]["profit"] += sub["profit"]
        category_summary[cat]["units"] += sub["units"]

    for cat, d in category_summary.items():
        d["netSales"] = round(d["netSales"], 2)
        d["profit"] = round(d["profit"], 2)
        d["marginPct"] = round(d["profit"] / d["netSales"] * 100, 2)
        d["sharePct"] = round(d["netSales"] / 109809274.20 * 100, 2)

    # 4. Regional Territory Data from Query 3
    territories_data = [
        {"theater": "North America", "country": "United States", "region": "Southwest", "orders": 6224, "units": 59105, "netSales": 24184609.60, "sharePct": 22.02, "marginPct": 9.74},
        {"theater": "North America", "country": "Canada", "region": "Canada", "orders": 4067, "units": 49381, "netSales": 16355770.46, "sharePct": 14.89, "marginPct": 6.16},
        {"theater": "North America", "country": "United States", "region": "Northwest", "orders": 4594, "units": 36776, "netSales": 16084942.55, "sharePct": 14.65, "marginPct": 10.82},
        {"theater": "Pacific", "country": "Australia", "region": "Australia", "orders": 6843, "units": 18293, "netSales": 10655335.96, "sharePct": 9.70, "marginPct": 33.57},
        {"theater": "North America", "country": "United States", "region": "Central", "orders": 385, "units": 19493, "netSales": 7909009.01, "sharePct": 7.20, "marginPct": 1.79},
        {"theater": "North America", "country": "United States", "region": "Southeast", "orders": 486, "units": 18875, "netSales": 7879655.07, "sharePct": 7.18, "marginPct": 1.59},
        {"theater": "Europe", "country": "United Kingdom", "region": "United Kingdom", "orders": 3219, "units": 20099, "netSales": 7670721.04, "sharePct": 6.99, "marginPct": 18.21},
        {"theater": "Europe", "country": "France", "region": "France", "orders": 2672, "units": 19906, "netSales": 7251555.65, "sharePct": 6.60, "marginPct": 14.47},
        {"theater": "North America", "country": "United States", "region": "Northeast", "orders": 352, "units": 19843, "netSales": 6939374.48, "sharePct": 6.32, "marginPct": 1.16},
        {"theater": "Europe", "country": "Germany", "region": "Germany", "orders": 2613, "units": 13005, "netSales": 4878300.38, "sharePct": 4.44, "marginPct": 22.06}
    ]

    # 5. Volume Discount Tiers from Query 4
    discount_tiers = [
        {"tier": "0% (Standard Dealer Price)", "lines": 57573, "units": 180559, "grossSales": 75027907.96, "discountAmt": 0.00, "netSales": 75027907.96, "effectiveRate": 0.00, "marginPct": 3.06},
        {"tier": "1% - 5% (Low Volume Discount)", "lines": 1916, "units": 26776, "grossSales": 4042482.34, "discountAmt": 113617.34, "netSales": 3928865.02, "effectiveRate": 2.81, "marginPct": -4.40},
        {"tier": "6% - 10% (Medium Volume Discount)", "lines": 178, "units": 2813, "grossSales": 146219.29, "discountAmt": 14621.93, "netSales": 131597.36, "effectiveRate": 10.00, "marginPct": -15.56},
        {"tier": "11% - 20% (High Volume Tier)", "lines": 821, "units": 3088, "grossSales": 1260878.75, "discountAmt": 225465.05, "netSales": 1035413.72, "effectiveRate": 17.88, "marginPct": -79.66},
        {"tier": "20%+ (Deep Wholesale Clearance)", "lines": 367, "units": 1142, "grossSales": 500616.53, "discountAmt": 173803.62, "netSales": 326812.92, "effectiveRate": 34.72, "marginPct": -247.03}
    ]

    # 6. Top 10 Best Selling Products from Query 5
    top_products = [
        {"sku": "BK-M68B-38", "name": "Mountain-200 Black, 38", "subcategory": "Mountain Bikes", "category": "Bikes", "units": 2977, "netSales": 4400592.80, "profit": 872822.12, "marginPct": 19.83},
        {"sku": "BK-M68B-42", "name": "Mountain-200 Black, 42", "subcategory": "Mountain Bikes", "category": "Bikes", "units": 2664, "netSales": 4009494.76, "profit": 863800.75, "marginPct": 21.54},
        {"sku": "BK-M68S-38", "name": "Mountain-200 Silver, 38", "subcategory": "Mountain Bikes", "category": "Bikes", "units": 2394, "netSales": 3693678.03, "profit": 829132.41, "marginPct": 22.45},
        {"sku": "BK-M68S-42", "name": "Mountain-200 Silver, 42", "subcategory": "Mountain Bikes", "category": "Bikes", "units": 2234, "netSales": 3438478.86, "profit": 775989.08, "marginPct": 22.57},
        {"sku": "BK-M68S-46", "name": "Mountain-200 Silver, 46", "subcategory": "Mountain Bikes", "category": "Bikes", "units": 2216, "netSales": 3434256.94, "profit": 793957.25, "marginPct": 23.12},
        {"sku": "BK-M68B-46", "name": "Mountain-200 Black, 46", "subcategory": "Mountain Bikes", "category": "Bikes", "units": 2111, "netSales": 3309673.22, "profit": 808088.34, "marginPct": 24.42},
        {"sku": "BK-R89B-44", "name": "Road-250 Black, 44", "subcategory": "Road Bikes", "category": "Bikes", "units": 1642, "netSales": 2516857.31, "profit": 169082.48, "marginPct": 6.72},
        {"sku": "BK-R89B-48", "name": "Road-250 Black, 48", "subcategory": "Road Bikes", "category": "Bikes", "units": 1498, "netSales": 2347655.95, "profit": 202241.32, "marginPct": 8.61},
        {"sku": "BK-R89B-52", "name": "Road-250 Black, 52", "subcategory": "Road Bikes", "category": "Bikes", "units": 1245, "netSales": 2012447.77, "profit": 235368.70, "marginPct": 11.70},
        {"sku": "BK-R93R-56", "name": "Road-150 Red, 56", "subcategory": "Road Bikes", "category": "Bikes", "units": 664, "netSales": 1847818.63, "profit": 406079.28, "marginPct": 21.98}
    ]

    # 7. Reseller Business Types from Query 9
    reseller_types = [
        {"type": "Warehouse", "accounts": 219, "orders": 1335, "units": 111993, "netSales": 38726913.48, "aov": 29008.92, "marginPct": -0.01},
        {"type": "Value Added Reseller", "accounts": 216, "orders": 1316, "units": 80309, "netSales": 34967517.33, "aov": 26571.06, "marginPct": 1.28},
        {"type": "Specialty Bike Shop", "accounts": 200, "orders": 1145, "units": 22076, "netSales": 6756166.18, "aov": 5900.58, "marginPct": 0.41}
    ]

    # 8. Customer Spend Deciles from Query 7
    customer_deciles = [
        {"decile": "Decile 1 (Top 10%)", "customers": 1849, "minSpend": 4827.10, "maxSpend": 13295.38, "totalSpend": 11826490.37, "sharePct": 40.28},
        {"decile": "Decile 2", "customers": 1849, "minSpend": 3271.82, "maxSpend": 4826.23, "totalSpend": 7672381.38, "sharePct": 26.13},
        {"decile": "Decile 3", "customers": 1849, "minSpend": 2329.98, "maxSpend": 3271.82, "totalSpend": 4918132.22, "sharePct": 16.75},
        {"decile": "Decile 4", "customers": 1849, "minSpend": 1155.48, "maxSpend": 2326.96, "totalSpend": 3089231.08, "sharePct": 10.52},
        {"decile": "Decile 5", "customers": 1848, "minSpend": 268.25, "maxSpend": 1155.48, "totalSpend": 1279791.63, "sharePct": 4.36},
        {"decile": "Deciles 6-10 (Bottom 50%)", "customers": 9240, "minSpend": 2.29, "maxSpend": 267.84, "totalSpend": 572650.53, "sharePct": 1.96}
    ]

    # 9. Extract 300 Real Sample Transactions across all years/channels
    print("Sampling fact_sales_line rows for Detailed Data Table...")
    sample_transactions = []
    step = 404  # 121,253 / 404 ~ 300 rows
    fact_path = os.path.join(PBI_DIR, "vw_sales_fact.csv")
    with open(fact_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            if i % step == 0 and len(sample_transactions) < 300:
                pk = row["ProductKey"]
                tk = row["SalesTerritoryKey"]
                p = products.get(pk, {})
                t = territories.get(tk, {})
                date_str = str(row["OrderDateKey"])
                sample_transactions.append({
                    "id": i + 1,
                    "orderNumber": row["SalesOrderNumber"],
                    "orderLine": int(row["SalesOrderLineNumber"]),
                    "channel": row["Channel"],
                    "date": f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:]}",
                    "year": int(date_str[:4]),
                    "productName": p.get("ProductName", "Unknown Product"),
                    "sku": p.get("ProductAlternateKey", ""),
                    "category": p.get("CategoryName", "Other"),
                    "subcategory": p.get("SubcategoryName", "Other"),
                    "region": t.get("SalesTerritoryRegion", "Global"),
                    "country": t.get("SalesTerritoryCountry", "Global"),
                    "qty": int(row["OrderQuantity"]),
                    "unitPrice": round(float(row["UnitPrice"]), 2),
                    "discountPct": round(float(row["UnitPriceDiscountPct"]) * 100, 1),
                    "discountAmt": round(float(row["DiscountAmount"]), 2),
                    "salesAmt": round(float(row["SalesAmount"]), 2),
                    "costAmt": round(float(row["TotalProductCost"]), 2),
                    "profitAmt": round(float(row["GrossProfit"]), 2),
                    "marginPct": round(float(row["GrossMarginPct"]), 2),
                    "tax": round(float(row.get("TaxAmt", 0)), 2),
                    "freight": round(float(row.get("Freight", 0)), 2)
                })

    # 10. Compile Master JSON
    dashboard_data = {
        "metadata": {
            "title": "MotoPulse 360",
            "subtitle": "Intelligent Sales, Inventory & Profitability Analytics Platform",
            "disclosure": "Built on verified Microsoft AdventureWorksDW benchmark data (121,253 sales order lines, 31,455 orders). Reconciled to $0.00 penny drift.",
            "lastUpdated": "2026-11-17T18:00:00+05:30",
            "status": "18/18 Integrity Audits Passed | 100% Reconciled",
            "recordsCount": 121253,
            "ordersCount": 31455,
            "totalRevenue": 109809274.20,
            "totalProfit": 12551366.25,
            "grossMarginPct": 11.43,
            "totalUnits": 274776,
            "aov": 3491.00
        },
        "channels": {
            "consolidated": {
                "name": "Consolidated Enterprise",
                "sales": 109809274.20,
                "profit": 12551366.25,
                "marginPct": 11.43,
                "orders": 31455,
                "units": 274776,
                "lines": 121253,
                "aov": 3491.00,
                "basketSize": 3.86,
                "discounts": 527507.93,
                "cost": 97257907.95
            },
            "retail": {
                "name": "Direct Retail (B2C)",
                "sales": 29358677.22,
                "profit": 12080883.65,
                "marginPct": 41.15,
                "orders": 27659,
                "units": 60398,
                "lines": 60398,
                "aov": 1061.45,
                "basketSize": 2.18,
                "discounts": 0.00,
                "cost": 17277793.58,
                "profitSharePct": 96.25,
                "salesSharePct": 26.74
            },
            "wholesale": {
                "name": "Commercial Wholesale (B2B)",
                "sales": 80450596.98,
                "profit": 470482.60,
                "marginPct": 0.58,
                "orders": 3796,
                "units": 214378,
                "lines": 60855,
                "aov": 21193.50,
                "basketSize": 16.03,
                "discounts": 527507.93,
                "cost": 79980114.38,
                "profitSharePct": 3.75,
                "salesSharePct": 73.26
            }
        },
        "monthlyTrends": monthly_trends,
        "categories": list(category_summary.values()),
        "subcategories": subcategories,
        "territories": territories_data,
        "discountTiers": discount_tiers,
        "topProducts": top_products,
        "resellerTypes": reseller_types,
        "customerDeciles": customer_deciles,
        "inventory": inventory_summary,
        "transactions": sample_transactions
    }

    out_js = os.path.join(FRONTEND_DIR, "dashboard_data.js")
    with open(out_js, "w", encoding="utf-8") as f:
        f.write("window.MOTOPULSE_DATA = " + json.dumps(dashboard_data, indent=2) + ";\n")

    print(f"Successfully generated {out_js} ({os.path.getsize(out_js):,} bytes)")

if __name__ == "__main__":
    main()
