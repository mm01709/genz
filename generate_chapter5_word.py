"""
Generate Chapter5_Mobile_Application.docx — styled to match Chapters 1-4
of the Gen Z Studio graduation project.

Style reference:
  - Chapter title: Bold, large, centered, navy
  - Section headers (x.x): Bold, 14pt, left-aligned, navy, underline
  - Sub-section (x.x.x): Bold, 12pt, navy
  - Body text: 11pt Calibri, justified, 1.15 line spacing
  - Bullets: • symbol, 11pt, bold term + colon pattern
  - Code blocks: Courier New 9pt in a shaded table
  - Tables: navy header row, alternating shading
"""

import re
import os
from docx import Document
from docx.shared import Pt, Cm, RGBColor, Inches, Emu
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

MD_PATH   = r"d:\myapp\GenZ\Chapter5_Mobile_Application.md"
DOCX_PATH = r"d:\myapp\GenZ\Chapter5_Mobile_Application.docx"

# ── Colours ────────────────────────────────────────────────────────────────────
NAVY       = RGBColor(0x1E, 0x3A, 0x5F)   # deep navy — chapter headers
DARK_NAVY  = RGBColor(0x0F, 0x1F, 0x3D)   # very dark navy for H1 bg
BLUE       = RGBColor(0x25, 0x63, 0xEB)   # accent blue
BODY_CLR   = RGBColor(0x1F, 0x2D, 0x3D)   # near-black body text
GREY       = RGBColor(0x4B, 0x55, 0x63)   # muted grey
LIGHT_HDR  = RGBColor(0xE8, 0xF2, 0xFF)   # very light blue tint for h2 bg
CODE_BG    = RGBColor(0x1E, 0x29, 0x3B)   # dark slate for code blocks
CODE_FG    = RGBColor(0xE2, 0xE8, 0xF0)   # light text on code
TABLE_HDR  = RGBColor(0x1E, 0x3A, 0x5F)   # navy table header
TABLE_ALT  = RGBColor(0xF0, 0xF4, 0xFA)   # faint blue alternating row
WHITE      = RGBColor(0xFF, 0xFF, 0xFF)
RED_CODE   = RGBColor(0xC7, 0x25, 0x4E)   # inline code color
PINK_BG    = RGBColor(0xFC, 0xE7, 0xEC)   # inline code background
ACCENT_BG  = RGBColor(0xEF, 0xF6, 0xFF)   # h2 section light bg

BODY_FONT  = 'Calibri'
CODE_FONT  = 'Courier New'
BODY_SIZE  = 11
CODE_SIZE  = 9


# ── XML helpers ────────────────────────────────────────────────────────────────

def _hex(rgb: RGBColor) -> str:
    return f"{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"


def set_cell_bg(cell, rgb: RGBColor):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:fill'), _hex(rgb))
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:val'), 'clear')
    tcPr.append(shd)


def set_para_shading(para, rgb: RGBColor):
    pPr = para._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:fill'), _hex(rgb))
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:val'), 'clear')
    pPr.append(shd)


def set_line_spacing(para, lines=1.15):
    pf = para.paragraph_format
    pf.line_spacing_rule = WD_LINE_SPACING.MULTIPLE
    pf.line_spacing = Pt(BODY_SIZE * lines)


def add_bottom_border(para, color_hex='1E3A5F', sz='12', space='4'):
    pPr = para._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    bdr = OxmlElement('w:bottom')
    bdr.set(qn('w:val'), 'single')
    bdr.set(qn('w:sz'), sz)
    bdr.set(qn('w:space'), space)
    bdr.set(qn('w:color'), color_hex)
    pBdr.append(bdr)
    pPr.append(pBdr)


def add_left_bar(para, color_hex='2563EB', sz='32', space='8'):
    pPr = para._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    bdr = OxmlElement('w:left')
    bdr.set(qn('w:val'), 'single')
    bdr.set(qn('w:sz'), sz)
    bdr.set(qn('w:space'), space)
    bdr.set(qn('w:color'), color_hex)
    pBdr.append(bdr)
    pPr.append(pBdr)


def remove_table_borders(tbl):
    tbl_elem = tbl._tbl
    tblPr = tbl_elem.find(qn('w:tblPr'))
    if tblPr is None:
        tblPr = OxmlElement('w:tblPr')
        tbl_elem.insert(0, tblPr)
    tblBorders = OxmlElement('w:tblBorders')
    for side in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        b = OxmlElement(f'w:{side}')
        b.set(qn('w:val'), 'none')
        tblBorders.append(b)
    tblPr.append(tblBorders)


# ── Inline markdown → styled runs ─────────────────────────────────────────────

def add_inline(para, text: str, size_pt=BODY_SIZE, color=BODY_CLR,
               bold=False, italic=False, font=BODY_FONT):
    """Parse **bold**, *italic*, `code` markers and add styled runs."""
    pattern = re.compile(r'(\*\*(.+?)\*\*|`([^`]+)`|\*(.+?)\*)')
    last = 0
    for m in pattern.finditer(text):
        if m.start() > last:
            chunk = text[last:m.start()]
            r = para.add_run(chunk)
            r.font.name = font
            r.font.size = Pt(size_pt)
            r.font.color.rgb = color
            r.bold = bold
            r.italic = italic

        full = m.group(0)
        if full.startswith('**'):
            r = para.add_run(m.group(2))
            r.font.name = font
            r.bold = True
            r.font.size = Pt(size_pt)
            r.font.color.rgb = color
        elif full.startswith('`'):
            r = para.add_run(m.group(3))
            r.font.name = CODE_FONT
            r.font.size = Pt(size_pt - 1)
            r.font.color.rgb = RED_CODE
            rPr = r._r.get_or_add_rPr()
            shd = OxmlElement('w:shd')
            shd.set(qn('w:val'), 'clear')
            shd.set(qn('w:color'), 'auto')
            shd.set(qn('w:fill'), _hex(PINK_BG))
            rPr.append(shd)
        elif full.startswith('*'):
            r = para.add_run(m.group(4))
            r.font.name = font
            r.italic = True
            r.font.size = Pt(size_pt)
            r.font.color.rgb = color
        last = m.end()

    if last < len(text):
        r = para.add_run(text[last:])
        r.font.name = font
        r.font.size = Pt(size_pt)
        r.font.color.rgb = color
        r.bold = bold
        r.italic = italic


# ── Block builders ─────────────────────────────────────────────────────────────

def add_h1(doc, text):
    """Chapter-level heading: e.g. '5.1 Introduction'.
    Styled as large bold navy with bottom border — like Chapter headings in refs."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(24)
    p.paragraph_format.space_after  = Pt(8)
    p.paragraph_format.left_indent  = Cm(0)
    set_para_shading(p, ACCENT_BG)
    add_bottom_border(p, color_hex=_hex(NAVY), sz='18', space='4')
    r = p.add_run(text.strip())
    r.bold = True
    r.font.name = BODY_FONT
    r.font.size = Pt(18)
    r.font.color.rgb = NAVY


def add_h2(doc, text):
    """Section heading (x.x): bold, 14pt navy with left accent bar."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(16)
    p.paragraph_format.space_after  = Pt(5)
    p.paragraph_format.left_indent  = Cm(0.2)
    add_left_bar(p, color_hex=_hex(BLUE), sz='32', space='8')
    r = p.add_run(text.strip())
    r.bold = True
    r.font.name = BODY_FONT
    r.font.size = Pt(14)
    r.font.color.rgb = NAVY


def add_h3(doc, text):
    """Sub-section heading (x.x.x): bold, 12pt navy."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after  = Pt(4)
    p.paragraph_format.left_indent  = Cm(0.3)
    r = p.add_run(text.strip())
    r.bold = True
    r.font.name = BODY_FONT
    r.font.size = Pt(12)
    r.font.color.rgb = NAVY


def add_h4(doc, text):
    """Fourth-level heading: bold, 11pt blue."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after  = Pt(3)
    p.paragraph_format.left_indent  = Cm(0.4)
    r = p.add_run(text.strip())
    r.bold = True
    r.font.name = BODY_FONT
    r.font.size = Pt(11)
    r.font.color.rgb = BLUE


def add_body(doc, text):
    """Justified body paragraph, 11pt Calibri, 1.15 line spacing."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_after  = Pt(6)
    p.paragraph_format.space_before = Pt(0)
    set_line_spacing(p, 1.15)
    add_inline(p, text.strip())


def add_bullet(doc, text, level=0):
    """Bullet point with • symbol. Supports level 0 (•) and level 1 (◦)."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    indent = Cm(0.7 + level * 0.5)
    p.paragraph_format.left_indent   = indent
    p.paragraph_format.first_line_indent = Cm(-0.4)
    p.paragraph_format.space_after   = Pt(3)
    p.paragraph_format.space_before  = Pt(1)
    set_line_spacing(p, 1.1)

    symbol = '•' if level == 0 else '◦'
    r0 = p.add_run(f'{symbol}  ')
    r0.font.name = BODY_FONT
    r0.font.size = Pt(BODY_SIZE)
    r0.font.color.rgb = BLUE if level == 0 else GREY
    add_inline(p, text.strip(), size_pt=BODY_SIZE, color=BODY_CLR)


def add_numbered(doc, num_str, text):
    """Numbered list item: '1.', '2.', etc."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.left_indent      = Cm(0.9)
    p.paragraph_format.first_line_indent = Cm(-0.5)
    p.paragraph_format.space_after      = Pt(3)
    p.paragraph_format.space_before     = Pt(1)
    set_line_spacing(p, 1.1)

    r0 = p.add_run(f'{num_str}  ')
    r0.font.name = BODY_FONT
    r0.font.size = Pt(BODY_SIZE)
    r0.bold = True
    r0.font.color.rgb = NAVY
    add_inline(p, text.strip(), size_pt=BODY_SIZE, color=BODY_CLR)


def add_code_block(doc, code_text):
    """Dark-background code block. Each line = one table row for solid fill."""
    code_lines = code_text.split('\n')
    if not code_lines:
        return

    tbl = doc.add_table(rows=len(code_lines), cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
    remove_table_borders(tbl)

    for ri, cl in enumerate(code_lines):
        cell = tbl.rows[ri].cells[0]
        set_cell_bg(cell, CODE_BG)
        cell.width = Inches(6.2)

        para = cell.paragraphs[0]
        para.paragraph_format.space_before = Pt(0)
        para.paragraph_format.space_after  = Pt(0)
        para.paragraph_format.left_indent  = Cm(0.25)

        r = para.add_run(cl if cl else ' ')
        r.font.name = CODE_FONT
        r.font.size = Pt(CODE_SIZE)
        r.font.color.rgb = CODE_FG

        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = OxmlElement('w:tcMar')
        for side in ('top', 'bottom', 'left', 'right'):
            m = OxmlElement(f'w:{side}')
            m.set(qn('w:w'), '60' if side in ('left', 'right') else '20')
            m.set(qn('w:type'), 'dxa')
            tcMar.append(m)
        tcPr.append(tcMar)

    sp = doc.add_paragraph()
    sp.paragraph_format.space_after = Pt(8)


def add_table_block(doc, rows):
    """Data table with navy header, alternating row shading, and borders."""
    if not rows:
        return
    col_count = max(len(r) for r in rows)
    norm = [r + [''] * (col_count - len(r)) for r in rows]

    tbl = doc.add_table(rows=len(norm), cols=col_count)
    tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
    tbl.style = 'Table Grid'

    col_w = Inches(6.2) / col_count

    for ri, row_data in enumerate(norm):
        row = tbl.rows[ri]
        for ci, cell_text in enumerate(row_data):
            cell = row.cells[ci]
            cell.width = col_w
            cell.text = ''

            clean = re.sub(r'\*\*(.+?)\*\*', r'\1', cell_text)
            clean = re.sub(r'`([^`]+)`', r'\1', clean)
            clean = re.sub(r'\*(.+?)\*', r'\1', clean)

            para = cell.paragraphs[0]
            para.paragraph_format.space_before = Pt(4)
            para.paragraph_format.space_after  = Pt(4)
            para.paragraph_format.left_indent  = Cm(0.1)

            r = para.add_run(clean.strip())
            r.font.name = BODY_FONT
            r.font.size = Pt(10)

            if ri == 0:
                set_cell_bg(cell, TABLE_HDR)
                r.bold = True
                r.font.color.rgb = WHITE
            elif ri % 2 == 0:
                set_cell_bg(cell, TABLE_ALT)
                r.font.color.rgb = BODY_CLR
            else:
                r.font.color.rgb = BODY_CLR

    sp = doc.add_paragraph()
    sp.paragraph_format.space_after = Pt(8)


def add_hr(doc):
    """Horizontal rule as a thin navy line."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after  = Pt(4)
    add_bottom_border(p, color_hex=_hex(NAVY), sz='6', space='1')


# ── Cover page ─────────────────────────────────────────────────────────────────

def add_cover(doc):
    # University / Institution line
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(60)
    p.paragraph_format.space_after  = Pt(4)
    r = p.add_run('Graduation Project — Batch 2024/2025')
    r.font.name = BODY_FONT
    r.font.size = Pt(12)
    r.font.color.rgb = GREY
    r.italic = True

    # Line separator
    sep = doc.add_paragraph()
    sep.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sep.paragraph_format.space_after = Pt(30)
    add_bottom_border(sep, color_hex=_hex(NAVY), sz='10', space='1')

    # Chapter label
    ch_label = doc.add_paragraph()
    ch_label.alignment = WD_ALIGN_PARAGRAPH.CENTER
    ch_label.paragraph_format.space_after = Pt(6)
    r_cl = ch_label.add_run('CHAPTER 5')
    r_cl.font.name = BODY_FONT
    r_cl.font.size = Pt(16)
    r_cl.bold = True
    r_cl.font.color.rgb = BLUE

    # Main title
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_after = Pt(10)
    r_t = title.add_run('Gen Z Studio Mobile Application')
    r_t.font.name = BODY_FONT
    r_t.font.size = Pt(28)
    r_t.bold = True
    r_t.font.color.rgb = NAVY

    # Subtitle
    sub = doc.add_paragraph()
    sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sub.paragraph_format.space_after = Pt(36)
    r_s = sub.add_run('Design, Architecture & Implementation')
    r_s.font.name = BODY_FONT
    r_s.font.size = Pt(14)
    r_s.font.color.rgb = GREY

    # Technology stack line
    tech = doc.add_paragraph()
    tech.alignment = WD_ALIGN_PARAGRAPH.CENTER
    tech.paragraph_format.space_after = Pt(6)
    r_tech = tech.add_run(
        'Flutter  ·  AWS Amplify  ·  Amazon Cognito  ·  AWS AppSync\n'
        'Amazon DynamoDB  ·  Amazon S3  ·  AWS EC2  ·  GraphQL'
    )
    r_tech.font.name = BODY_FONT
    r_tech.font.size = Pt(11)
    r_tech.font.color.rgb = GREY

    # Bottom separator
    sep2 = doc.add_paragraph()
    sep2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sep2.paragraph_format.space_before = Pt(30)
    sep2.paragraph_format.space_after = Pt(10)
    add_bottom_border(sep2, color_hex=_hex(NAVY), sz='10', space='1')

    # Module info
    mod = doc.add_paragraph()
    mod.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_mod = mod.add_run('Module 2 of 4  ·  Gen Z Studio Integrated Platform')
    r_mod.font.name = BODY_FONT
    r_mod.font.size = Pt(10)
    r_mod.font.color.rgb = GREY

    doc.add_page_break()


# ── Table of Contents ──────────────────────────────────────────────────────────

def add_toc(doc):
    # TOC title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p_title.paragraph_format.space_before = Pt(0)
    p_title.paragraph_format.space_after  = Pt(14)
    r = p_title.add_run('Table of Contents')
    r.bold = True
    r.font.name = BODY_FONT
    r.font.size = Pt(18)
    r.font.color.rgb = NAVY
    add_bottom_border(p_title, color_hex=_hex(NAVY), sz='12', space='4')

    entries = [
        ("5.1",    "Introduction", 0),
        ("5.2",    "Technology Stack & Development Framework", 0),
        ("5.2.1",  "Flutter — In-Depth Framework Analysis", 1),
        ("5.2.2",  "AWS Amplify — Cloud Backend Integration Layer", 1),
        ("5.2.3",  "Key Dependencies", 1),
        ("5.3",    "Application Architecture", 0),
        ("5.3.1",  "High-Level Architecture Overview", 1),
        ("5.3.2",  "Application Startup & Navigation Flow", 1),
        ("5.3.3",  "Code Organization & Module Structure", 1),
        ("5.3.4",  "State Management Strategy", 1),
        ("5.4",    "Authentication & User Management", 0),
        ("5.5",    "Client-Facing Features & User Interface", 0),
        ("5.5.1",  "Responsive Layout System", 1),
        ("5.5.2",  "Splash / Welcome Screen UI", 1),
        ("5.5.3",  "Home Screen — Welcome Banner", 1),
        ("5.5.4",  "Studio Grid — Responsive Display", 1),
        ("5.5.5",  "Services Catalog — Category-Grouped Design", 1),
        ("5.5.6",  "Booking Form — Detailed UI Walkthrough", 1),
        ("5.6",    "AI-Powered Chatbot — Design & Implementation", 0),
        ("5.6.1",  "Chatbot Screen UI", 1),
        ("5.6.2",  "Empty State — Welcome Screen", 1),
        ("5.6.3",  "Message Bubbles", 1),
        ("5.6.4",  "Loading Indicator", 1),
        ("5.6.5",  "Message Input Area", 1),
        ("5.6.6",  "Backend Communication & Session Management", 1),
        ("5.6.7",  "Booking Intent Detection & Execution", 1),
        ("5.7",    "Real-Time Support Chat & Ticket System", 0),
        ("5.8",    "Employee Administration Dashboard", 0),
        ("5.8.1",  "Dashboard Tab — Booking Management", 1),
        ("5.8.2",  "Notification System — Employee Side", 1),
        ("5.8.3",  "Wide-Screen Layout", 1),
        ("5.9",    "Notifications System", 0),
        ("5.10",   "Analytics & Reporting", 0),
        ("5.11",   "Internationalization & Responsive Design", 0),
        ("5.12",   "Database Schema & Data Models", 0),
        ("5.13",   "Real-Time Synchronization Strategy", 0),
        ("5.14",   "Visual Design System", 0),
        ("5.15",   "Summary & Conclusions", 0),
    ]

    for num, title, level in entries:
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(2 if level == 0 else 1)
        p.paragraph_format.space_before = Pt(5 if level == 0 else 0)
        if level > 0:
            p.paragraph_format.left_indent = Cm(1.5)

        r = p.add_run(f'{num}    {title}')
        r.font.name = BODY_FONT
        r.font.size = Pt(11 if level == 0 else 10)
        r.bold = (level == 0)
        r.font.color.rgb = NAVY if level == 0 else GREY

    doc.add_page_break()


# ── Markdown table parser ──────────────────────────────────────────────────────

def parse_md_table(lines):
    rows = []
    for line in lines:
        if re.match(r'\|?\s*:?-+:?\s*\|', line):
            continue
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        rows.append(cells)
    return rows


# ── Main parser ────────────────────────────────────────────────────────────────

def build_docx(md_text: str, doc: Document):
    add_cover(doc)
    add_toc(doc)

    lines = md_text.splitlines()
    n = len(lines)
    i = 0

    in_code   = False
    code_buf  = []
    in_table  = False
    table_buf = []
    para_buf  = []   # accumulate consecutive body text lines

    def flush_para():
        if para_buf:
            add_body(doc, ' '.join(para_buf))
            para_buf.clear()

    while i < n:
        line = lines[i]

        # ── code block fence ──────────────────────────────────────────────────
        if line.strip().startswith('```'):
            flush_para()
            if not in_code:
                in_code = True
                code_buf = []
            else:
                in_code = False
                add_code_block(doc, '\n'.join(code_buf))
                code_buf = []
            i += 1
            continue

        if in_code:
            code_buf.append(line)
            i += 1
            continue

        # ── markdown table ────────────────────────────────────────────────────
        if '|' in line and not in_table:
            flush_para()
            in_table = True
            table_buf = [line]
            i += 1
            continue

        if in_table:
            if '|' in line:
                table_buf.append(line)
                i += 1
                continue
            else:
                rows = parse_md_table(table_buf)
                add_table_block(doc, rows)
                in_table  = False
                table_buf = []
                continue   # reprocess current line

        # ── headings ──────────────────────────────────────────────────────────
        if re.match(r'^# [^#]', line):
            flush_para()
            add_h1(doc, line[2:])
            i += 1; continue

        if re.match(r'^## [^#]', line):
            flush_para()
            add_h2(doc, line[3:])
            i += 1; continue

        if re.match(r'^### [^#]', line):
            flush_para()
            add_h3(doc, line[4:])
            i += 1; continue

        if line.startswith('#### '):
            flush_para()
            add_h4(doc, line[5:])
            i += 1; continue

        # ── horizontal rule ───────────────────────────────────────────────────
        if re.match(r'^[-*_]{3,}\s*$', line.strip()):
            flush_para()
            add_hr(doc)
            i += 1; continue

        # ── bullet (level 0: '- ' or '* ') ───────────────────────────────────
        m_bul = re.match(r'^[-*]\s+(.*)', line)
        if m_bul:
            flush_para()
            add_bullet(doc, m_bul.group(1), level=0)
            i += 1; continue

        # ── sub-bullet (indented '  - ' or '    - ') ─────────────────────────
        m_sub = re.match(r'^ {2,}[-*]\s+(.*)', line)
        if m_sub:
            flush_para()
            add_bullet(doc, m_sub.group(1), level=1)
            i += 1; continue

        # ── numbered list ─────────────────────────────────────────────────────
        m_num = re.match(r'^(\d+\.)\s+(.*)', line)
        if m_num:
            flush_para()
            add_numbered(doc, m_num.group(1), m_num.group(2))
            i += 1; continue

        # ── blank line → flush paragraph buffer ──────────────────────────────
        if line.strip() == '':
            flush_para()
            i += 1; continue

        # ── normal body text → accumulate ────────────────────────────────────
        stripped = line.strip()
        if stripped:
            para_buf.append(stripped)
        i += 1

    # Flush anything remaining at end of file
    flush_para()
    if in_table and table_buf:
        add_table_block(doc, parse_md_table(table_buf))
    if in_code and code_buf:
        add_code_block(doc, '\n'.join(code_buf))


# ── Document setup ─────────────────────────────────────────────────────────────

def setup_document() -> Document:
    doc = Document()

    # Page margins — match Chapters 1-4 style
    for section in doc.sections:
        section.top_margin    = Cm(2.5)
        section.bottom_margin = Cm(2.5)
        section.left_margin   = Cm(3.0)   # slightly wider left for binding
        section.right_margin  = Cm(2.5)

    # Default (Normal) style
    normal = doc.styles['Normal']
    normal.font.name = BODY_FONT
    normal.font.size = Pt(BODY_SIZE)

    return doc


def main():
    print('Reading markdown...')
    with open(MD_PATH, encoding='utf-8') as f:
        md_text = f.read()

    print('Building document...')
    doc = setup_document()
    build_docx(md_text, doc)

    doc.save(DOCX_PATH)
    size_kb = os.path.getsize(DOCX_PATH) // 1024
    print(f'Done! -> {DOCX_PATH}')
    print(f'Size  : {size_kb} KB')


if __name__ == '__main__':
    main()
