"""
MotoPulse 360: Power BI Template (.pbit) Packager
-------------------------------------------------
Packages the verified Tabular Model (model.bim) and Report Definition (report.json)
into an official Power BI Template (.pbit) archive.
"""

import os
import zipfile
import json

REPORT_JSON_PATH = os.path.join("powerbi", "MotoPulse_360_Analytics.Report", "report.json")
MODEL_BIM_PATH = os.path.join("powerbi", "MotoPulse_360_Analytics.SemanticModel", "model.bim")
OUTPUT_PBIT = os.path.join("powerbi", "MotoPulse_360_Analytics.pbit")

print("=" * 80)
print("MotoPulse 360: Packaging Power BI Template (.pbit)")
print("=" * 80)

with open(REPORT_JSON_PATH, "r", encoding="utf-8") as f:
    layout_content = f.read()

with open(MODEL_BIM_PATH, "r", encoding="utf-8") as f:
    schema_content = f.read()

content_types_xml = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="" />
  <Override PartName="/DataModelSchema" ContentType="" />
  <Override PartName="/Report/Layout" ContentType="" />
  <Override PartName="/Version" ContentType="" />
  <Override PartName="/Settings" ContentType="" />
</Types>"""

version_str = "1.28"
settings_json = json.dumps({"locale": "en-US"})

with zipfile.ZipFile(OUTPUT_PBIT, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types_xml.encode("utf-8"))
    z.writestr("Version", version_str.encode("utf-16le"))
    z.writestr("Settings", settings_json.encode("utf-16le"))
    z.writestr("DataModelSchema", schema_content.encode("utf-16le"))
    z.writestr("Report/Layout", layout_content.encode("utf-16le"))

print(f"Successfully generated: {OUTPUT_PBIT} ({os.path.getsize(OUTPUT_PBIT):,} bytes)")
print("=" * 80)
