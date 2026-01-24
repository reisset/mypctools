---
name: xlsx-expert
description: Create and modify Excel spreadsheets (.xlsx) using LibreOffice CLI. Use for spreadsheet generation, data manipulation, and conversion tasks.
allowed-tools: Read, Write, Bash, Glob
---

# XLSX Expert

Handle Excel spreadsheet operations using LibreOffice headless mode.

## Common Operations

### Convert to XLSX
```bash
# From ODS, CSV, etc.
libreoffice --headless --convert-to xlsx --outdir /output/path /path/to/file.ods
libreoffice --headless --convert-to xlsx data.csv
```

### Convert from XLSX
```bash
# To CSV (first sheet only by default)
libreoffice --headless --convert-to csv spreadsheet.xlsx

# To ODS
libreoffice --headless --convert-to ods spreadsheet.xlsx

# To PDF
libreoffice --headless --convert-to pdf spreadsheet.xlsx
```

### Batch Convert
```bash
libreoffice --headless --convert-to xlsx --outdir ./excel *.csv
```

## Creating Spreadsheets from CSV

### Basic CSV to XLSX
```bash
# Create CSV file
cat > data.csv << 'EOF'
Name,Age,City
Alice,30,NYC
Bob,25,LA
Carol,35,Chicago
EOF

# Convert to XLSX
libreoffice --headless --convert-to xlsx data.csv
```

### CSV with Formulas
LibreOffice preserves formulas when converting:
```csv
Item,Quantity,Price,Total
Widget,10,5.00,=B2*C2
Gadget,5,10.00,=B3*C3
```

## Data Manipulation Workflow

### Extract and Modify Data
1. Convert XLSX to CSV: `libreoffice --headless --convert-to csv file.xlsx`
2. Manipulate with standard tools:
```bash
# Filter rows
awk -F',' '$3 > 100' data.csv > filtered.csv

# Add column
awk -F',' 'BEGIN{OFS=","} {print $0, $2*1.1}' data.csv > with_tax.csv

# Sort
sort -t',' -k2 -n data.csv > sorted.csv
```
3. Convert back: `libreoffice --headless --convert-to xlsx modified.csv`

### Multiple Sheets
CSV only exports first sheet. For multi-sheet operations:
1. Convert to ODS (preserves sheets)
2. Extract and edit XML
3. Convert back to XLSX

## ODS XML Editing (Advanced)

```bash
# Extract ODS
unzip spreadsheet.ods -d ods_contents/

# Edit content.xml for data changes
# - <table:table> elements are sheets
# - <table:table-row> elements are rows
# - <table:table-cell> elements are cells

# Repackage
cd ods_contents && zip -r ../modified.ods *

# Convert to XLSX
libreoffice --headless --convert-to xlsx modified.ods
```

## Tips
- CSV is the easiest interchange format for data manipulation
- Formulas are preserved in ODS/XLSX conversions
- Complex formatting (merged cells, conditional formatting) may not survive CSV round-trips
- For pure data work, stay in CSV as long as possible
- Use `--infilter` option for CSV import settings if needed:
  ```bash
  libreoffice --headless --convert-to xlsx --infilter="CSV:44,34,UTF8" data.csv
  # 44=comma, 34=quote char, UTF8=encoding
  ```
