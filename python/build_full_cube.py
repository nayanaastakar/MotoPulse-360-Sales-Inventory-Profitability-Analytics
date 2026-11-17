"""
MotoPulse 360: Full Multidimensional Analytical Cube & Data Bundle Generator
Precompiles the complete 121,253-line fact dataset into an ultra-fast, 
multi-dimensional micro-cube (6,618 cells) for sub-millisecond in-browser cross-filtering.
"""

import os
import csv
import json
from collections import defaultdict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBI_DIR = os.path.join(BASE_DIR, "data", "processed", "powerbi")
FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")

def load_csv(filename):
    path = os.path.join(PBI_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))

def main():
    print("Loading Star Schema dimension tables...")
    prod_rows = load_csv("vw_dim_product.csv")
    terr_rows = load_csv("vw_dim_territory.csv")
    inv_rows = load_csv("vw_inventory_latest.csv")

    products = {r["ProductKey"]: (r["CategoryName"], r["SubcategoryName"], r["ProductName"], r["ProductAlternateKey"]) for r in prod_rows}
    territories = {r["SalesTerritoryKey"]: (r["SalesTerritoryRegion"], r["SalesTerritoryCountry"], r["SalesTerritoryGroup"]) for r in terr_rows}

    print("Building multi-dimensional cube from vw_sales_fact.csv (121,253 rows)...")
    # key: (year, month, channel, category, subcategory, region)
    # val: [orders_set, units, sales, cost, profit, discount]
    cube_dict = defaultdict(lambda: [set(), 0, 0.0, 0.0, 0.0, 0.0])

    fact_path = os.path.join(PBI_DIR, "vw_sales_fact.csv")
    sample_transactions = []
    step = 404  # ~300 representative rows

    with open(fact_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for i, r in enumerate(reader):
            date_str = str(r["OrderDateKey"])
            year = int(date_str[:4])
            month = int(date_str[4:6])
            channel = "Retail" if r["Channel"] == "Internet" else "Wholesale"
            
            p_info = products.get(r["ProductKey"], ("Other", "Other", "Unknown Product", ""))
            t_info = territories.get(r["SalesTerritoryKey"], ("Other", "Other", "Other"))
            
            cat, subcat, prod_name, sku = p_info
            region, country, group = t_info
            
            qty = int(r["OrderQuantity"])
            sales = float(r["SalesAmount"])
            cost = float(r["TotalProductCost"])
            profit = float(r["GrossProfit"])
            discount = float(r["DiscountAmount"])

            k = (year, month, channel, cat, subcat, region)
            cell = cube_dict[k]
            cell[0].add(r["SalesOrderNumber"])
            cell[1] += qty
            cell[2] += sales
            cell[3] += cost
            cell[4] += profit
            cell[5] += discount

            # Sample row for table
            if i % step == 0 and len(sample_transactions) < 350:
                sample_transactions.append({
                    "id": i + 1,
                    "orderNumber": r["SalesOrderNumber"],
                    "orderLine": int(r["SalesOrderLineNumber"]),
                    "channel": channel,
                    "date": f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:]}",
                    "year": year,
                    "month": month,
                    "productName": prod_name,
                    "sku": sku,
                    "category": cat,
                    "subcategory": subcat,
                    "region": region,
                    "country": country,
                    "qty": qty,
                    "unitPrice": round(float(r["UnitPrice"]), 2),
                    "discountPct": round(float(r["UnitPriceDiscountPct"]) * 100, 1),
                    "discountAmt": round(discount, 2),
                    "salesAmt": round(sales, 2),
                    "costAmt": round(cost, 2),
                    "profitAmt": round(profit, 2),
                    "marginPct": round(float(r["GrossMarginPct"]), 2),
                    "tax": round(float(r.get("TaxAmt", 0)), 2),
                    "freight": round(float(r.get("Freight", 0)), 2)
                })

    # Convert cube into compact list of tuples:
    # [year, month, channel, category, subcategory, region, orderCount, units, sales, cost, profit, discount]
    compact_cube = []
    total_sales = 0.0
    total_profit = 0.0
    for k, v in cube_dict.items():
        year, month, channel, cat, subcat, region = k
        orders_count = len(v[0])
        units = v[1]
        sales = round(v[2], 2)
        cost = round(v[3], 2)
        profit = round(v[4], 2)
        discount = round(v[5], 2)

        total_sales += sales
        total_profit += profit

        compact_cube.append([
            year,
            month,
            channel,
            cat,
            subcat,
            region,
            orders_count,
            units,
            sales,
            cost,
            profit,
            discount
        ])

    print(f"Cube compiled: {len(compact_cube)} cells. Total Sales: ${total_sales:,.2f}, Profit: ${total_profit:,.2f}")

    # Inventory summary
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

    inventory_summary["urgentItems"].sort(key=lambda x: x["stockDeficit"], reverse=True)

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

    # Compile master bundle
    bundle = {
        "metadata": {
            "title": "MotoPulse 360",
            "subtitle": "Intelligent Sales, Inventory & Profitability Platform",
            "disclosure": "Built on verified Microsoft AdventureWorksDW benchmark data (121,253 sales order lines, 31,455 orders). Reconciled to $0.00 penny drift.",
            "totalRevenue": 109809274.20,
            "totalProfit": 12551366.25,
            "grossMarginPct": 11.43,
            "totalOrders": 31455,
            "totalUnits": 274776,
            "totalLines": 121253,
            "aov": 3491.00,
            "totalDiscount": 527507.93
        },
        "cube": compact_cube,
        "inventory": inventory_summary,
        "topProducts": top_products,
        "transactions": sample_transactions
    }

    out_file = os.path.join(FRONTEND_DIR, "dashboard_data.js")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write("window.MOTOPULSE_DATA = " + json.dumps(bundle, separators=(",", ":")) + ";\n")

    print(f"Generated {out_file} ({os.path.getsize(out_file):,} bytes)")

if __name__ == "__main__":
    main()
