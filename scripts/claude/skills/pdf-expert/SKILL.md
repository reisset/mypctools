---
name: pdf-expert
description: Create, convert, and modify PDF files using LibreOffice CLI. Use for PDF generation, conversion, and manipulation tasks.
allowed-tools: Read, Write, Bash, Glob
---

# PDF Expert

Handle PDF operations using LibreOffice headless mode.

## Common Operations

### Convert to PDF
```bash
# From any supported format (docx, odt, xlsx, pptx, html, txt, etc.)
libreoffice --headless --convert-to pdf --outdir /output/path /path/to/file.docx
```

### Convert from PDF
```bash
# To editable format (limited - works best with simple PDFs)
libreoffice --headless --convert-to odt --outdir /output/path /path/to/file.pdf
```

### Batch Convert
```bash
# Convert all docx files in a directory
libreoffice --headless --convert-to pdf --outdir ./pdfs *.docx
```

### Merge PDFs
If `pdftk` is available:
```bash
pdftk file1.pdf file2.pdf cat output merged.pdf
```

Alternative with `pdfunite` (poppler-utils):
```bash
pdfunite file1.pdf file2.pdf merged.pdf
```

### Split PDF
```bash
# Extract pages 1-5
pdftk input.pdf cat 1-5 output pages1-5.pdf

# Extract single page
pdftk input.pdf cat 3 output page3.pdf
```

### PDF Info
```bash
# Get page count and metadata
pdfinfo document.pdf
```

## Creating PDFs from Scratch

1. Create content in a text/markdown file
2. Convert to ODT or use HTML
3. Convert to PDF:
```bash
# From HTML
libreoffice --headless --convert-to pdf report.html

# From markdown (via pandoc if available)
pandoc report.md -o report.pdf
```

## Workflow for Modifications

To modify an existing PDF:
1. Convert PDF to ODT: `libreoffice --headless --convert-to odt file.pdf`
2. Edit the ODT file (Read/Edit tools or LibreOffice)
3. Convert back to PDF: `libreoffice --headless --convert-to pdf file.odt`
4. Clean up temporary ODT

## Tips
- Always use `--headless` for CLI operation
- Use `--outdir` to control output location
- LibreOffice locks files during conversion - don't run parallel conversions on same file
- Complex PDFs (scanned, forms) may not convert cleanly to editable formats
