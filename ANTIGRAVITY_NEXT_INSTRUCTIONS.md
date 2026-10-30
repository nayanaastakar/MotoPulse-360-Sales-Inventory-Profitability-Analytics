# MotoPulse 360: Continuation Playbook for Antigravity

Place this file in the project root next to `ANTIGRAVITY_START_HERE.md` and `HANDOVER_TO_ANTIGRAVITY.md`.
Read those two first. This playbook says how to finish the project from the current point
(Stage 2, inspection script written but NOT yet run on real data).

---

## 0. Non-negotiable rules (apply to every stage)

1. **No fabricated results.** Every number, row count, date range, finding, screenshot or "tested" claim must come from output you actually produced or the user pasted. If you cannot run something, say so and give the user the exact command.
2. **Raw data is read-only.** Never edit, overwrite or delete anything in `data/raw/`.
3. **Preserve working files.** Do not regenerate `python/00_inspect_raw_files.py`. Fix it only if real files expose a bug, and explain the diff first.
4. **Small gated stages.** At the end of each stage: list files created/changed, how to run them, tests performed, results observed, open issues. Then STOP and wait for the user to confirm before the next stage.
5. **Label every claim:** observed (from data), derived (computed), assumption, or synthetic. AdventureWorks is a fictional, synthetic bicycle company: never call it real or motorcycle data.
6. **Financial integrity:** revenue is not profit. Gross profit only from the dataset's standard-cost fields, labelled "based on standard cost (model value, not observed cost)". Never infer stock shortage from sales alone. Never invent returns, payment fees or supplier costs.
7. **Credentials:** database passwords go in a local `.env` (git-ignored). Commit only `.env.example` with placeholders.
8. **MySQL-compatible SQL only** (MySQL 8.x features such as CTEs and window functions are fine). No PostgreSQL/SQL Server syntax.
9. **Teach, don't just generate.** The user is a fresher who must explain this in interviews. Add comments, short rationale for each decision, and plain-language explanations.
10. **Ask rather than guess** when something is missing (files, credentials, MySQL settings, branding decision).

---

## Stage 2: Run and validate the raw-file inspection (current stage)

**Goal:** learn what the real files look like before any schema is written.

Tasks
1. List `data/raw/` recursively. Report which of these are present/missing: DimDate, DimProduct, DimProductSubcategory, DimProductCategory, DimCustomer, DimReseller, DimSalesTerritory, FactInternetSales, FactResellerSales, FactProductInventory. If some are missing, name them and ask the user; do not proceed with fake data.
2. Run `python python/00_inspect_raw_files.py` from the project root (venv active). Capture the console output and `data/processed/raw_file_inspection.csv`.
3. Record real findings in `docs/raw_file_inspection_findings.md`: per file, the encoding, delimiter, header present or not, row and column counts, sample rows, date ranges.
4. Known risks to test explicitly (previously recalled from memory, NOT verified): UTF-16 encoding, unusual delimiters, no header row, `+|` multi-character delimiter (untested path), the script's header heuristic misjudging a file. Report each as confirmed or refuted.
5. If files have no header, derive column names from the official AdventureWorksDW table definitions and record the source of each name. If names cannot be confirmed, ask the user.
6. Investigate malformed rows or parse warnings. Do not drop them silently.
7. Ask the user two decisions: (a) keep the "MotoPulse 360" name with a clear fictional/AdventureWorks-bicycle disclosure, or rename (e.g. "CyclePulse 360"); (b) confirm the DW tables to use.

Done when: real output has been reviewed, findings are written, the user confirmed.

---

## Stage 3: Data model and schema design (documents only, no SQL yet)

Create `docs/data_model.md` (Mermaid ER diagram + explanation) and `docs/data_dictionary.md` (first draft), using the REAL columns from Stage 2.

Planned model (adjust to what the real data shows):
- Dimensions: `dim_date`, `dim_product`, `dim_product_subcategory`, `dim_product_category`, `dim_customer`, `dim_reseller`, `dim_sales_territory`.
- Facts: `fact_sales_line` (FactInternetSales and FactResellerSales stacked, with a `channel` column: 'Internet' = Retail analogue, 'Reseller' = Wholesale analogue) and `fact_inventory_movement`.
- Grain, define explicitly in the docs:
  - `fact_sales_line`: one sales-order line (order number + line number). Verify uniqueness of that pair per channel in the real data.
  - `fact_inventory_movement`: one product on one date (verify).
- Decide and document how customer vs reseller keys are stored in the unified fact (nullable keys with a CHECK-style validation query: exactly one populated).
- Order-level fields (freight, tax) repeat on every line of an order; document that they must not be summed naively, and decide whether to exclude them from revenue (recommended: exclude from net sales).
- Verify, do not assume: whether DimProduct/DimCustomer are slowly-changing (multiple versions per business key with start/end dates/status). If so, document how product-level rollups avoid splitting one product into several rows (e.g. group by the business key/name, or use the fact's ProductKey version consistently) and show the evidence.
- "Warehouse" analysis is replaced by **Sales Territory** analysis. DimReseller's business type containing "Warehouse" is a customer type, not the retailer's warehouse.
- Inventory has no warehouse dimension (verify). Replenishment analysis is product-level only; compare the latest balance with the product's reorder point / safety stock where those fields exist, and state clearly what the inventory balance does and does not mean once its semantics are verified in the real data.

Also write `docs/business_requirements.md`:
- Questions answerable: revenue/units/orders/AOV by product, category, territory, channel, month; discount amount and rate; gross profit and margin (standard-cost basis); Retail vs Wholesale behaviour; MoM growth, rankings, running totals, concentration; product-level stock vs reorder point (if supported).
- Questions NOT answerable: payment fees, returns, warehouse performance/stock, stockouts and lost sales, observed supplier cost.

Gate: user reviews the model and confirms before any SQL.

---

## Stage 4: MySQL implementation (`sql/` + conversion step)

### 4a. Environment
- Confirm MySQL 8.x is installed and running; connect via Workbench or the `mysql` CLI. Ask the user for host/port/user; password only via `.env`.
- Create `.env.example` (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME) and add a small Python helper that reads `.env` (use `python-dotenv`, add it to requirements.txt).

### 4b. Convert the raw files to clean UTF-8 CSVs
- Write `python/01_convert_raw_to_clean_csv.py`: reads each raw file using the encoding/delimiter/header facts verified in Stage 2 and writes UTF-8, comma-delimited, quoted CSVs with proper column names into `data/processed/clean/`. Everything stays text at this step. Log row counts in/out per file and fail loudly on any mismatch. Never touch `data/raw/`.

### 4c. SQL scripts (idempotent, safe to rerun, with comments)
Execution order and names:
1. `sql/01_create_database.sql`: `CREATE DATABASE IF NOT EXISTS motopulse360 CHARACTER SET utf8mb4`.
2. `sql/02_create_tables.sql`: staging tables `stg_*` (all VARCHAR, one per source file, raw copy for traceability) and typed analytical tables (`DECIMAL(19,4)` for money, `DATE` for dates, appropriate INT sizes, PK/FK/indexes). Add FKs only where the data supports them; if real data violates a key, report it instead of weakening silently.
3. `sql/02b_load_staging.sql` (or a Python loader): load clean CSVs into staging. `LOAD DATA LOCAL INFILE` requires `local_infile=1` on both server and client and may hit `secure_file_priv`; give the user the exact steps, and offer a pandas + SQLAlchemy (`pymysql`) loader as fallback. After loading, compare staging row counts to the CSV row counts and report.
4. `sql/03_data_quality_checks.sql`: read-only checks producing a summary table (`dq_summary`): duplicate keys, orphan foreign keys in each direction, NULL/blank counts, negative or zero quantities/prices, impossible or out-of-range dates (order <= ship, DateKey valid), financial consistency (test empirically whether SalesAmount = ExtendedAmount - DiscountAmount, whether TotalProductCost = ProductStandardCost x quantity, discount % vs amount; report the actual mismatch counts rather than assuming the formulas), uniqueness of line grain, channel key rule.
5. `sql/04_data_cleaning.sql`: build typed analytical tables from staging with documented rules (NULLIF on blanks, STR_TO_DATE for DateKey, casts). **Do not silently delete questionable rows.** Flag them (e.g. `dq_flag` column or a quarantine table), explain the treatment, and report counts.
6. Reconciliation: row counts staging vs analytical; `fact_sales_line` count = FactInternetSales + FactResellerSales; total SalesAmount per channel equals the staging total. Report actual numbers.

Gate: the user runs the scripts and shares output (row counts, `dq_summary`). Review findings with the user before analytics.

---

## Stage 5: Business metrics and SQL analytics

First write `docs/methodology.md` defining each metric with formula and limitation:
- Gross sales amount, discount amount, net sales revenue, units sold, number of orders (COUNT DISTINCT order number, per channel), AOV (net sales / distinct orders, defined at order level, never line-level average), MoM growth, revenue share, gross profit and gross margin (standard-cost basis only), stock vs reorder point (product-level, if verified).
- Explicitly list metrics not computed and why (payment fees, returns, inventory turnover unless cost + inventory semantics are verified, days of inventory likewise).

SQL files (each query block with: business question, query, logic explanation, expected output columns, validation method, interpretation placeholder to fill ONLY after running):
- `sql/05_business_analysis.sql`: core (SELECT/WHERE/GROUP BY/HAVING/CASE/NULL handling/joins/date functions/subqueries) and intermediate (CTEs, conditional aggregation; revenue by product/category/territory/channel/month, AOV, units, distinct orders, discount analysis, gross profit by product/category).
- `sql/06_advanced_analytics.sql`: ROW_NUMBER/RANK/DENSE_RANK, LAG/LEAD for MoM growth, running totals, percent contribution, top-N per category/territory, 3-month moving average (only if the months are contiguous; verify), Pareto/concentration, customer segmentation only if customer history supports it (document the rule used), product stock vs reorder point.
- `sql/07_views_and_kpis.sql`: reusable views for Power BI (`vw_sales_fact`, `vw_dim_product`, `vw_dim_customer`/`vw_dim_reseller`, `vw_dim_territory`, `vw_dim_date`, `vw_inventory_latest`, `vw_monthly_kpis`), each with a stated grain.
- Join-grain safety: never join an order-level aggregate to line-level data without re-aggregating; add a validation query for any join that could multiply revenue (compare totals before/after the join).
- Cross-check every headline aggregate two ways (e.g. fact total vs staging total).

Gate: the user runs queries and pastes outputs; only then write interpretations.

---

## Stage 6: Python/Pandas notebooks (`python/`)

Create four well-commented notebooks, each beginning with a markdown purpose cell and ending with findings that cite actual outputs:
1. `01_data_profiling.ipynb`: dimensions, dtypes, samples, missing values, duplicates, date ranges, categories; save a data-quality report.
2. `02_data_cleaning.ipynb`: convert dates/numerics, documented missing-value rules, duplicates, FK validation, financial checks; write to `data/processed/` only.
3. `03_exploratory_analysis.ipynb`: trends, product/category, territory, channel comparison, price/quantity distributions, outlier investigation; readable titles/axis labels; no unnecessary ML. Only add forecasting if the monthly history is long and regular enough to defend; otherwise state it was skipped and why.
4. `04_sql_python_validation.ipynb`: compare selected SQL aggregates with Pandas (net sales, orders, units, margin by channel/category), explain any discrepancy (rounding, NULLs, join grain), show the diff table.

Use SQLAlchemy+pymysql with credentials from `.env`. Do not claim a notebook ran unless it was executed and outputs are saved; otherwise tell the user to run it.

---

## Stage 7: Power BI documentation (the `.pbix` is built by the user)

Antigravity cannot be assumed to produce a working `.pbix`. Do not claim one exists. Write guides in `powerbi/`:
- `model_relationships.md`: star schema, tables (views from Stage 5), keys, relationship direction and cardinality (one-to-many dimension to fact), a proper Date table (marked as date table), inactive relationships if needed, a note on connecting Power BI to MySQL (the MySQL connector must be installed; fallback: import CSV exports of the views).
- `dax_measures.md`: exact measures, each with a plain explanation, e.g. Net Sales, Gross Sales, Discount Amount, Units Sold, Orders (DISTINCTCOUNT of order number), AOV (DIVIDE), Gross Profit and Margin % (labelled standard-cost basis), MoM Growth using prior month via DATEADD/PREVIOUSMONTH, Revenue % of Total (ALL/ALLSELECTED), rank measures, stock vs reorder point measures. Test every measure's logic against SQL totals.
- `dashboard_build_guide.md`: three pages with field assignments, visual types, slicers, interactions, drill-through, formatting/layout, tooltips:
  1. Executive Overview (KPI cards, monthly trend, revenue by category, sales by territory, date/territory/product slicers).
  2. Product and Sales Intelligence (top/bottom N, category contribution, units vs revenue scatter, product trend, Retail vs Wholesale comparison, drill-through detail page).
  3. Inventory and Operational Insights (stock vs reorder point, replenishment priority list, discount impact). Replace unsupported metrics (payment fees, warehouse stock, returns) with supported ones and note why on the page.
- A validation checklist: totals on cards match SQL results, slicers behave, no double counting, blank/unknown members reviewed.
- Screenshot instructions for `powerbi/screenshots/` (the user captures them; never fabricate screenshots).

---

## Stage 8: Findings, documentation and portfolio package

Only after the user has run analyses and shared real outputs:
- `docs/findings_and_recommendations.md` and `reports/executive_summary.md`: for each finding give metric, period, actual result, business significance, recommended action, uncertainty/limitation. No invented percentages, rankings or impact estimates.
- `docs/limitations.md`: synthetic bicycle data; standard cost is a model value; no returns/payment fees/warehouse-level data; inventory at product level; territory instead of warehouse; any SCD or date-range caveats found.
- Full `README.md`: title and disclosure of data source and fictional nature, overview, problem statement, features, stack, Mermaid architecture and schema diagrams, setup/run instructions for Windows (order of scripts), screenshots (only real ones), sample queries, key findings (real), limitations, future work, dataset attribution and licence (verify the licence on the Microsoft repository; keep the notice).
- Resume bullet and a 60-second interview explanation, both truthful about what was and was not done.
- Ten technical interview questions with answers grounded in this repository's actual implementation (grain, double counting, window functions used, join traps, data quality decisions, DAX measures).
- Final pass: `.gitignore` check, no credentials or raw data committed, no unused files, consistent naming, `requirements.txt` pinned to versions actually used, a "how to reproduce" section tested by actually following it where possible.

---

## Stage-completion report template (use after every stage)

```
Stage N complete
- Files created/changed:
- How to run:
- Tests performed (and on what data):
- Actual results observed:
- Problems / unverified items:
- Decision(s) needed from the user:
- Proposed next step (waiting for confirmation):
```
