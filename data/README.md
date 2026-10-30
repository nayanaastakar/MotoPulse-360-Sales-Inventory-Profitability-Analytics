# data/

Source datasets are NOT included in this archive.

## Expected placement
Download the AdventureWorksDW data-warehouse install script zip from Microsoft's
AdventureWorks page (https://github.com/Microsoft/sql-server-samples/blob/master/samples/databases/adventure-works/README.md),
extract it, and place the CSV files under `data/raw/` (nested folders are fine; the
inspection script searches subfolders).

Exact zip filename and file layout were NOT verified by Claude (GitHub could not be
fetched in its environment). Confirm them yourself.

## Rules
- `data/raw/` is read-only source data. Never edit or overwrite it.
- `data/processed/` holds generated outputs (e.g. raw_file_inspection.csv).
- Licence: Microsoft's sql-server-samples repository was reported as MIT-licensed in
  search results; confirm on the repository's LICENSE file before redistributing anything.
