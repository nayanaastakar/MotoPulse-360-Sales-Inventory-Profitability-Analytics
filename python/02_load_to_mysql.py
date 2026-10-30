"""
MotoPulse 360 - Stage 4: Automated MySQL Database Loader & Validation Pipeline.

Purpose
-------
Loads clean CSV files from data/processed/clean/ into MySQL staging tables,
executes cleaning transformations to populate typed analytical tables, and
runs data quality audits.

Features:
- Secure: Reads connection parameters from .env (never hardcodes passwords).
- Robust: Windows-friendly Python/SQLAlchemy batch loader (works even when
  LOAD DATA LOCAL INFILE is disabled by server security).
- Auditable: Compares CSV source rows against MySQL table counts and prints
  a full reconciliation matrix.

Usage:
    py python/02_load_to_mysql.py
"""

import os
import sys
import time
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Load environment variables
load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "motopulse360")

CLEAN_DIR = Path("data/processed/clean")
SQL_DIR = Path("sql")

TABLE_STAGING_MAP = {
    "DimDate": "stg_dim_date",
    "DimProductCategory": "stg_dim_product_category",
    "DimProductSubcategory": "stg_dim_product_subcategory",
    "DimProduct": "stg_dim_product",
    "DimCustomer": "stg_dim_customer",
    "DimReseller": "stg_dim_reseller",
    "DimSalesTerritory": "stg_dim_sales_territory",
    "DimGeography": "stg_dim_geography",
    "DimPromotion": "stg_dim_promotion",
    "DimCurrency": "stg_dim_currency",
    "FactInternetSales": "stg_fact_internet_sales",
    "FactResellerSales": "stg_fact_reseller_sales",
    "FactProductInventory": "stg_fact_product_inventory",
    "FactCurrencyRate": "stg_fact_currency_rate",
    "FactSalesQuota": "stg_fact_sales_quota",
}


def get_engine(include_db: bool = True):
    db_part = f"/{DB_NAME}" if include_db else ""
    url = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}{db_part}?charset=utf8mb4"
    return create_engine(url, echo=False)


def execute_sql_file(conn, file_path: Path):
    print(f"Executing {file_path.name}...")
    with open(file_path, "r", encoding="utf-8") as f:
        statements = f.read().split(";")
    for stmt in statements:
        stmt = stmt.strip()
        if stmt and not stmt.startswith("--"):
            conn.execute(text(stmt))


def main():
    print("=" * 80)
    print("MotoPulse 360: Automated MySQL Loader & Verification")
    print(f"Target: mysql://{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    print("=" * 80)

    # 1. Test Server Connectivity
    try:
        root_engine = get_engine(include_db=False)
        with root_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print("SUCCESS: Connected to MySQL Server!")
    except Exception as exc:
        print("\n[UNAVAILABLE] Could not connect to MySQL Server.")
        print(f"Error details: {exc}")
        print("\nTroubleshooting for Windows:")
        print("1. Ensure MySQL Server is installed and running (e.g., via Windows Services: services.msc).")
        print("2. Create a '.env' file in project root with valid credentials (see .env.example).")
        print("3. Alternatively, you can execute the SQL scripts directly in MySQL Workbench:")
        print("   - sql/01_create_database.sql")
        print("   - sql/02_create_tables.sql")
        print("   - sql/02b_load_staging.sql")
        print("   - sql/04_data_cleaning.sql")
        print("   - sql/03_data_quality_checks.sql")
        return 1

    # 2. Create Database & Tables
    engine = get_engine(include_db=False)
    with engine.begin() as conn:
        execute_sql_file(conn, SQL_DIR / "01_create_database.sql")

    engine = get_engine(include_db=True)
    with engine.begin() as conn:
        execute_sql_file(conn, SQL_DIR / "02_create_tables.sql")

    # 3. Load Staging Tables via Pandas Chunking
    print("\nLoading clean CSVs into staging tables...")
    reconciliation = []

    for file_stem, stg_table in TABLE_STAGING_MAP.items():
        csv_file = CLEAN_DIR / f"{file_stem}.csv"
        if not csv_file.exists():
            print(f"WARNING: {csv_file} not found. Run python/01_convert_raw_to_clean_csv.py first.")
            continue

        start_t = time.time()
        print(f"Loading {stg_table:28} from {csv_file.name:24}...", end=" ", flush=True)
        
        # Read clean CSV as strings
        df = pd.read_csv(csv_file, dtype=str, keep_default_na=False, encoding="utf-8")
        csv_row_count = len(df)

        # Batch insert into MySQL staging table
        df.to_sql(
            stg_table,
            con=engine,
            if_exists="append",
            index=False,
            chunksize=10000,
            method="multi"
        )

        with engine.connect() as conn:
            db_count = conn.execute(text(f"SELECT COUNT(*) FROM {stg_table}")).scalar()

        dur = round(time.time() - start_t, 2)
        match = "MATCH" if csv_row_count == db_count else "MISMATCH"
        print(f"OK: {db_count:,} rows in {dur}s [{match}]")

        reconciliation.append({
            "table": stg_table,
            "csv_rows": csv_row_count,
            "db_rows": db_count,
            "status": match,
            "duration_sec": dur
        })

    # 4. Execute Data Cleaning & Transformation
    print("\nExecuting sql/04_data_cleaning.sql...")
    with engine.begin() as conn:
        execute_sql_file(conn, SQL_DIR / "04_data_cleaning.sql")

    # 5. Execute Data Quality Checks
    print("\nExecuting sql/03_data_quality_checks.sql...")
    with engine.begin() as conn:
        execute_sql_file(conn, SQL_DIR / "03_data_quality_checks.sql")

    # 6. Display Data Quality Results
    print("\n" + "=" * 80)
    print("DATA QUALITY AUDIT SUMMARY (dq_summary)")
    print("=" * 80)
    with engine.connect() as conn:
        dq_results = conn.execute(text("SELECT check_category, table_name, check_description, failing_records_count, status FROM dq_summary")).fetchall()
        for row in dq_results:
            print(f"[{row[4]:6}] {row[0]:25} | {row[1]:25} | {row[2]:40} | Failures: {row[3]}")

    print("=" * 80)
    print("Stage 4 MySQL Loading & Transformation Completed Successfully!")
    print("=" * 80)
    return 0


if __name__ == "__main__":
    sys.exit(main())
