"""
MotoPulse 360 - Stage 2: inspect raw source files.

Purpose
-------
The AdventureWorksDW CSV files are not plain UTF-8 comma files, so we first
DETECT how each file is encoded and delimited, then print a profile.
This script only READS data/raw. It never modifies or deletes anything.

Run from the project root:
    python python/00_inspect_raw_files.py
Optional: only some tables
    python python/00_inspect_raw_files.py FactInternetSales DimProduct
"""
import sys
from pathlib import Path

import pandas as pd

RAW_DIR = Path("data/raw")
REPORT_DIR = Path("data/processed")
KEY_TABLES = [
    "DimDate", "DimProduct", "DimProductSubcategory", "DimProductCategory",
    "DimCustomer", "DimReseller", "DimSalesTerritory",
    "FactInternetSales", "FactResellerSales", "FactProductInventory",
]
# Delimiters to try, most likely first. "+|" is a multi-character delimiter.
CANDIDATE_DELIMS = ["\t", "|", "+|", ",", ";"]


def detect_encoding(path: Path) -> str:
    """Look at the first bytes (the BOM) to guess the text encoding."""
    head = path.read_bytes()[:4]
    if head.startswith(b"\xff\xfe"):
        return "utf-16"          # UTF-16 little endian with BOM
    if head.startswith(b"\xfe\xff"):
        return "utf-16"          # UTF-16 big endian with BOM
    if head.startswith(b"\xef\xbb\xbf"):
        return "utf-8-sig"
    # No BOM: try UTF-8, otherwise fall back to latin-1 (never fails)
    try:
        path.read_bytes()[:200000].decode("utf-8")
        return "utf-8"
    except UnicodeDecodeError:
        return "latin-1"


def detect_delimiter(path: Path, encoding: str) -> str:
    """Pick the delimiter that splits the first lines into the same number of fields (>1)."""
    with open(path, encoding=encoding, errors="replace") as fh:
        lines = [fh.readline() for _ in range(5)]
    lines = [ln.rstrip("\r\n") for ln in lines if ln.strip()]
    best, best_fields = None, 1
    for delim in CANDIDATE_DELIMS:
        counts = {len(ln.split(delim)) for ln in lines}
        if len(counts) == 1:                       # consistent across lines
            n = counts.pop()
            if n > best_fields:
                best, best_fields = delim, n
    return best or ","


def load(path: Path):
    enc = detect_encoding(path)
    delim = detect_delimiter(path, enc)
    # DW files have no header row in some releases; we detect by checking
    # whether the first row looks like column names (no digits at all).
    with open(path, encoding=enc, errors="replace") as fh:
        first = fh.readline().rstrip("\r\n").split(delim)
    has_header = not any(any(ch.isdigit() for ch in cell) for cell in first)
    df = pd.read_csv(
        path,
        sep=delim if len(delim) == 1 else delim,
        engine="python" if len(delim) > 1 else "c",
        encoding=enc,
        header=0 if has_header else None,
        dtype=str,                  # read EVERYTHING as text; we convert later, deliberately
        keep_default_na=False,
        on_bad_lines="warn",
    )
    return df, enc, delim, has_header


def date_like_columns(df: pd.DataFrame):
    """Report min/max for columns that look like dates (YYYY-MM-DD text) or DateKeys (YYYYMMDD)."""
    out = []
    for col in df.columns:
        s = df[col].astype(str).str.strip()
        s = s[s != ""]
        if s.empty:
            continue
        name = str(col).lower()
        if s.str.fullmatch(r"\d{4}-\d{2}-\d{2}.*").mean() > 0.95:
            d = pd.to_datetime(s.str[:10], errors="coerce")
            out.append((col, str(d.min().date()), str(d.max().date())))
        elif "datekey" in name and s.str.fullmatch(r"\d{8}").mean() > 0.95:
            d = pd.to_datetime(s, format="%Y%m%d", errors="coerce")
            out.append((col, str(d.min().date()), str(d.max().date())))
    return out


def main() -> int:
    if not RAW_DIR.exists():
        print(f"ERROR: {RAW_DIR} not found. Run this from the project root.")
        return 1
    wanted = sys.argv[1:] or KEY_TABLES
    files = {p.stem: p for p in RAW_DIR.rglob("*.csv")}
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    summary = []

    for table in wanted:
        path = files.get(table)
        if path is None:
            print(f"\n[MISSING] {table}.csv not found under {RAW_DIR}")
            summary.append({"table": table, "status": "missing"})
            continue
        try:
            df, enc, delim, has_header = load(path)
        except Exception as exc:  # report and continue with the other files
            print(f"\n[FAILED] {table}: {exc}")
            summary.append({"table": table, "status": f"failed: {exc}"})
            continue

        print("\n" + "=" * 70)
        print(f"{table}   ({path})")
        print(f"encoding={enc!r}  delimiter={delim!r}  header_row={has_header}")
        print(f"rows={len(df):,}  columns={df.shape[1]}")
        print("columns:", list(df.columns))
        print(df.head(3).to_string(max_colwidth=25))
        for col, lo, hi in date_like_columns(df):
            print(f"date-like column {col!r}: {lo} -> {hi}")
        summary.append({
            "table": table, "status": "ok", "encoding": enc,
            "delimiter": repr(delim), "has_header": has_header,
            "rows": len(df), "columns": df.shape[1],
        })

    pd.DataFrame(summary).to_csv(REPORT_DIR / "raw_file_inspection.csv", index=False)
    print(f"\nSummary written to {REPORT_DIR / 'raw_file_inspection.csv'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
