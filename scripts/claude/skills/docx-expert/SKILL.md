---
name: docx-expert
description: Create and modify Word documents (.docx) using LibreOffice CLI. Use for document generation, conversion, and editing tasks.
allowed-tools: Read, Write, Bash, Glob
---

# DOCX Expert

Handle Word document operations using LibreOffice headless mode.

## Common Operations

### Convert to DOCX
```bash
# From ODT, RTF, TXT, HTML, etc.
libreoffice --headless --convert-to docx --outdir /output/path /path/to/file.odt
```

### Convert from DOCX
```bash
# To PDF
libreoffice --headless --convert-to pdf document.docx

# To ODT (for easier editing)
libreoffice --headless --convert-to odt document.docx

# To plain text
libreoffice --headless --convert-to txt document.docx

# To HTML
libreoffice --headless --convert-to html document.docx
```

### Batch Convert
```bash
libreoffice --headless --convert-to docx --outdir ./docs *.odt
```

## Creating Documents from Scratch

### From Plain Text
1. Write content to a `.txt` file
2. Convert: `libreoffice --headless --convert-to docx content.txt`

### From HTML (better formatting control)
1. Create HTML with styling:
```html
<html>
<body>
<h1>Title</h1>
<p>Paragraph with <strong>bold</strong> and <em>italic</em>.</p>
<ul>
  <li>List item 1</li>
  <li>List item 2</li>
</ul>
</body>
</html>
```
2. Convert: `libreoffice --headless --convert-to docx document.html`

### From Markdown (via pandoc)
```bash
pandoc document.md -o document.docx
```

## Modification Workflow

To modify an existing DOCX:
1. Convert to ODT: `libreoffice --headless --convert-to odt file.docx`
2. The ODT is XML-based and can be manipulated:
   - Unzip: `unzip file.odt -d odt_contents/`
   - Edit `content.xml` for text changes
   - Rezip: `cd odt_contents && zip -r ../modified.odt *`
3. Convert back: `libreoffice --headless --convert-to docx modified.odt`

### Direct XML Editing (advanced)
DOCX is also a zip archive:
```bash
unzip document.docx -d docx_contents/
# Edit word/document.xml
zip -r modified.docx docx_contents/*
```

## Templates
For repeated document generation:
1. Create a template DOCX with placeholder text like `{{NAME}}`, `{{DATE}}`
2. Convert to ODT, extract, use sed/awk to replace placeholders
3. Repackage and convert back to DOCX

## Tips
- ODT is easier to manipulate programmatically than DOCX
- Use HTML as intermediate format for complex formatting
- Preserve original files before modification
- Test conversions - complex formatting may shift slightly
