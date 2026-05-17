#!/usr/bin/env python3
"""Конвертер Markdown → красивый самодостаточный HTML для отправки клиенту."""

import sys
import markdown
from pathlib import Path

if len(sys.argv) < 3:
    print("Usage: python3 _md2html.py <input.md> <output.html> [<title>]")
    sys.exit(1)

input_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
title = sys.argv[3] if len(sys.argv) > 3 else input_path.stem

md_text = input_path.read_text(encoding="utf-8")

html_body = markdown.markdown(
    md_text,
    extensions=["tables", "fenced_code", "toc", "sane_lists"],
)

html = f"""<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>{title}</title>
<style>
@page {{
  size: A4;
  margin: 18mm 16mm 18mm 16mm;
}}

* {{ box-sizing: border-box; }}

html, body {{
  font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif;
  font-size: 10.5pt;
  line-height: 1.55;
  color: #1c1c1c;
  background: #fff;
  margin: 0;
  padding: 0;
}}

body {{ max-width: 178mm; margin: 0 auto; padding: 4mm; }}

h1 {{
  font-size: 22pt;
  font-weight: 700;
  margin: 0 0 4mm 0;
  color: #103206;
  page-break-after: avoid;
  border-bottom: 2pt solid #103206;
  padding-bottom: 3mm;
}}

h2 {{
  font-size: 16pt;
  font-weight: 700;
  color: #103206;
  margin: 10mm 0 4mm 0;
  padding-bottom: 2mm;
  border-bottom: 1pt solid #c4c4c4;
  page-break-after: avoid;
}}

h3 {{
  font-size: 13pt;
  font-weight: 700;
  color: #103206;
  margin: 6mm 0 3mm 0;
  page-break-after: avoid;
}}

h4 {{
  font-size: 11.5pt;
  font-weight: 700;
  color: #103206;
  margin: 4mm 0 2mm 0;
  page-break-after: avoid;
}}

p {{ margin: 0 0 3mm 0; }}

ul, ol {{ margin: 0 0 3mm 0; padding-left: 6mm; }}
li {{ margin-bottom: 1mm; }}

table {{
  border-collapse: collapse;
  width: 100%;
  margin: 0 0 4mm 0;
  font-size: 9.5pt;
  page-break-inside: avoid;
}}

table th, table td {{
  border: 0.5pt solid #c4c4c4;
  padding: 2mm 3mm;
  text-align: left;
  vertical-align: top;
}}

table th {{
  background: #f4f0e8;
  font-weight: 700;
  color: #103206;
}}

table tr:nth-child(even) td {{ background: #fafaf7; }}

blockquote {{
  margin: 0 0 4mm 0;
  padding: 3mm 5mm;
  background: #f4f0e8;
  border-left: 3pt solid #c99700;
  font-style: italic;
  color: #2c2c2c;
}}

blockquote p {{ margin: 0; }}

code {{
  background: #f4f0e8;
  padding: 0.5mm 1.5mm;
  border-radius: 1mm;
  font-family: 'SF Mono', 'Menlo', 'Monaco', monospace;
  font-size: 9pt;
  color: #103206;
}}

pre {{
  background: #f4f0e8;
  padding: 4mm;
  border-radius: 2mm;
  border-left: 3pt solid #103206;
  page-break-inside: avoid;
  overflow-x: auto;
  margin: 0 0 4mm 0;
}}

pre code {{
  background: transparent;
  padding: 0;
  font-size: 9pt;
  display: block;
  line-height: 1.4;
}}

hr {{
  border: none;
  border-top: 1pt solid #c4c4c4;
  margin: 6mm 0;
}}

strong {{ color: #103206; }}

a {{ color: #c99700; text-decoration: none; }}
a:hover {{ text-decoration: underline; }}

.no-break {{ page-break-inside: avoid; }}
</style>
</head>
<body>
{html_body}
</body>
</html>
"""

output_path.write_text(html, encoding="utf-8")
print(f"OK: {output_path}")
