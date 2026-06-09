import re
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, Preformatted, Frame, KeepInFrame
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

PDF_PATH = r"d:\myapp\GenZ\Chapter5_Mobile_Application.pdf"
MD_PATH  = r"d:\myapp\GenZ\Chapter5_Mobile_Application.md"

# ── Colour palette ──────────────────────────────────────────────────────────
NAVY      = colors.HexColor("#1e3a5f")
BLUE      = colors.HexColor("#2563eb")
LIGHT_BG  = colors.HexColor("#e8f0fe")
CODE_BG   = colors.HexColor("#1e293b")
CODE_FG   = colors.HexColor("#e2e8f0")
TABLE_HDR = colors.HexColor("#1e3a5f")
TABLE_ALT = colors.HexColor("#f8faff")
GREY_TEXT = colors.HexColor("#4b5563")
BORDER    = colors.HexColor("#c7d2e8")
WHITE     = colors.white

# ── Page setup ───────────────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4
LEFT = RIGHT = 2.2 * cm
TOP  = BOT   = 2.2 * cm

def make_styles():
    base = getSampleStyleSheet()
    def s(name, **kw):
        return ParagraphStyle(name, **kw)

    return {
        "cover_title": s("cover_title",
            fontSize=26, leading=32, textColor=NAVY,
            alignment=TA_CENTER, fontName="Helvetica-Bold"),
        "cover_sub": s("cover_sub",
            fontSize=14, leading=20, textColor=BLUE,
            alignment=TA_CENTER, fontName="Helvetica-Bold"),
        "cover_meta": s("cover_meta",
            fontSize=10, leading=16, textColor=GREY_TEXT,
            alignment=TA_CENTER, fontName="Helvetica"),

        "h1": s("h1",
            fontSize=16, leading=22, textColor=NAVY,
            fontName="Helvetica-Bold", spaceAfter=8,
            spaceBefore=20, borderPad=6,
            backColor=LIGHT_BG, borderColor=BLUE,
            borderWidth=0, leftIndent=0),
        "h2": s("h2",
            fontSize=13, leading=18, textColor=NAVY,
            fontName="Helvetica-Bold", spaceAfter=6,
            spaceBefore=14),
        "h3": s("h3",
            fontSize=11, leading=16, textColor=NAVY,
            fontName="Helvetica-Bold", spaceAfter=4,
            spaceBefore=10),

        "body": s("body",
            fontSize=10, leading=15, textColor=colors.HexColor("#1a1a2e"),
            fontName="Helvetica", spaceAfter=6, alignment=TA_JUSTIFY),
        "bullet": s("bullet",
            fontSize=10, leading=14, textColor=colors.HexColor("#1a1a2e"),
            fontName="Helvetica", spaceAfter=3,
            leftIndent=14, firstLineIndent=0, bulletIndent=4),
        "code": s("code",
            fontSize=8, leading=12, textColor=CODE_FG,
            fontName="Courier", backColor=CODE_BG,
            spaceAfter=8, spaceBefore=6,
            leftIndent=8, rightIndent=8, borderPad=8),
        "toc_main": s("toc_main",
            fontSize=10.5, leading=16, textColor=NAVY,
            fontName="Helvetica-Bold", spaceAfter=2),
        "toc_sub": s("toc_sub",
            fontSize=10, leading=14, textColor=GREY_TEXT,
            fontName="Helvetica", spaceAfter=1, leftIndent=14),
        "caption": s("caption",
            fontSize=8.5, leading=12, textColor=GREY_TEXT,
            fontName="Helvetica", spaceAfter=4, alignment=TA_CENTER),
    }

def header_footer(canvas, doc):
    canvas.saveState()
    w = PAGE_W - LEFT - RIGHT
    # header bar
    canvas.setFillColor(NAVY)
    canvas.rect(LEFT, PAGE_H - TOP + 4, w, 2, fill=1, stroke=0)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(GREY_TEXT)
    canvas.drawString(LEFT, PAGE_H - TOP + 8, "CHAPTER 5 — GEN Z STUDIO MOBILE APPLICATION")
    canvas.drawRightString(LEFT + w, PAGE_H - TOP + 8, "Graduation Project")
    # footer
    canvas.setFillColor(NAVY)
    canvas.rect(LEFT, BOT - 10, w, 1.5, fill=1, stroke=0)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(GREY_TEXT)
    canvas.drawCentredString(PAGE_W / 2, BOT - 20, f"Page {doc.page}")
    canvas.restoreState()

def parse_table(lines):
    rows = []
    for line in lines:
        if re.match(r"\|?\s*:?-+:?\s*\|", line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows

def md_inline(text, st):
    """Convert inline markdown (bold, code, italic) to Reportlab markup."""
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    # Bold
    text = re.sub(r"\*\*(.+?)\*\*", r'<b>\1</b>', text)
    # Inline code
    text = re.sub(r"`([^`]+)`", r'<font name="Courier" color="#c7254e" backColor="#fce7ec">\1</font>', text)
    # Italic
    text = re.sub(r"\*(.+?)\*", r'<i>\1</i>', text)
    return text

def _code_table(code_text, styles):
    """Render a code block as a Table with guaranteed dark background."""
    usable_w = PAGE_W - LEFT - RIGHT
    inner_w  = usable_w - 16   # 8pt padding each side

    code_style = ParagraphStyle("code_inner",
        fontSize=8, leading=12,
        fontName="Courier",
        textColor=CODE_FG,
        backColor=CODE_BG,
        leftIndent=0, rightIndent=0, borderPad=0)

    # Escape XML special chars, keep leading spaces by using non-breaking space trick
    def esc(line):
        line = line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        # Preserve leading spaces (reportlab strips them in Paragraph)
        stripped = line.lstrip(" ")
        leading  = len(line) - len(stripped)
        return " " * leading + stripped  # NBSP preserves indent

    paras = [Paragraph(esc(ln) if ln.strip() else " ", code_style)
             for ln in code_text.splitlines()]
    if not paras:
        paras = [Paragraph(" ", code_style)]

    tbl = Table([[p] for p in paras], colWidths=[inner_w])
    tbl.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, -1), CODE_BG),
        ("LEFTPADDING",  (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING",   (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 8),
        ("ROWBACKGROUNDS",(0,0),(-1,-1),[CODE_BG]),
        ("ROUNDEDCORNERS", [4]),
    ]))
    return tbl


def build_story(md_text, styles):
    story = []
    lines = md_text.splitlines()
    i = 0

    # ── Cover page ────────────────────────────────────────────────────────────
    story += [
        Spacer(1, 3*cm),
        Paragraph("GEN Z STUDIO", styles["cover_title"]),
        Spacer(1, 0.3*cm),
        Paragraph("Mobile Application Platform", styles["cover_sub"]),
        Spacer(1, 0.5*cm),
        HRFlowable(width="60%", thickness=3, color=BLUE, spaceAfter=12, hAlign="CENTER"),
        Spacer(1, 0.6*cm),
        Paragraph("CHAPTER 5", ParagraphStyle("ch5lbl",
            fontSize=20, leading=26, textColor=NAVY,
            alignment=TA_CENTER, fontName="Helvetica-Bold")),
        Paragraph("Mobile Application Development &amp; Architecture",
            ParagraphStyle("ch5sub", fontSize=13, leading=18,
                textColor=GREY_TEXT, alignment=TA_CENTER, fontName="Helvetica")),
        Spacer(1, 1.5*cm),
        Paragraph("Flutter &nbsp;·&nbsp; AWS Amplify &nbsp;·&nbsp; Amazon Cognito<br/>"
                  "AWS AppSync &nbsp;·&nbsp; DynamoDB &nbsp;·&nbsp; Amazon S3 &nbsp;·&nbsp; EC2",
                  styles["cover_meta"]),
        Spacer(1, 0.4*cm),
        Paragraph("Graduation Project — Module 2: Mobile Application", styles["caption"]),
        PageBreak(),
    ]

    # ── TOC ───────────────────────────────────────────────────────────────────
    story += [
        Paragraph("Table of Contents", ParagraphStyle("toc_hdr",
            fontSize=16, leading=22, textColor=NAVY, fontName="Helvetica-Bold",
            spaceAfter=10)),
        HRFlowable(width="100%", thickness=2, color=BLUE, spaceAfter=10),
    ]
    toc_entries = [
        ("5.1", "Introduction", False),
        ("5.2", "Technology Stack &amp; Development Framework", False),
        ("5.2.1", "Flutter -- In-Depth Framework Analysis", True),
        ("5.2.2", "AWS Amplify -- Cloud Backend Integration Layer", True),
        ("5.2.3", "Key Dependencies", True),
        ("5.3", "Application Architecture", False),
        ("5.3.1", "High-Level Architecture Overview", True),
        ("5.3.2", "Application Startup &amp; Navigation Flow", True),
        ("5.3.3", "Code Organization &amp; Module Structure", True),
        ("5.3.4", "State Management Strategy", True),
        ("5.4", "Authentication &amp; User Management", False),
        ("5.5", "Client-Facing Features &amp; User Interface", False),
        ("5.5.1", "Responsive Layout System", True),
        ("5.5.2", "Splash / Welcome Screen UI", True),
        ("5.5.3", "Home Screen -- Welcome Banner", True),
        ("5.5.4", "Studio Grid -- Responsive Display", True),
        ("5.5.5", "Services Catalog -- Category-Grouped Design", True),
        ("5.5.6", "Booking Form -- Detailed UI Walkthrough", True),
        ("5.6", "AI-Powered Chatbot -- Screen Design &amp; Technical Implementation", False),
        ("5.6.1", "Chatbot Screen UI", True),
        ("5.6.2", "Empty State -- Welcome Screen", True),
        ("5.6.3", "Message Bubbles", True),
        ("5.6.4", "Loading Indicator", True),
        ("5.6.5", "Message Input Area", True),
        ("5.6.6", "Backend Communication &amp; Session Management", True),
        ("5.6.7", "Booking Intent Detection &amp; Execution", True),
        ("5.7", "Real-Time Support Chat &amp; Ticket System", False),
        ("5.8", "Employee Administration Dashboard", False),
        ("5.8.1", "Dashboard Tab -- Booking Management", True),
        ("5.8.2", "Notification System -- Employee Side", True),
        ("5.8.3", "Wide-Screen Layout", True),
        ("5.9", "Notifications System", False),
        ("5.10", "Analytics &amp; Reporting", False),
        ("5.11", "Internationalization &amp; Responsive Design", False),
        ("5.12", "Database Schema &amp; Data Models", False),
        ("5.13", "Real-Time Synchronization Strategy", False),
        ("5.14", "User Interface Design -- Visual Language &amp; Design System", False),
        ("5.15", "Summary", False),
    ]
    for num, title, is_sub in toc_entries:
        st = styles["toc_sub"] if is_sub else styles["toc_main"]
        story.append(Paragraph(f"{num} &nbsp;&nbsp; {title}", st))
    story.append(PageBreak())

    # ── Parse markdown body ───────────────────────────────────────────────────
    in_code = False
    code_lines = []
    in_table = False
    table_lines = []

    while i < len(lines):
        line = lines[i]

        # fenced code block
        if line.strip().startswith("```"):
            if not in_code:
                in_code = True
                code_lines = []
            else:
                in_code = False
                code_text = "\n".join(code_lines)
                story.append(Spacer(1, 6))
                story.append(_code_table(code_text, styles))
                story.append(Spacer(1, 6))
                code_lines = []
            i += 1
            continue

        if in_code:
            code_lines.append(line)
            i += 1
            continue

        # table detection
        if "|" in line and not in_table:
            in_table = True
            table_lines = [line]
            i += 1
            continue

        if in_table:
            if "|" in line:
                table_lines.append(line)
                i += 1
                continue
            else:
                # flush table
                rows = parse_table(table_lines)
                if rows:
                    col_count = max(len(r) for r in rows)
                    # normalise
                    norm = [r + [""] * (col_count - len(r)) for r in rows]
                    # build styled cells
                    tdata = []
                    for ri, row in enumerate(norm):
                        styled = []
                        for cell in row:
                            cell = md_inline(cell, styles)
                            p_style = ParagraphStyle("tc",
                                fontSize=9, leading=13,
                                fontName="Helvetica-Bold" if ri == 0 else "Helvetica",
                                textColor=WHITE if ri == 0 else colors.HexColor("#1a1a2e"))
                            styled.append(Paragraph(cell, p_style))
                        tdata.append(styled)

                    col_w = (PAGE_W - LEFT - RIGHT) / col_count
                    col_widths = [col_w] * col_count

                    ts = TableStyle([
                        ("BACKGROUND", (0,0), (-1,0), TABLE_HDR),
                        ("GRID",       (0,0), (-1,-1), 0.5, BORDER),
                        ("ROWBACKGROUNDS", (0,1), (-1,-1), [WHITE, TABLE_ALT]),
                        ("TOPPADDING",  (0,0), (-1,-1), 6),
                        ("BOTTOMPADDING",(0,0),(-1,-1), 6),
                        ("LEFTPADDING", (0,0), (-1,-1), 8),
                        ("RIGHTPADDING",(0,0), (-1,-1), 8),
                        ("VALIGN",     (0,0), (-1,-1), "TOP"),
                    ])
                    t = Table(tdata, colWidths=col_widths, repeatRows=1)
                    t.setStyle(ts)
                    story.append(Spacer(1, 6))
                    story.append(t)
                    story.append(Spacer(1, 8))
                in_table = False
                table_lines = []
                continue

        # headings
        if line.startswith("# "):
            story.append(Spacer(1, 8))
            txt = md_inline(line[2:], styles)
            story.append(Paragraph(txt, styles["h1"]))
            story.append(HRFlowable(width="100%", thickness=2, color=BLUE, spaceAfter=6))
            i += 1; continue

        if line.startswith("## "):
            story.append(Spacer(1, 10))
            txt = md_inline(line[3:], styles)
            # blue left-bar effect via table
            bar_data = [[Paragraph(txt, ParagraphStyle("h2p",
                fontSize=13, leading=18, textColor=NAVY,
                fontName="Helvetica-Bold"))]]
            bar_t = Table(bar_data,
                colWidths=[PAGE_W - LEFT - RIGHT],
                style=TableStyle([
                    ("BACKGROUND",   (0,0), (-1,-1), LIGHT_BG),
                    ("LEFTPADDING",  (0,0), (-1,-1), 10),
                    ("RIGHTPADDING", (0,0), (-1,-1), 8),
                    ("TOPPADDING",   (0,0), (-1,-1), 6),
                    ("BOTTOMPADDING",(0,0), (-1,-1), 6),
                    ("LINEBEFORE",   (0,0), (0,-1), 4, BLUE),
                ]))
            story.append(bar_t)
            story.append(Spacer(1, 6))
            i += 1; continue

        if line.startswith("### "):
            story.append(Spacer(1, 8))
            txt = md_inline(line[4:], styles)
            story.append(Paragraph(txt, styles["h2"]))
            story.append(HRFlowable(width="100%", thickness=0.8, color=BORDER, spaceAfter=4))
            i += 1; continue

        if line.startswith("#### "):
            txt = md_inline(line[5:], styles)
            story.append(Paragraph(txt, styles["h3"]))
            i += 1; continue

        # HR
        if line.strip() in ("---", "***", "___"):
            story.append(HRFlowable(width="100%", thickness=1.5,
                color=BORDER, spaceAfter=8, spaceBefore=8))
            i += 1; continue

        # bullet
        if line.startswith("- ") or line.startswith("* "):
            txt = md_inline(line[2:], styles)
            story.append(Paragraph(f"• &nbsp; {txt}", styles["bullet"]))
            i += 1; continue

        # numbered list
        m = re.match(r"^(\d+)\.\s+(.*)", line)
        if m:
            txt = md_inline(m.group(2), styles)
            story.append(Paragraph(f"{m.group(1)}. &nbsp; {txt}", styles["bullet"]))
            i += 1; continue

        # blank line
        if line.strip() == "":
            story.append(Spacer(1, 4))
            i += 1; continue

        # normal paragraph
        txt = md_inline(line, styles)
        if txt.strip():
            story.append(Paragraph(txt, styles["body"]))
        i += 1

    return story


def main():
    with open(MD_PATH, encoding="utf-8") as f:
        md_text = f.read()

    styles = make_styles()

    doc = SimpleDocTemplate(
        PDF_PATH,
        pagesize=A4,
        leftMargin=LEFT, rightMargin=RIGHT,
        topMargin=TOP + 0.8*cm, bottomMargin=BOT + 0.6*cm,
        title="Chapter 5 — Gen Z Studio Mobile Application",
        author="Gen Z Studio Team",
    )

    story = build_story(md_text, styles)

    print("Generating PDF …")
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    size_kb = os.path.getsize(PDF_PATH) // 1024
    print(f"Done! -> {PDF_PATH}")
    print(f"Size  : {size_kb} KB")

if __name__ == "__main__":
    main()
