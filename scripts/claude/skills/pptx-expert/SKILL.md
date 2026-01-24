---
name: pptx-expert
description: Create and modify PowerPoint presentations (.pptx) using LibreOffice CLI. Use for presentation generation, conversion, and slide manipulation.
allowed-tools: Read, Write, Bash, Glob
---

# PPTX Expert

Handle PowerPoint presentation operations using LibreOffice headless mode.

## Common Operations

### Convert to PPTX
```bash
# From ODP, PPT, etc.
libreoffice --headless --convert-to pptx --outdir /output/path /path/to/file.odp
```

### Convert from PPTX
```bash
# To PDF (great for sharing)
libreoffice --headless --convert-to pdf presentation.pptx

# To ODP (for editing)
libreoffice --headless --convert-to odp presentation.pptx

# To images (one per slide)
libreoffice --headless --convert-to png presentation.pptx
```

### Batch Convert
```bash
libreoffice --headless --convert-to pptx --outdir ./presentations *.odp
```

## Creating Presentations

### From HTML
Create slides using HTML structure:
```html
<html>
<body>
<h1>Slide 1 Title</h1>
<p>Content for first slide</p>

<h1>Slide 2 Title</h1>
<ul>
  <li>Bullet point 1</li>
  <li>Bullet point 2</li>
</ul>
</body>
</html>
```
Convert: `libreoffice --headless --convert-to pptx slides.html`

### From Markdown (via pandoc)
```bash
pandoc presentation.md -o presentation.pptx
```

Markdown format for slides:
```markdown
# Slide 1 Title

First slide content

---

# Slide 2 Title

- Bullet 1
- Bullet 2

---

# Slide 3

More content here
```

## Modification Workflow

### Edit via ODP
1. Convert: `libreoffice --headless --convert-to odp presentation.pptx`
2. Extract: `unzip presentation.odp -d odp_contents/`
3. Edit `content.xml`:
   - `<draw:page>` elements are slides
   - `<draw:frame>` contains text boxes
   - `<text:p>` contains text
4. Repackage: `cd odp_contents && zip -r ../modified.odp *`
5. Convert back: `libreoffice --headless --convert-to pptx modified.odp`

### Extract Text
```bash
# Convert to plain text for review/editing
libreoffice --headless --convert-to txt presentation.pptx
```

## Slide Manipulation

### Extract Single Slide as Image
```bash
# Convert to images, then select the one you need
libreoffice --headless --convert-to png presentation.pptx
# Creates presentation-1.png, presentation-2.png, etc.
```

### Merge Presentations
No direct CLI method. Workflow:
1. Convert both to ODP
2. Extract both
3. Copy `<draw:page>` elements from one content.xml to another
4. Update manifest.xml if needed
5. Repackage and convert to PPTX

## Tips
- ODP is the best intermediate format for manipulation
- HTML to PPTX gives basic slides - no fancy transitions
- Pandoc produces cleaner PPTX from Markdown than LibreOffice HTML conversion
- For complex presentations, edit in LibreOffice GUI when possible
- PNG export is useful for embedding slides in other documents
- Slide dimensions: default is 10"x7.5" (widescreen) or 10"x7.5" (4:3)
