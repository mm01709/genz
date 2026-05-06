import markdown
import weasyprint
import os

md_path = r"D:\myapp\GenZ\GENZ_AWS_Documentation.md"
pdf_path = r"D:\myapp\GenZ\GENZ_AWS_Documentation.pdf"

with open(md_path, encoding="utf-8") as f:
    md_text = f.read()

html_body = markdown.markdown(
    md_text,
    extensions=["fenced_code", "tables", "toc"]
)

html = f"""<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="UTF-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap');
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    font-family: 'Cairo', 'Segoe UI', Arial, sans-serif;
    font-size: 13px;
    line-height: 1.8;
    color: #1a1a2e;
    background: #ffffff;
    padding: 40px 50px;
    direction: rtl;
  }}
  h1 {{
    font-size: 28px;
    font-weight: 900;
    color: #1a1a2e;
    border-bottom: 4px solid #6c63ff;
    padding-bottom: 12px;
    margin: 36px 0 20px;
    page-break-before: always;
  }}
  h1:first-of-type {{ page-break-before: avoid; }}
  h2 {{
    font-size: 20px;
    font-weight: 700;
    color: #6c63ff;
    border-right: 5px solid #6c63ff;
    padding-right: 12px;
    margin: 28px 0 14px;
  }}
  h3 {{
    font-size: 16px;
    font-weight: 700;
    color: #2d3748;
    margin: 20px 0 10px;
  }}
  h4 {{
    font-size: 14px;
    font-weight: 700;
    color: #4a5568;
    margin: 16px 0 8px;
  }}
  p {{
    margin-bottom: 10px;
  }}
  code {{
    background: #f0f0f8;
    color: #c7254e;
    padding: 2px 6px;
    border-radius: 4px;
    font-family: 'Courier New', monospace;
    font-size: 12px;
    direction: ltr;
    unicode-bidi: embed;
  }}
  pre {{
    background: #1a1a2e;
    color: #e2e8f0;
    padding: 16px 20px;
    border-radius: 10px;
    overflow-x: auto;
    margin: 14px 0;
    direction: ltr;
    text-align: left;
    font-family: 'Courier New', monospace;
    font-size: 11.5px;
    line-height: 1.6;
    border-right: 4px solid #6c63ff;
  }}
  pre code {{
    background: none;
    color: #e2e8f0;
    padding: 0;
    border-radius: 0;
    font-size: 11.5px;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    font-size: 12px;
  }}
  th {{
    background: #6c63ff;
    color: white;
    padding: 10px 14px;
    text-align: right;
    font-weight: 700;
  }}
  td {{
    padding: 9px 14px;
    border-bottom: 1px solid #e2e8f0;
    text-align: right;
  }}
  tr:nth-child(even) td {{ background: #f8f8ff; }}
  tr:hover td {{ background: #f0efff; }}
  blockquote {{
    background: #f0efff;
    border-right: 5px solid #6c63ff;
    padding: 12px 16px;
    margin: 14px 0;
    border-radius: 0 8px 8px 0;
    color: #4a5568;
  }}
  ul, ol {{
    margin: 10px 0 10px 0;
    padding-right: 24px;
  }}
  li {{ margin-bottom: 5px; }}
  hr {{
    border: none;
    border-top: 2px solid #e2e8f0;
    margin: 30px 0;
  }}
  strong {{ color: #1a1a2e; font-weight: 700; }}
  em {{ color: #6c63ff; }}
  .page-break {{ page-break-before: always; }}
</style>
</head>
<body>
{html_body}
</body>
</html>"""

print("Converting to PDF...")
weasyprint.HTML(string=html, base_url=os.path.dirname(md_path)).write_pdf(pdf_path)
print(f"Done! PDF saved to: {pdf_path}")
