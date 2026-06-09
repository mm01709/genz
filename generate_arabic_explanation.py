"""
يولّد ملف Word شرح كامل بالعربي لتطبيق Gen Z Studio
"""

from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import os

DOCX_PATH = r"d:\myapp\GenZ\GenZ_Arabic_Explanation.docx"

NAVY  = RGBColor(0x1E, 0x3A, 0x5F)
BLUE  = RGBColor(0x25, 0x63, 0xEB)
GREEN = RGBColor(0x16, 0xA3, 0x4A)
RED   = RGBColor(0xDC, 0x26, 0x26)
GREY  = RGBColor(0x4B, 0x55, 0x63)
BODY  = RGBColor(0x1F, 0x2D, 0x3D)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
TABLE_HDR = RGBColor(0x1E, 0x3A, 0x5F)
TABLE_ALT = RGBColor(0xEF, 0xF6, 0xFF)
CODE_BG   = RGBColor(0x1E, 0x29, 0x3B)
CODE_FG   = RGBColor(0xE2, 0xE8, 0xF0)

def _hex(rgb):
    return f"{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"

def set_cell_bg(cell, rgb):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:fill'), _hex(rgb))
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:val'), 'clear')
    tcPr.append(shd)

def set_rtl(para):
    pPr = para._p.get_or_add_pPr()
    bidi = OxmlElement('w:bidi')
    pPr.append(bidi)

def set_para_bg(para, rgb):
    pPr = para._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:fill'), _hex(rgb))
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:val'), 'clear')
    pPr.append(shd)

def add_border_bottom(para, color_hex, sz='12'):
    pPr = para._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    b = OxmlElement('w:bottom')
    b.set(qn('w:val'), 'single')
    b.set(qn('w:sz'), sz)
    b.set(qn('w:space'), '4')
    b.set(qn('w:color'), color_hex)
    pBdr.append(b)
    pPr.append(pBdr)

def add_left_bar(para, color_hex, sz='28'):
    pPr = para._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    b = OxmlElement('w:right')   # right = RTL left
    b.set(qn('w:val'), 'single')
    b.set(qn('w:sz'), sz)
    b.set(qn('w:space'), '8')
    b.set(qn('w:color'), color_hex)
    pBdr.append(b)
    pPr.append(pBdr)

def run(para, text, size=12, color=BODY, bold=False, italic=False, font='Calibri'):
    r = para.add_run(text)
    r.font.name = font
    r.font.size = Pt(size)
    r.font.color.rgb = color
    r.bold = bold
    r.italic = italic
    # RTL run
    rPr = r._r.get_or_add_rPr()
    rtl = OxmlElement('w:rtl')
    rPr.append(rtl)
    return r

# ── بانيات الفقرات ─────────────────────────────────────────────────────────────

def chapter_title(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after  = Pt(16)
    set_rtl(p)
    set_para_bg(p, RGBColor(0xE8, 0xF2, 0xFF))
    add_border_bottom(p, _hex(NAVY), sz='20')
    run(p, text, size=22, color=NAVY, bold=True)

def section(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(18)
    p.paragraph_format.space_after  = Pt(6)
    set_rtl(p)
    add_left_bar(p, _hex(BLUE), sz='32')
    run(p, text, size=15, color=NAVY, bold=True)

def subsection(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after  = Pt(4)
    set_rtl(p)
    run(p, text, size=13, color=NAVY, bold=True)

def subsubsection(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after  = Pt(3)
    set_rtl(p)
    run(p, text, size=12, color=BLUE, bold=True)

def body(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after  = Pt(7)
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.MULTIPLE
    p.paragraph_format.line_spacing = Pt(12 * 1.4)
    set_rtl(p)
    run(p, text, size=12, color=BODY)

def note(doc, text):
    """فقرة ملاحظة بخلفية صفراء فاتحة"""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after  = Pt(6)
    p.paragraph_format.left_indent  = Cm(0.5)
    p.paragraph_format.right_indent = Cm(0.5)
    set_rtl(p)
    set_para_bg(p, RGBColor(0xFF, 0xFB, 0xEB))
    run(p, '💡 ملاحظة: ', size=11, color=RGBColor(0x92, 0x40, 0x00), bold=True)
    run(p, text, size=11, color=RGBColor(0x78, 0x35, 0x00))

def bullet(doc, bold_part, rest='', color=BLUE):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after   = Pt(4)
    p.paragraph_format.right_indent  = Cm(0.8)
    p.paragraph_format.first_line_indent = Cm(-0.4)
    set_rtl(p)
    run(p, '• ', size=12, color=color, bold=True)
    if bold_part:
        run(p, bold_part, size=12, color=NAVY, bold=True)
    if rest:
        run(p, rest, size=12, color=BODY)

def numbered(doc, num, bold_part, rest=''):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after   = Pt(4)
    p.paragraph_format.right_indent  = Cm(0.8)
    p.paragraph_format.first_line_indent = Cm(-0.5)
    set_rtl(p)
    run(p, f'{num}. ', size=12, color=NAVY, bold=True)
    if bold_part:
        run(p, bold_part, size=12, color=NAVY, bold=True)
    if rest:
        run(p, rest, size=12, color=BODY)

def code_line(doc, text):
    """سطر كود بخلفية داكنة"""
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.shared import Inches
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.RIGHT
    cell = tbl.rows[0].cells[0]
    set_cell_bg(cell, CODE_BG)
    para = cell.paragraphs[0]
    para.paragraph_format.space_before = Pt(2)
    para.paragraph_format.space_after  = Pt(2)
    r = para.add_run(text)
    r.font.name = 'Courier New'
    r.font.size = Pt(10)
    r.font.color.rgb = CODE_FG
    # remove borders
    tbl_elem = tbl._tbl
    from docx.oxml.ns import qn as _qn
    tblPr = tbl_elem.find(_qn('w:tblPr'))
    if tblPr is None:
        tblPr = OxmlElement('w:tblPr')
        tbl_elem.insert(0, tblPr)
    tblBorders = OxmlElement('w:tblBorders')
    for side in ('top','left','bottom','right','insideH','insideV'):
        b = OxmlElement(f'w:{side}')
        b.set(_qn('w:val'), 'none')
        tblBorders.append(b)
    tblPr.append(tblBorders)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def table(doc, rows_data):
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.shared import Inches
    if not rows_data: return
    cols = max(len(r) for r in rows_data)
    norm = [r + ['']*(cols-len(r)) for r in rows_data]
    tbl = doc.add_table(rows=len(norm), cols=cols)
    tbl.style = 'Table Grid'
    tbl.alignment = WD_TABLE_ALIGNMENT.RIGHT
    col_w = Inches(6.0) / cols
    for ri, row_data in enumerate(norm):
        for ci, txt in enumerate(row_data):
            cell = tbl.rows[ri].cells[ci]
            cell.width = col_w
            cell.text = ''
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
            set_rtl(p)
            r = p.add_run(txt)
            r.font.name = 'Calibri'
            r.font.size = Pt(11)
            if ri == 0:
                set_cell_bg(cell, TABLE_HDR)
                r.bold = True
                r.font.color.rgb = WHITE
            elif ri % 2 == 0:
                set_cell_bg(cell, TABLE_ALT)
                r.font.color.rgb = BODY
            else:
                r.font.color.rgb = BODY
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def page_break(doc):
    doc.add_page_break()

# ── الغلاف ─────────────────────────────────────────────────────────────────────

def add_cover(doc):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(60)
    set_rtl(p)
    run(p, 'مشروع التخرج — Gen Z Studio', size=13, color=GREY, italic=True)

    sep = doc.add_paragraph()
    sep.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sep.paragraph_format.space_after = Pt(30)
    add_border_bottom(sep, _hex(NAVY), sz='12')

    t = doc.add_paragraph()
    t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    t.paragraph_format.space_after = Pt(8)
    set_rtl(t)
    run(t, 'شرح تطبيق الجوال بالعربي', size=26, color=NAVY, bold=True)

    s = doc.add_paragraph()
    s.alignment = WD_ALIGN_PARAGRAPH.CENTER
    s.paragraph_format.space_after = Pt(30)
    set_rtl(s)
    run(s, 'كل حاجة في التطبيق مشروحة بالتفصيل', size=14, color=GREY)

    info = doc.add_paragraph()
    info.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_rtl(info)
    run(info, 'Flutter  ·  AWS  ·  Amazon Cognito  ·  AppSync  ·  DynamoDB', size=11, color=GREY)

    sep2 = doc.add_paragraph()
    sep2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sep2.paragraph_format.space_before = Pt(30)
    add_border_bottom(sep2, _hex(NAVY), sz='10')

    doc.add_page_break()

# ── المحتوى الكامل ─────────────────────────────────────────────────────────────

def build(doc):
    add_cover(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١. فلتر (Flutter) — إيه ده وليه اخترناه؟')

    section(doc, '١.١ إيه هو Flutter؟')
    body(doc, 'Flutter هو framework مفتوح المصدر من Google، بيخليك تكتب تطبيق واحد بس وتشغّله على Android وiOS والويب وحتى الكمبيوتر، كل ده من كود واحد! بدل ما تكتب تطبيق Android منفصل وتطبيق iPhone منفصل، بتكتب Flutter وبيطلع من الاتنين.')
    body(doc, 'التطبيق بيتكتب بلغة اسمها Dart — لغة من Google كمان، حديثة وسريعة وفيها type safety يعني لو عملت غلطة في الكود بيقولك عليها قبل ما تشغّل التطبيق.')

    subsection(doc, '١.٢ ليه Flutter مش بيستخدم مكونات Android أو iPhone الأصلية؟')
    body(doc, 'ده السر الكبير في Flutter. معظم الـ frameworks التانية بتقول لـ Android "ارسم زرار" وبتقول لـ iPhone "ارسم زرار" — فبيطلعوا مختلفين على كل جهاز.')
    body(doc, 'Flutter بيرسم هو نفسه كل حاجة على الشاشة مباشرة عن طريق الـ GPU، زي ما لعبة فيديو بترسم نفسها. يعني الزرار هيبقى بالظبط نفسه على Android وiPhone — مفيش فرق.')

    note(doc, 'Flutter بيستخدم محرك رسم اسمه Skia (أو Impeller في النسخ الجديدة) — نفس المحرك اللي Chrome بيستخدمه.')

    subsection(doc, '١.٣ إيه هو الـ Widget؟')
    body(doc, 'في Flutter كل حاجة بتشوفها على الشاشة اسمها Widget. الزرار widget، النص widget، الصورة widget، حتى الـ padding (المسافة) widget! التطبيق كله عبارة عن شجرة من الـ widgets جوا بعض.')
    body(doc, 'فيه نوعين أساسيين:')
    bullet(doc, 'StatelessWidget:', ' بيتبنى مرة واحدة ومش بيتغير. مثال: عنوان الشاشة أو سعر الخدمة — دي حاجات ثابتة.')
    bullet(doc, 'StatefulWidget:', ' بيتغير مع الوقت. مثال: شاشة الحجز اللي بتحسب السعر وأنت بتغير الساعات — كل ما تغير حاجة بيحسبها تاني.')
    body(doc, 'لما بتستدعي setState() بتقول لـ Flutter "في حاجة اتغيرت، أعد رسم الشاشة" — Flutter بيعمل ده بذكاء، بيرسم بس الجزء اللي اتغير مش الشاشة كلها.')

    subsection(doc, '١.٤ ليه اخترنا Flutter لـ Gen Z Studio؟')
    numbered(doc, '١', 'AWS Amplify عنده Flutter SDK رسمي: ', 'Amazon عامل SDK خاص لـ Flutter بيربطه بكل خدمات AWS. ده أهم سبب — مش كل framework عنده ده.')
    numbered(doc, '٢', 'تطبيق واحد لـ Android وiOS والويب: ', 'بدل ما نعمل ٣ تطبيقات منفصلة، عملنا واحد بس.')
    numbered(doc, '٣', 'Hot Reload: ', 'لما بتغير حاجة في الكود بيظهر التغيير في أقل من ثانية من غير ما التطبيق يقفل — ده بيسرّع الشغل جداً.')
    numbered(doc, '٤', 'AOT Compilation: ', 'الكود بيتحول لـ machine code حقيقي قبل ما التطبيق يشتغل — يعني التطبيق سريع جداً زي التطبيقات الأصلية.')
    numbered(doc, '٥', 'Dart Streams: ', 'Dart عنده نظام للبيانات اللي بتيجي في real-time مناسب جداً للـ subscriptions والـ WebSockets اللي بنستخدمها.')
    numbered(doc, '٦', 'Material Design: ', 'Flutter جاي بكل مكونات Google Material Design جاهزة — كاردز، حوارات، أيقونات، إلخ.')

    table(doc, [
        ['المعيار', 'Flutter', 'React Native', 'تطبيقات منفصلة'],
        ['كود واحد لكل المنصات', 'نعم ✓', 'نعم ✓', 'لأ ✗'],
        ['الأداء', 'ممتاز (بدون JS bridge)', 'جيد (فيه overhead)', 'ممتاز'],
        ['AWS Amplify رسمي', 'نعم ✓', 'نعم ✓', 'لكل منصة منفرد'],
        ['ثبات الشكل على كل الأجهزة', 'مثالي (رسم ذاتي)', 'فيه فروق طفيفة', 'مختلف على كل منصة'],
        ['Hot Reload', 'نعم ✓', 'نعم ✓', 'لأ ✗'],
    ])

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٢. AWS و Amplify — الـ Backend بتاعنا')

    section(doc, '٢.١ إيه هو AWS Amplify؟')
    body(doc, 'AWS Amplify هو framework بيوصّل تطبيق Flutter بخدمات Amazon السحابية. بدل ما تبني server من الصفر، Amplify بيديك Authentication (تسجيل دخول)، Database، File Storage وكل حاجة جاهزة.')
    body(doc, 'في تطبيقنا بنستخدم ٤ خدمات من AWS:')
    bullet(doc, 'Amazon Cognito:', ' لإدارة المستخدمين وتسجيل الدخول')
    bullet(doc, 'AWS AppSync:', ' الـ API اللي التطبيق بيتكلم معاه')
    bullet(doc, 'Amazon DynamoDB:', ' قاعدة البيانات')
    bullet(doc, 'Amazon S3:', ' لتخزين الصور')

    subsection(doc, '٢.٢ ليه أوقفنا الـ DataStore؟')
    body(doc, 'Amplify DataStore هو نظام بيحمّل كل البيانات على الجهاز ويزامنها مع السحابة. المشكلة: نظام الأمان عندنا (owner-based auth) بيمنع كل مستخدم يشوف بيانات الآخرين.')
    body(doc, 'لما DataStore يحاول يجيب كل الحجوزات (مثلاً) — AppSync بيرفض الطلب لأن العميل مسموله يشوف حجوزاته هو بس. فـ DataStore كان بيرمي errors مستمرة.')
    body(doc, 'الحل: أوقفنا DataStore واشتغلنا بـ Amplify.API.query() مباشرة — كل شاشة بتجيب البيانات اللي محتاجاها هي بس.')

    note(doc, 'في main.dart فيه كومنت بيشرح ده: "⚠️ DataStore disabled — owner-auth schema rejects sync. Using Amplify.API directly + polling timers."')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٣. Amazon Cognito — تسجيل الدخول والأمان')

    section(doc, '٣.١ إيه هو Cognito؟')
    body(doc, 'Cognito هو خدمة AWS المسؤولة عن كل حاجة تتعلق بالمستخدمين: إنشاء الحساب، تأكيد الإيميل، تسجيل الدخول، وإدارة الصلاحيات. مش محتاجين نبني login server من الصفر — Cognito بيعمل كل ده.')

    section(doc, '٣.٢ إيه هي الـ JWT Tokens؟')
    body(doc, 'لما المستخدم يسجل دخول، Cognito بيديه ٣ tokens (زي بطاقات هوية رقمية):')
    bullet(doc, 'ID Token:', ' بيحتوي على معلومات المستخدم — الاسم، الإيميل، انتمى لأي group (عميل أم موظف). بيبقى صالح ساعة واحدة.')
    bullet(doc, 'Access Token:', ' بيُستخدم للتحقق من الصلاحية عند الوصول لـ AWS. بيبقى صالح ساعة.')
    bullet(doc, 'Refresh Token:', ' يعيش ٣٠ يوم. لما الـ ID Token ينتهي، Amplify بيستخدمه تلقائياً يجيب token جديد من غير ما المستخدم يحس بحاجة.')
    body(doc, 'الـ Tokens بتتخزن في مكان آمن على الجهاز — Android Keystore على أندرويد، و iOS Keychain على آيفون. مش بتتكتب في مكان عادي يقدر حد يقرأه.')

    section(doc, '٣.٣ خطوات إنشاء الحساب')
    body(doc, 'لما مستخدم جديد يسجّل:')
    numbered(doc, '١', 'بيملا:', ' الاسم الأول، الاسم الأخير، الإيميل، الباسورد، تأكيد الباسورد')
    numbered(doc, '٢', 'Amplify.Auth.signUp():', ' بترسل البيانات لـ Cognito')
    numbered(doc, '٣', 'Cognito بيبعت OTP:', ' كود من ٦ أرقام على إيميله')
    numbered(doc, '٤', 'المستخدم بيدخل الكود:', ' Amplify.Auth.confirmSignUp()')
    numbered(doc, '٥', 'الحساب بيتأكد:', ' Cognito بيعلّمه confirmed')
    numbered(doc, '٦', 'التطبيق بيسجل دخوله تلقائياً:', ' ويوصّله للشاشة الرئيسية')

    section(doc, '٣.٤ الـ Groups — عميل أم موظف؟')
    body(doc, 'في Cognito عندنا Group واحد هو "Employees". أي مستخدم مش في الـ Employees group تلقائياً يتعامل معاه كعميل. التطبيق بيشوف الـ group من الـ JWT token ويوجّه المستخدم للشاشة الصح.')
    table(doc, [
        ['الـ Group', 'الصلاحيات'],
        ['Clients (عملاء)', 'يشوف الاستوديوهات — يحجز — يشوف حجوزاته — يتكلم مع الدعم — يشوف إشعاراته'],
        ['Employees (موظفون)', 'كل حاجة + يدير الحجوزات + يضيف/يعدل/يمسح الاستوديوهات والخدمات + يشوف التقارير'],
    ])

    section(doc, '٣.٥ الأمان على مستوى الـ API')
    body(doc, 'حتى لو حد حاول يخترق التطبيق ويبعت request مباشرة لـ AppSync، AppSync بيرفضه. الأمان مش بس في التطبيق، هو موجود على السيرفر. مثلاً:')
    bullet(doc, 'عميل يحاول يشوف حجوزات عميل تاني:', ' AppSync بيرجّعله نتيجة فاضية')
    bullet(doc, 'عميل يحاول يعدل استوديو:', ' AppSync بيرجعه خطأ 401 Unauthorized')
    bullet(doc, 'عميل يحاول يشوف إشعارات حد تاني:', ' مبيظهرش له حاجة')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٤. شاشات العميل — كل شاشة بالتفصيل')

    section(doc, '٤.١ شاشة الترحيب (قبل تسجيل الدخول)')
    body(doc, 'أول ما التطبيق يفتح ومفيش حساب مسجّل، بتظهر WelcomeScreen. فيها:')
    bullet(doc, 'هيدر بـ gradient:', ' من اللون الأزرق الغامق للنيفي — فيه لوجو "GENZ Studios" وـ tagline')
    bullet(doc, 'TabBar بتابين:', ' "تسجيل الدخول" و"إنشاء حساب"')
    bullet(doc, 'تاب تسجيل الدخول:', ' فيلد الإيميل، فيلد الباسورد (مع زرار إظهار/إخفاء)، لينك "نسيت الباسورد"')
    bullet(doc, 'تاب إنشاء الحساب:', ' الاسم الأول، الاسم الأخير، الإيميل، الباسورد، تأكيد الباسورد')
    bullet(doc, 'رسائل الخطأ:', ' بتظهر كبانر ملوّن فوق زرار التسجيل')

    section(doc, '٤.٢ شاشة Splash (التحميل الأولي)')
    body(doc, 'لما التطبيق يفتح وفيه حساب مسجّل، بتظهر SplashScreen لمدة أقل من ثانية. فيها:')
    bullet(doc, 'خلفية نيفي داكنة كاملة الشاشة')
    bullet(doc, 'أيقونة كاميرا 80px بيضاء في الوسط')
    bullet(doc, 'نص "GENZ Studios" بولد أبيض 28pt')
    bullet(doc, 'CircularProgressIndicator أبيض تحتيه')
    body(doc, 'في نفس الوقت التطبيق بيعمل:')
    numbered(doc, '١', 'Amplify.Auth.fetchAuthSession():', ' بيشوف فيه session ولا لأ')
    numbered(doc, '٢', 'يجيب بيانات المستخدم:', ' الاسم، الإيميل، النوع (عميل/موظف)، الصورة')
    numbered(doc, '٣', 'يوجّهه:', ' موظف ← شاشة الموظفين | عميل جديد ← Onboarding | عميل قديم ← الشاشة الرئيسية')

    section(doc, '٤.٣ الشاشة الرئيسية — Layout المتجاوب')
    body(doc, 'الشاشة الرئيسية للعميل (client_screen.dart) بتتغير شكلها حسب حجم الشاشة:')
    table(doc, [
        ['حجم الشاشة', 'الـ Layout', 'التنقل'],
        ['أقل من 600px (موبايل)', 'عمود واحد كامل', 'أيقونة Hamburger تفتح Drawer من الجانب'],
        ['600 - 900px (تابلت)', 'Sidebar ثابت + محتوى', 'Sidebar دايم ظاهر (أيقونات بس)'],
        ['أكبر من 900px (ديسكتوب/ويب)', 'Sidebar واسع + محتوى', 'Sidebar بأيقونات ونصوص'],
    ])
    body(doc, 'الكود بيشوف عرض الشاشة عند كل build() — لو المستخدم غيّر حجم نافذة المتصفح، التصميم بيتغير على الفور بدون أي restart.')

    section(doc, '٤.٤ البانر الترحيبي (Welcome Banner)')
    body(doc, 'أول حاجة بتشوفها في الشاشة الرئيسية. هو Container بـ gradient من اللون الأزرق للنيفي، مع:')
    bullet(doc, '"Welcome back":', ' نص أبيض شفاف 13pt')
    bullet(doc, 'اسم العميل:', ' بولد أبيض 20pt، جاي من بيانات الحساب')
    bullet(doc, 'زرار "Instant Book":', ' زرار بيجيب العميل على طول لفورم الحجز')
    bullet(doc, 'أيقونة كاميرا:', ' زخرفة في يمين البانر 60px')

    section(doc, '٤.٥ شبكة الاستوديوهات (Studio Grid)')
    body(doc, 'تحت البانر بتظهر الاستوديوهات في شبكة بتتغير حسب حجم الشاشة:')
    bullet(doc, 'موبايل:', ' عمود واحد (كل استوديو يملا العرض)')
    bullet(doc, 'تابلت:', ' عمودين')
    bullet(doc, 'ديسكتوب:', ' ٣ أعمدة')
    body(doc, 'كل كارد استوديو بيحتوي على:')
    bullet(doc, 'صورة الاستوديو:', ' متحملة من Amazon S3')
    bullet(doc, 'الاسم والموقع والسعر')
    bullet(doc, 'مؤشر التوفر:', ' نقطة خضرا = متاح، رمادي = مش متاح')
    bullet(doc, 'زرار "Book Now":', ' بيختار الاستوديو ده ويروح لفورم الحجز')
    note(doc, 'الاستوديوهات بتتحدث كل ٩٠ ثانية تلقائياً. لو موظف مسح استوديو، بيختفي من شاشة العميل خلال ٩٠ ثانية.')

    section(doc, '٤.٦ كتالوج الخدمات (Services Catalog)')
    body(doc, 'تحت الاستوديوهات بيظهر كتالوج الخدمات. الخدمات متجمعة في ٥ فئات كل واحدة بلونها:')
    table(doc, [
        ['الفئة', 'الإيموجي', 'اللون'],
        ['Photography Packages (تصوير)', '📷', 'بنفسجي #6C63FF'],
        ['Video Production (فيديو)', '🎬', 'أزرق #3B82F6'],
        ['Advertising & Marketing (إعلانات)', '📢', 'كهرماني #F59E0B'],
        ['Creative Design (تصميم)', '🎨', 'أحمر #EF4444'],
        ['Social Media Management (سوشيال)', '📱', 'أخضر #22C55E'],
    ])
    body(doc, 'كل فئة بيظهر عليها كارد فيه هيدر ملوّن مع الإيموجي واسم الفئة وعدد الباقات. الضغط على "Request" بيفتح Bottom Sheet (شيت من تحت) فيه تفاصيل الطلب.')
    note(doc, 'استخدمنا showModalBottomSheet(isScrollControlled: true) عشان الـ sheet يقدر يكبر ويوعي الكيبورد من غير ما يغطي الفورم.')

    section(doc, '٤.٧ فورم الحجز — أهم شاشة في التطبيق')
    body(doc, 'فورم الحجز هو أكتر شاشة فيها منطق. بيجمع كل بيانات الحجز:')

    subsubsection(doc, 'الفيلدز')
    bullet(doc, 'الاسم الأول والاسم الأخير:', ' جنب بعض في Row على الشاشات الكبيرة')
    bullet(doc, 'رقم التليفون')
    bullet(doc, 'اختيار الاستوديو:', ' Dropdown فيه الاستوديوهات المتاحة')
    bullet(doc, 'تاريخ البداية والنهاية:', ' بفتح Date Picker')
    bullet(doc, 'ساعة البداية والنهاية:', ' Slider من ٩ صباحاً لـ ٧ مساءً')
    bullet(doc, 'الأجهزة المطلوبة:', ' textarea')
    bullet(doc, 'الشروط والأحكام:', ' Checkbox لازم يتشاك')

    subsubsection(doc, 'Date Picker مع قواعد تجارية')
    body(doc, 'التقويم بيظهر بـ selectableDayPredicate لمنع اختيار يوم الجمعة (إجازة الاستوديو). الأيام دي بتتعمّر ومش ممكن تضغط عليها. كمان:')
    bullet(doc, 'مش ممكن تختار يوم في الماضي', '')
    bullet(doc, 'المستقبل محدود بسنة واحدة بس', '')

    subsubsection(doc, 'حساب السعر في الـ Real-time')
    body(doc, 'كل ما تغير الاستوديو أو التواريخ أو الساعات، السعر بيتحسب فوراً من غير ما يروح للسيرفر:')
    code_line(doc, 'final hours = endHour - startHour;')
    code_line(doc, 'final days = toDate.difference(fromDate).inDays + 1;')
    code_line(doc, 'final total = studio["pricePerHour"] * hours * days;')
    body(doc, 'الحساب بيظهر في بوكس ملوّن في أسفل الفورم — عدد الساعات × عدد الأيام × السعر بالساعة.')

    subsubsection(doc, 'الـ Atomic Booking — منع الحجز المضاعف')
    body(doc, 'لما العميل يضغط "احجز"، بيحصل الآتي بالترتيب:')
    numbered(doc, '١', 'Validation:', ' كل الفيلدز ممليّة؟ التواريخ صح؟ endHour > startHour؟ الشروط متشاكة؟')
    numbered(doc, '٢', 'زرار الإرسال يتعطّل:', ' بيتحول لـ spinner عشان يمنع ضغطتين')
    numbered(doc, '٣', 'saveBookingAtomic():', ' بيبعت الحجز لـ DynamoDB مع conditional write')
    numbered(doc, '٤', 'DynamoDB بيتحقق:', ' في حجوزات متعارضة للاستوديو ده في نفس الوقت؟')
    numbered(doc, '٥', 'لو نجح:', ' بيبعت إشعار للموظف وإشعار للعميل')
    numbered(doc, '٦', 'لو فشل:', ' بيظهر رسالة خطأ واضحة حسب السبب')
    body(doc, 'رسائل الخطأ:')
    bullet(doc, 'studio_booked:', ' "الاستوديو محجوز في هذا الوقت"')
    bullet(doc, 'client_time_conflict:', ' "عندك حجز آخر في نفس الوقت"')
    bullet(doc, 'invalid_dates:', ' "اختر تواريخ صحيحة"')
    bullet(doc, 'auth_error:', ' "انتهت الجلسة، سجل دخولك مجدداً"')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٥. الشات بوت بالذكاء الاصطناعي')

    section(doc, '٥.١ إيه هو الشات بوت؟')
    body(doc, 'الشات بوت هو مساعد ذكي داخل التطبيق بيساعد العملاء يعرفوا معلومات عن الاستوديو، يستفسروا عن الأسعار، ويقدروا يحجزوا من خلال المحادثة. بيستخدم NLP (معالجة اللغة الطبيعية) ويدعم العربي والإنجليزي.')

    section(doc, '٥.٢ معمارية الشات بوت')
    body(doc, 'الشات بوت مش شغّال جوا التطبيق مباشرة. التطبيق بيبعت الرسالة لـ server خارجي:')
    bullet(doc, 'السيرفر:', ' Python Flask على AWS EC2')
    bullet(doc, 'الـ IP:', ' http://3.239.202.67:5000')
    bullet(doc, 'الـ Endpoint:', ' POST /chat')
    body(doc, 'كل رسالة بتتبعت مع:')
    code_line(doc, '{ "message": "نص الرسالة", "session_id": "معرف الجلسة" }')
    body(doc, 'الـ session_id بيخلي السيرفر يفتكر سياق المحادثة كلها — مش بس الرسالة الأخيرة.')

    section(doc, '٥.٣ حفظ الجلسة')
    body(doc, 'الـ session_id بيتحفظ في SharedPreferences على الجهاز تحت مفتاح "chatbot_session_id". يعني حتى لو قفلت التطبيق وفتحته تاني، المحادثة بتكمل من نفس الجلسة ومش بتبدأ من الأول.')
    note(doc, 'SharedPreferences هو تخزين بسيط على الجهاز زي الـ settings — مناسب للبيانات الخفيفة زي session ID أو إعدادات اللغة.')

    section(doc, '٥.٤ تصميم شاشة الشات')
    body(doc, 'الشاشة اتصممت تشبه تطبيقات الشات المعروفة:')

    subsubsection(doc, 'الشاشة الفاضية (Empty State)')
    body(doc, 'لما مفيش رسائل بعد، بتظهر:')
    bullet(doc, 'دايرة gradient كبيرة ٨٠×٨٠ فيها أيقونة بوت')
    bullet(doc, 'رسالة ترحيبية')
    bullet(doc, 'Chips (أزرار بيضاوية):', ' اقتراحات سريعة زي "أسعار الاستوديوهات؟" و"ازاي أحجز؟"')

    subsubsection(doc, 'فقاعات الرسائل (Bubbles)')
    body(doc, 'رسائل العميل بتظهر على اليمين بـ gradient أزرق. ردود البوت بتظهر على الشمال بخلفية الكارد. الزوايا مختلفة: رسالة العميل بيبقى corner يمين تحت صغير جداً (4px) عشان يوضّح اتجاه الرسالة.')

    subsubsection(doc, 'Loading Indicator')
    body(doc, 'بعد ما العميل يبعت رسالة وقبل ما الرد ييجي، بيظهر LinearProgressIndicator في أعلى الشاشة — خط رفيع بيتحرك. ده بيحسّس المستخدم إن في حاجة بتحصل.')

    subsubsection(doc, 'صندوق الكتابة')
    body(doc, 'TextField مستدير الحواف (borderRadius: 24) مع زرار إرسال دايري ٤٤×٤٤ بـ gradient وـ shadow — يعطي إحساس بالعمق وتجاوب مع الضغط.')

    section(doc, '٥.٥ اكتشاف لغة الرد')
    body(doc, 'التطبيق بيشوف اللغة من آخر رسالة للعميل باستخدام Regex:')
    code_line(doc, "RegExp(r'[؀-ۿ]').hasMatch(lastUserMessage)")
    body(doc, 'لو فيه حروف عربية في الرسالة، التطبيق بيبعت طلب للسيرفر يجاوب بالعربي. لو إنجليزي، بالإنجليزي.')

    section(doc, '٥.٦ اكتشاف نية الحجز')
    body(doc, 'البوت ممكن يرد بـ JSON مخفي في رده، فيه بيانات حجز:')
    code_line(doc, '{"booking_intent": {"studio": "Studio A", "date": "2024-12-01", "hours": 3}}')
    body(doc, 'ChatbotBookingService.extractBookingIntent() بيحلل رد البوت، لو لاقى JSON بيانات حجز، بيعبّي فورم الحجز تلقائياً وبيودّي العميل عليه. العميل بس بيراجع ويضغط "احجز".')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٦. شات الدعم البشري (Support Chat)')

    section(doc, '٦.١ الفرق بين الشات بوت وشات الدعم')
    body(doc, 'الشات بوت = ذكاء اصطناعي تلقائي، مفيش بشر بيرد.')
    body(doc, 'شات الدعم = محادثة حقيقية بين العميل وموظف من الاستوديو.')
    table(doc, [
        ['', 'الشات بوت', 'شات الدعم'],
        ['من يرد؟', 'AI (Python Flask)', 'موظف بشري'],
        ['السيرفر', 'AWS EC2', 'AWS AppSync + DynamoDB'],
        ['الاستجابة', 'فورية', 'خلال دقائق'],
        ['الغرض', 'معلومات عامة + حجز', 'مشاكل وشكاوى واستفسارات'],
    ])

    section(doc, '٦.٢ كيف يشتغل؟')
    body(doc, 'العميل بيبعت رسالة → بتتكتب في DynamoDB كـ ChatMessage record. الموظف عنده polling كل ١٠ ثوانٍ يجيب الرسائل الجديدة. الموظف بيرد → الرد بيتكتب في DynamoDB كمان. العميل عنده polling كمان يشوف الردود الجديدة.')
    body(doc, 'كل المحادثة بتتعرّف بـ clientEmail — إيميل العميل هو اللي بيجمع رسائل المحادثة كلها سواء جت من العميل أو من الموظف.')

    section(doc, '٦.٣ التحكم في الشات (من جانب الموظف)')
    body(doc, 'الموظف يقدر:')
    bullet(doc, 'يفتح/يقفل الشات:', ' toggle switch يمنع العميل من بعت رسائل لو الـ toggle مقفول')
    bullet(doc, 'يحذف المحادثة:', ' يمسح كل رسائل الـ thread ده من DynamoDB')
    body(doc, 'لما الموظف يفتح الشات، العميل بياخد إشعار: "فريق الدعم فتح الشات معاك".')

    section(doc, '٦.٤ Optimistic UI في الـ Toggle')
    body(doc, 'عشان الـ toggle ما يتأخرش، استخدمنا Optimistic Update:')
    code_line(doc, 'setState(() => _chatEnabledCache[email] = next);  // تحديث فوري في الـ UI')
    code_line(doc, 'await AWSStorageService.enableChatForClient(...); // تحديث في السيرفر')
    body(doc, 'التطبيق بيحدّث الشاشة فوراً قبل ما يرجع رد السيرفر. لو السيرفر فشل، الـ cache بيفضل بالقيمة الجديدة — مقبول عشان الموظف يقدر يجرب تاني.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٧. شاشات الموظف — لوحة التحكم')

    section(doc, '٧.١ نظرة عامة')
    body(doc, 'شاشة الموظفين (Employees_screen.dart) هي لوحة تحكم كاملة. فيها ٤ تبويبات رئيسية:')
    bullet(doc, 'Dashboard:', ' إدارة الحجوزات')
    bullet(doc, 'Support:', ' inbox رسائل العملاء')
    bullet(doc, 'Studios:', ' إضافة/تعديل/مسح الاستوديوهات')
    bullet(doc, 'Services:', ' إدارة كتالوج الخدمات')

    section(doc, '٧.٢ إدارة الحجوزات (Dashboard Tab)')
    body(doc, 'الـ Dashboard بيعرض كل الحجوزات مع إمكانية الفلترة:')

    subsubsection(doc, 'Filter Chips')
    body(doc, 'صف من الأزرار البيضاوية في الأعلى: الكل — Pending — Approved — Rejected — Done. الضغط على أي chip بيفلتر القائمة على طول.')

    subsubsection(doc, 'بطاقة الحجز')
    body(doc, 'كل حجز بيظهر كبطاقة فيها:')
    bullet(doc, 'اسم العميل والإيميل والتليفون')
    bullet(doc, 'اسم الاستوديو')
    bullet(doc, 'التاريخ والساعات')
    bullet(doc, 'المبلغ الإجمالي')
    bullet(doc, 'Badge ملوّن للحالة:', ' كهرماني = Pending، أخضر = Approved، أحمر = Rejected، نيفي = Done')
    bullet(doc, '٣ أزرار:', ' Approve (أخضر) — Reject (أحمر) — Mark as Done (أزرق)')

    subsubsection(doc, 'لما الموظف يضغط Approve أو Reject')
    body(doc, 'بيفتح AlertDialog فيه textarea فيه رسالة جاهزة. الموظف يقدر يعدّل الرسالة قبل ما يبعتها. الضغط على "تأكيد" بيحدّث الحالة في DynamoDB وبيبعت إشعار للعميل برسالة الموظف.')

    subsubsection(doc, 'الأرشيف')
    body(doc, 'الحجوزات اللي خلصت (Done أو تاريخها فات) بتنزل في قسم منفصل اسمه Archive في أسفل الشاشة. قسم قابل للطي/الفتح.')

    section(doc, '٧.٣ نظام الإشعارات — جانب الموظف')
    body(doc, 'في الـ AppBar في أيقونة bell فيها رقم حمرا يوضح عدد الإشعارات غير المقروءة. الرقم بيتعلّى لـ "9+" لو أكتر من ٩. الإشعارات بتتحدث كل ١٥ ثانية.')
    body(doc, 'لما حجز جديد ييجي، بيظهر Banner مخصص في أعلى الشاشة:')
    bullet(doc, 'بطاقة بيضاء مع حافة نيفي مضيئة')
    bullet(doc, 'أيقونة تقويم في مربع مستدير الحواف')
    bullet(doc, 'عنوان الإشعار + جزء من النص')
    bullet(doc, 'زرار "View" صغير', '')
    body(doc, 'البانر ده بيفضل ٥ ثوانٍ وبعدين بيختفي لوحده.')

    section(doc, '٧.٤ Layout الشاشة الواسعة')
    body(doc, 'لما عرض الشاشة يبقى ≥ 800px (تابلت أو ويب)، الـ Dashboard بيتحول لتصميم عمودين: عمود للقائمة، عمود للتفاصيل. ده بيستغل المساحة أحسن ويخلي الموظف يشتغل أسرع.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٨. نظام الإشعارات')

    section(doc, '٨.١ ليه مش بنستخدم Push Notifications حقيقية؟')
    body(doc, 'الـ Push Notifications الحقيقية (زي اللي WhatsApp بيبعتها وإنت خارج التطبيق) محتاجة:')
    bullet(doc, 'شهادة APNs من Apple (للـ iOS)')
    bullet(doc, 'Firebase FCM key (للـ Android)')
    bullet(doc, 'Device Token لكل جهاز')
    bullet(doc, 'Server يبعت للـ Push servers')
    body(doc, 'ده تعقيد إضافي. قررنا نعمل "In-App Notifications" — الإشعارات بتتخزن في DynamoDB والتطبيق بيجيبها وهو شغّال. مناسب لتطبيق حجز — المستخدم مش محتاج يشوف الإشعار وهو خارج التطبيق.')

    section(doc, '٨.٢ متى بيتبعت إشعار؟')
    table(doc, [
        ['الحدث', 'المُرسِل', 'المستلم', 'الرسالة'],
        ['حجز جديد', 'النظام', 'الموظفون', '"طلب حجز جديد من [اسم العميل]"'],
        ['حجز جديد', 'النظام', 'العميل', '"طلبك اتسجّل وبينتظر المراجعة"'],
        ['الحجز اتوافق', 'الموظف', 'العميل', 'رسالة الموظف المخصصة'],
        ['الحجز اترفض', 'الموظف', 'العميل', 'رسالة الموظف المخصصة'],
        ['فتح الشات', 'الموظف', 'العميل', '"فريق الدعم فتح الشات معاك"'],
    ])

    section(doc, '٨.٣ تصميم البانر')
    body(doc, 'البانر عبارة عن SnackBar بخلفية شفافة (backgroundColor: transparent) عشان يظهر الـ Container المخصص جواه. التصميم: بطاقة بيضاء (أو داكنة في Dark Mode) بحافة نيفي شفافة وـ shadow ناعمة. جوّاه: أيقونة في مربع مستدير + عنوان + نص + زرار View.')
    note(doc, 'استخدمنا withValues(alpha: 0.4) بدل withOpacity() عشان Amplify.Auth بيستخدم API جديد. withOpacity() اتعمل deprecated في Flutter الجديد.')

    section(doc, '٨.٤ شاشة الإشعارات الكاملة')
    body(doc, 'غير البانر، في NotificationsScreen بتعرض كل الإشعارات مرتبة من الأحدث. كل إشعار فيه:')
    bullet(doc, 'أيقونة وبتاعة النوع:', ' ✓ خضرا للموافقة، ✗ حمرا للرفض')
    bullet(doc, 'العنوان بولد')
    bullet(doc, 'نص الرسالة')
    bullet(doc, 'الوقت النسبي:', ' "منذ ساعتين" أو "أمس"')
    bullet(doc, 'نقطة زرقا:', ' للإشعارات غير المقروءة')
    body(doc, 'الضغط على إشعار بيعلّمه مقروء (read: "true" في DynamoDB).')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '٩. التقارير والتحليلات')

    section(doc, '٩.١ من بيشوف التقارير؟')
    body(doc, 'تبويب التقارير (ReportsScreen) متاح للموظفين فقط. مش ظاهر في navigation العميل خالص، وحتى لو حد حاول يجيب البيانات مباشرة، AppSync بيرفض لأن العميل مش في Employees group.')

    section(doc, '٩.٢ الإحصائيات المعروضة')
    bullet(doc, 'حجم الحجوزات اليومية:', ' BarChart بيوضح عدد الحجوزات لكل يوم')
    bullet(doc, 'إيراد كل استوديو:', ' BarChart مقارنة بين الاستوديوهات')
    bullet(doc, 'توزيع حالات الحجوزات:', ' PieChart (Pending/Approved/Rejected/Done)')
    bullet(doc, 'أعلى العملاء إنفاقاً:', ' قائمة مرتبة حسب إجمالي الحجوزات المؤكدة')
    body(doc, 'فيه ٣ فترات زمنية: اليوم — هذا الأسبوع — هذا الشهر.')

    section(doc, '٩.٣ fl_chart — مكتبة الرسوم البيانية')
    body(doc, 'fl_chart هي مكتبة Flutter للرسوم البيانية. مش بتستخدم WebView أو JavaScript — بترسم مباشرة على الـ GPU زي باقي الـ widgets. المميزات:')
    bullet(doc, 'Animation تلقائي لما البيانات تتحمّل')
    bullet(doc, 'Tooltips على اللمس')
    bullet(doc, 'بتتكيف مع Dark/Light Mode تلقائياً')

    section(doc, '٩.٤ تصدير PDF')
    body(doc, 'زرار "Export Report" بيولّد PDF على الجهاز مباشرة باستخدام مكتبة pdf. الـ PDF فيه:')
    bullet(doc, 'عنوان التقرير والتاريخ')
    bullet(doc, 'جدول بالإحصائيات الرئيسية')
    bullet(doc, 'ملخص الإيرادات')
    body(doc, 'بعد الحفظ، الـ Share Sheet بيظهر عشان الموظف يبعته على الإيميل أو WhatsApp.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١٠. قاعدة البيانات — DynamoDB والـ Schema')

    section(doc, '١٠.١ ليه DynamoDB مش SQL؟')
    body(doc, 'DynamoDB هي قاعدة بيانات NoSQL من Amazon. يعني البيانات بتتخزن كـ records مرنة مش في جداول بصفوف وأعمدة صارمة. المميزات:')
    bullet(doc, 'Scale تلقائي:', ' لو الطلبات زادت، Amazon بيزود الموارد لوحده')
    bullet(doc, 'بدون server management:', ' مش محتاج تدير database server')
    bullet(doc, 'تكامل مع AppSync:', ' بيتكلموا مع بعض مباشرة')

    section(doc, '١٠.٢ الـ Models (الجداول)')
    body(doc, 'عندنا ٥ models رئيسية:')

    subsubsection(doc, 'BookingRequest — الحجوزات')
    table(doc, [
        ['الفيلد', 'النوع', 'الوصف'],
        ['id', 'String', 'معرّف فريد للحجز (UUID تلقائي)'],
        ['clientEmail', 'String', 'إيميل العميل — مستخدم في الأمان (owner field)'],
        ['clientName', 'String', 'اسم العميل'],
        ['clientPhone', 'String', 'تليفون العميل'],
        ['studio', 'String', 'اسم الاستوديو المحجوز'],
        ['date', 'String', 'التاريخ (YYYY-MM-DD)'],
        ['hours', 'Int', 'عدد الساعات'],
        ['price', 'Float', 'السعر الإجمالي بالجنيه'],
        ['status', 'String', 'Pending / Approved / Rejected / Done'],
        ['fullStartDateTime', 'String', 'تاريخ ووقت البداية الكاملة (ISO 8601)'],
        ['fullEndDateTime', 'String', 'تاريخ ووقت النهاية الكاملة (ISO 8601)'],
    ])

    subsubsection(doc, 'Studio — الاستوديوهات')
    table(doc, [
        ['الفيلد', 'النوع', 'الوصف'],
        ['id', 'String', 'معرّف فريد'],
        ['name', 'String', 'اسم الاستوديو'],
        ['description', 'String', 'وصف الاستوديو'],
        ['location', 'String', 'موقع الاستوديو'],
        ['pricePerHour', 'Float', 'السعر بالساعة'],
        ['pricePerDay', 'Float', 'السعر باليوم'],
        ['imageUrl', 'String', 'مفتاح الصورة في S3'],
        ['available', 'Boolean', 'متاح للحجز أم لا'],
    ])

    subsubsection(doc, 'AppNotification — الإشعارات')
    table(doc, [
        ['الفيلد', 'النوع', 'الوصف'],
        ['clientEmail', 'String', 'إيميل المستلم (أو "employees" للموظفين)'],
        ['title', 'String', 'عنوان الإشعار'],
        ['body', 'String', 'نص الإشعار الكامل'],
        ['type', 'String', 'Approved / Rejected / chat_opened / إلخ'],
        ['time', 'String', 'الوقت (ISO 8601)'],
        ['read', 'String', '"true" أو "false"'],
    ])

    subsubsection(doc, 'ChatMessage — رسائل الدعم')
    body(doc, 'كل رسالة في شات الدعم بتتخزن كـ record مستقل فيه senderEmail (المُرسِل)، senderName (اسمه)، clientEmail (معرّف الـ thread)، text (النص)، time (الوقت).')

    subsubsection(doc, 'ServiceItem — الخدمات')
    body(doc, 'فيه فيلد name بالإنجليزي وfيلد nameAr بالعربي. التطبيق بيختار الصح حسب اللغة النشطة: لو العربي محدد وnameAr مش فاضي، بيعرض nameAr.')

    section(doc, '١٠.٣ قواعد الأمان (@auth)')
    body(doc, 'كل model عنده @auth rules بتحدد مين يقدر يعمل إيه:')
    table(doc, [
        ['الـ Model', 'العميل يقدر', 'الموظف يقدر'],
        ['BookingRequest', 'يضيف حجز خاص به — يشوف حجوزاته بس', 'يشوف كل الحجوزات — يعدّل الحالة — يمسح'],
        ['Studio', 'يشوف بس (لا تعديل)', 'إضافة / تعديل / مسح / قراءة'],
        ['AppNotification', 'يشوف إشعاراته — يعلّمها مقروءة', 'يضيف لأي إيميل — يقرأ كل الإشعارات'],
        ['ChatMessage', 'يضيف رسالة — يشوف thread الخاص به', 'يقرأ كل الـ threads — يضيف — يمسح'],
        ['ServiceItem', 'يشوف بس', 'إضافة / تعديل / مسح / قراءة'],
    ])
    note(doc, 'الـ @auth rules بتتطبّق على السيرفر (AppSync) مش في التطبيق بس. يعني حتى لو حد عمل hacking للتطبيق، السيرفر هيرفض أي طلب غير مصرّح.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١١. إزاي البيانات بتتحدث؟ (Real-Time Sync)')

    section(doc, '١١.١ المشكلة')
    body(doc, 'التطبيق محتاج يوضّح التغييرات الجديدة بسرعة. مثلاً لما موظف يوافق على حجز، العميل لازم يعرف قريباً. لو في حجز جديد، الموظف لازم يشوفه سريع.')

    section(doc, '١١.٢ الحل — Polling')
    body(doc, 'Polling يعني إن التطبيق بيسأل السيرفر كل فترة: "في حاجة اتغيرت؟". زي ما تسأل صاحبك كل ١٠ ثوانٍ "جالك رسالة؟".')
    body(doc, 'استخدمنا Timer.periodic في Dart لعمل ده تلقائياً:')
    code_line(doc, 'Timer.periodic(Duration(seconds: 12), (timer) => _pollBookings());')
    body(doc, 'كل timer بيستدعي method تروح لـ AWS وتجيب البيانات وتحدّث الشاشة لو في تغيير.')

    section(doc, '١١.٣ جدول التحديثات')
    table(doc, [
        ['البيانات', 'من يحتاجها', 'كل كام؟', 'ليه هذا الوقت؟'],
        ['الاستوديوهات', 'العميل والموظف', '٩٠ ثانية', 'بتتغير نادراً — مش ضروري كتير'],
        ['الحجوزات', 'العميل', '١٢ ثانية', 'مهمة للعميل يعرف التحديثات'],
        ['الحجوزات', 'الموظف', '٨ ثوانٍ', 'أسرع للموظف عشان يتعامل بسرعة'],
        ['رسائل الدعم', 'الموظف', '١٠ ثوانٍ', 'وقت استجابة معقول للدعم'],
        ['الإشعارات', 'العميل', '٢٠ ثانية', 'الإشعارات مش urgent جداً'],
        ['الإشعارات', 'الموظف', '١٥ ثانية', 'أسرع شوية للموظفين'],
    ])

    section(doc, '١١.٤ Smart Change Detection — مش بنرسم لو مفيش تغيير')
    body(doc, 'الـ polling مش بيحدث الشاشة دايماً. قبل setState()، بيقارن البيانات الجديدة بالقديمة:')
    code_line(doc, 'final changed = ids.length != newIds.length ||')
    code_line(doc, '    ids.any((id) => !newIds.contains(id)) || ...')
    code_line(doc, 'if (changed) setState(() => studios = loaded);')
    body(doc, 'لو البيانات نفسها، setState() مش بتتستدعى ومفيش رسم تاني للشاشة. ده بيوفّر battery وأداء.')

    section(doc, '١١.٥ Ghost Records — منع ظهور الاستوديوهات المحذوفة')
    body(doc, 'لما موظف يمسح استوديو، DynamoDB بيمسحه لكن في تأخير صغير في الانتشار. في خلال هذه الفترة، لو العميل جاب الاستوديوهات ممكن الاستوديو المحذوف يظهر لثانية.')
    body(doc, 'الحل: Set اسمها _deletedStudioIds بتحفظ الـ IDs المحذوفة لـ ٥ ثوانٍ. أي استوديو ID موجود في الـ Set بيتفلتر ومش بيظهر حتى بعد الـ ٥ ثوانٍ.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١٢. التصميم البصري — Design System')

    section(doc, '١٢.١ الألوان')
    body(doc, 'كل الألوان متعرّفة في AppColors class. مفيش شاشة بتكتب hex color مباشرة — كلها بتيجي من AppColors. ده بيضمن توحيد الألوان في كل مكان.')
    table(doc, [
        ['الـ Token', 'اللون', 'بيُستخدم في'],
        ['primary (النيفي)', '#1E3A5F', 'الأزرار، الحالة النشطة، الروابط'],
        ['gradientStart', 'أزرق غامق', 'gradient البانر والفقاعات وزرار الإرسال'],
        ['success (أخضر)', '#22C55E', 'حجز مؤكد، Approved، تفعيل toggle'],
        ['error (أحمر)', '#EF4444', 'رسائل خطأ، Reject، مسح، badge غير مقروء'],
        ['warning (كهرماني)', '#F59E0B', 'Pending، تحذيرات'],
    ])

    section(doc, '١٢.٢ شكل الكروت والزوايا')
    body(doc, 'كل الكروت والـ input fields والـ dialogs بتستخدم BorderRadius.circular(20). الأزرار والـ chips بتستخدم circular(20) أو circular(12). ده بيدي التطبيق طابع ناعم ومريح.')
    body(doc, 'الـ elevation (الظل) بيتعمل بـ BoxShadow بـ opacity خفيف جداً (alpha: 0.04) بدل Material elevation الافتراضي. النتيجة: عمق بدون ظل قاسي.')

    section(doc, '١٢.٣ Dark Mode و Light Mode')
    body(doc, 'كل ويدجت بيستخدم نمط:')
    code_line(doc, 'color: isDark ? AppColors.darkCard : AppColors.lightSurface')
    body(doc, 'مش في حاجة بتكتب لون ثابت بدون conditional. ده بيضمن إن Dark Mode بيشتغل صح في كل مكان. التبديل بين الـ modes بيحصل فوراً بدون restart — SettingsService.themeMode هو ValueNotifier، أي تغيير بيـ rebuild الـ MaterialApp بس.')

    section(doc, '١٢.٤ الخطوط')
    body(doc, 'الهيدرات بتستخدم FontWeight.w800 (Extra Bold) مع letterSpacing: -0.5 — ده بيدي شكل عصري وهادي. النص العادي FontWeight.w400. الأحجام:')
    bullet(doc, '٢٠px:', ' عناوين الأقسام')
    bullet(doc, '١٥-١٦px:', ' عناوين الكروت')
    bullet(doc, '١٣px:', ' نص عادي ووصف')
    bullet(doc, '١١-١٢px:', ' metadata، badges، captions')

    section(doc, '١٢.٥ Text Scale Clamping')
    body(doc, 'بعض المستخدمين بيكبّروا خط الجهاز في إعدادات Accessibility ل ٢٠٠%. لو التطبيق شغّال بالخط الكبير ده، الكروت هتبوظ والـ layout هينكسر.')
    body(doc, 'الحل: بنقيّد الـ text scale بين 85% و120%:')
    code_line(doc, 'textScaler: TextScaler.linear(mq.textScaler.scale(1).clamp(0.85, 1.2))')
    body(doc, 'يعني أقصى تكبير مسموح ١٢٠% وأقل تصغير ٨٥%. الـ layout بيفضل سليم.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١٣. اللغة العربية والاستجابة')

    section(doc, '١٣.١ Bilingual Support — عربي وإنجليزي')
    body(doc, 'التطبيق بيدعم العربي والإنجليزي بشكل كامل. كل النصوص متعرّفة في AppLocalizations class كـ key-value map. بدل ما تكتب النص مباشرة في الكود، بتكتب:')
    code_line(doc, 'AppLocalizations.of(context).translate("book_now")')
    body(doc, 'وده بيرجع "Book Now" بالإنجليزي أو "احجز الآن" بالعربي حسب اللغة الحالية.')

    section(doc, '١٣.٢ تبديل اللغة في الـ Real-time')
    body(doc, 'تبديل اللغة بيحصل فوراً بدون restart:')
    code_line(doc, 'SettingsService.locale.value = Locale("ar"); // يبدّل كل التطبيق للعربي')
    body(doc, 'SettingsService.locale هو ValueNotifier. أي تغيير بيـ rebuild الـ MaterialApp بس، واللي بدوره بيـ rebuild كل الشاشات باللغة الجديدة.')

    section(doc, '١٣.٣ RTL — اليمين لليسار')
    body(doc, 'لما اللغة تتبدل للعربي، Flutter تلقائياً بيعكس الـ layout:')
    bullet(doc, 'الـ Row بيعكس اتجاهه')
    bullet(doc, 'الـ Text محاذاة لليمين')
    bullet(doc, 'الـ Drawer بييجي من اليمين مش الشمال')
    bullet(doc, 'الـ Padding والـ Margin بتتعكس')
    body(doc, 'ده بيحصل تلقائياً لأن التطبيق مسجّل GlobalWidgetsLocalizations.delegate. مش محتاجين نعمل حاجة إضافية في كل شاشة.')

    section(doc, '١٣.٤ الحقول ثنائية اللغة في الـ Database')
    body(doc, 'ServiceItem model فيه name (إنجليزي) وnameAr (عربي). عند العرض:')
    code_line(doc, 'isAr && nameAr.isNotEmpty ? nameAr : name')
    body(doc, 'لو اللغة عربي والـ nameAr موجود، بيعرض العربي. غير كده بيعرض الإنجليزي.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١٤. إدارة الحالة (State Management)')

    section(doc, '١٤.١ إيه هو State Management؟')
    body(doc, 'State هي البيانات اللي التطبيق بيتذكرها ويعرضها. مثلاً: الاستوديوهات المحمّلة، اسم المستخدم، اللغة الحالية، حالة التحميل، إلخ. State Management هو كيف بنخزن ونشارك ونحدّث الـ state ده.')

    section(doc, '١٤.٢ المستويات في تطبيقنا')
    table(doc, [
        ['المستوى', 'الأداة', 'بيُستخدم لـ'],
        ['Global — بين كل الشاشات', 'Provider + AppState', 'بيانات المستخدم: الاسم، الإيميل، النوع، الصورة'],
        ['Global خفيف', 'ValueNotifier', 'الـ Theme (Dark/Light) — اللغة (AR/EN)'],
        ['داخل شاشة واحدة', 'StatefulWidget + setState()', 'بيانات الشاشة: الحجوزات، الاستوديوهات، حالة التحميل'],
        ['Real-time events', 'StreamSubscription', 'GraphQL Subscriptions للـ WebSocket'],
        ['Periodic refresh', 'Timer.periodic', 'Polling كل X ثوانٍ'],
    ])

    section(doc, '١٤.٣ ليه ValueNotifier وليس Provider للـ Theme؟')
    body(doc, 'لو استخدمنا Provider للـ Theme، لما اللون يتغير كل widget بيستخدم context.watch<AppState>() هيـ rebuild — وده ممكن يكون ألاف الـ widgets!')
    body(doc, 'ValueNotifier بيعمل rebuild للـ ValueListenableBuilder بس — اللي هو MaterialApp. يعني تغيير الـ Theme بيـ rebuild الـ MaterialApp فقط، وده كافي لتطبيق اللون الجديد على كل مكان.')
    note(doc, 'ده optimisation مهم — مش مجرد code style.')

    page_break(doc)

    # ══════════════════════════════════════════════════════════════════
    chapter_title(doc, '١٥. ملخص عام')

    section(doc, '١٥.١ إيه اللي اتعمل؟')
    body(doc, 'تطبيق Gen Z Studio هو تطبيق Flutter متكامل بيشغّل على Android وiOS والويب من كود واحد. بيدعم نوعين من المستخدمين — عملاء وموظفين — مع صلاحيات مختلفة تماماً، backend سحابي على AWS، وذكاء اصطناعي مدمج.')

    section(doc, '١٥.٢ التحديات اللي اتحلّت')
    table(doc, [
        ['التحدي', 'السبب', 'الحل'],
        ['DataStore مش شغّال', 'Owner-auth بيرفض bulk sync', 'أوقفنا DataStore واشتغلنا بـ Amplify.API مباشرة'],
        ['Double booking', 'عميلان يحجزوا نفس الوقت', 'Atomic write مع DynamoDB conditional expression'],
        ['Ghost records', 'تأخير في انتشار الحذف', '_deletedStudioIds Set بتفلتر لـ ٥ ثوانٍ'],
        ['خط كبير يكسر الـ layout', 'Accessibility font scale > 200%', 'TextScaler.clamp(0.85, 1.2) في main.dart'],
        ['RTL للعربي', 'العربي من اليمين للشمال', 'GlobalWidgetsLocalizations.delegate'],
        ['Chatbot مش عارف اللغة', 'المستخدم ممكن يكتب عربي أو إنجليزي', 'RegEx بيكشف الحروف العربية ويختار اللغة'],
    ])

    section(doc, '١٥.٣ ملخص التقنيات')
    table(doc, [
        ['المكوّن', 'التقنية'],
        ['واجهة المستخدم', 'Flutter (Dart) — AOT Compiled'],
        ['تسجيل الدخول', 'Amazon Cognito (JWT + User Pool Groups)'],
        ['الـ API', 'AWS AppSync (GraphQL)'],
        ['قاعدة البيانات', 'Amazon DynamoDB (NoSQL)'],
        ['الصور', 'Amazon S3'],
        ['الشات بوت', 'Python Flask على AWS EC2'],
        ['إدارة الحالة', 'setState + Provider + ValueNotifier'],
        ['اللغات', 'عربي / إنجليزي مع RTL'],
        ['الرسوم البيانية', 'fl_chart'],
        ['تصدير PDF', 'pdf package (pw)'],
        ['التخزين المحلي', 'SharedPreferences'],
    ])

    body(doc, 'النتيجة النهائية: تطبيق احترافي متكامل يخدم عميل يقدر يكتشف الاستوديوهات ويتكلم مع الـ AI ويحجز، وموظف يقدر يدير كل العمليات ويشوف التقارير — كل ده من تطبيق موبايل واحد.')

# ── تشغيل ──────────────────────────────────────────────────────────────────────

def main():
    print('Building Arabic file...')
    doc = Document()

    for section_obj in doc.sections:
        section_obj.top_margin    = Cm(2.5)
        section_obj.bottom_margin = Cm(2.5)
        section_obj.left_margin   = Cm(2.8)
        section_obj.right_margin  = Cm(2.8)

    normal = doc.styles['Normal']
    normal.font.name = 'Calibri'
    normal.font.size = Pt(12)

    # RTL document direction
    settings = doc.settings.element
    compat = OxmlElement('w:compat')
    bidiDoc = OxmlElement('w:bidiDocument')
    compat.append(bidiDoc)
    settings.append(compat)

    build(doc)

    doc.save(DOCX_PATH)
    size_kb = os.path.getsize(DOCX_PATH) // 1024
    print(f'Done! -> {DOCX_PATH}')
    print(f'Size: {size_kb} KB')

if __name__ == '__main__':
    main()
