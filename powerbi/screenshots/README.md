# MotoPulse 360: Power BI Dashboard Screenshots

This directory stores authentic visual captures of the active MotoPulse 360 Power BI Desktop reports.

## Instructions for Portfolio Creator

1. Open Power BI Desktop and load the pre-built dataset using either:
   - Clean CSV files from `data/processed/powerbi/`
   - Direct connection to MySQL `motopulse360` views
2. Follow the design instructions in `powerbi/dashboard_build_guide.md` and implement the 3 pages:
   - **`01_executive_overview.png`**: Page 1 Executive Overview with KPI cards, monthly trends, and category distribution.
   - **`02_product_channel_intelligence.png`**: Page 2 Product & Channel Intelligence with scatter plot, subcategory margin matrix, and discount leakage chart.
   - **`03_inventory_operational_alerts.png`**: Page 3 Supply Chain & Replenishment Center with stock status donut and priority procurement action grid.
3. Save your Power BI project file as `MotoPulse_360_Analytics.pbix` in `powerbi/`.
4. Capture high-resolution full-screen PNG screenshots (16:9 aspect ratio, 1920x1080 recommended) and save them in this folder with the names:
   - `powerbi/screenshots/01_executive_overview.png`
   - `powerbi/screenshots/02_product_channel_intelligence.png`
   - `powerbi/screenshots/03_inventory_operational_alerts.png`
5. The root `README.md` is pre-configured to link directly to these screenshot paths.
