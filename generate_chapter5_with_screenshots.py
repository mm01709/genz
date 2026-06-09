"""
Generate Chapter 5 - GenZ Studios Mobile Application
Professional Word document with embedded app screenshots.
- Chapter/section titles: 18pt Bold
- Body text: 14pt normal
- Figure captions below every image/table
- All app screenshots embedded in their proper sections
- English throughout, minimal color (professional academic style)
"""

from docx import Document
from docx.shared import Pt, Cm, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import os

DOCX_PATH = r"d:\myapp\GenZ\Chapter5_App_Screens.docx"
SCREENS_DIR = r"d:\myapp\GenZ\screenshots"

# ── Screenshot map: filename → (figure_number, caption) ──────────────────────
# Based on visual inspection of saved screens:
# screen_00: Client Home Screen
# screen_01: My Bookings - All tab
# screen_02: My Bookings - Pending tab (empty)
# screen_03: My Bookings - Approved tab
# screen_04: My Bookings - Rejected tab
# screen_05: My Tickets (Support Tickets list)
# screen_06: Support Chat - Disabled state
# screen_07: Notifications screen
# screen_08: Settings (Client)
# screen_09: Onboarding page 1 - Welcome
# screen_10: Onboarding page 2 - Browse Studios
# screen_11: Onboarding page 3 - Book a Studio
# screen_12: Onboarding page 4 - Track Your Bookings
# screen_13: Onboarding page 5 - Support & Help
# screen_14: AI Chatbot (GENZ AI)
# screen_15: Support Chat - Live conversation (client side)
# screen_16: Employee Dashboard - Stats cards
# screen_17: Employee Dashboard - Bookings + Archive list
# screen_18: Employee Dashboard - Archive expanded
# screen_19: Employee Support Tickets list
# screen_20: Employee Support Chat thread
# screen_21: Employee Studios grid
# screen_22: New Studio form - top
# screen_23: New Studio form - bottom
# screen_24: Employee Services list
# screen_25: Add Service bottom sheet
# screen_26: Reports screen
# screen_27: Employee Settings

IMG_WIDTH = Inches(2.6)   # phone screenshots are tall; fit 2 per row nicely

# ── Document styling helpers ─────────────────────────────────────────────────

def new_doc():
    doc = Document()
    # Page margins
    for section in doc.sections:
        section.top_margin    = Cm(2.5)
        section.bottom_margin = Cm(2.5)
        section.left_margin   = Cm(3.0)
        section.right_margin  = Cm(2.5)
    return doc


def _set_font(run, size_pt, bold=False, color=None):
    run.font.name  = "Calibri"
    run.font.size  = Pt(size_pt)
    run.font.bold  = bold
    if color:
        run.font.color.rgb = RGBColor(*color)


def heading1(doc, text):
    """Chapter title - 18pt Bold, centered, space before."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(24)
    p.paragraph_format.space_after  = Pt(12)
    run = p.add_run(text)
    _set_font(run, 18, bold=True)
    return p


def heading2(doc, text):
    """Section heading - 18pt Bold, left, space before."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(18)
    p.paragraph_format.space_after  = Pt(6)
    run = p.add_run(text)
    _set_font(run, 18, bold=True)
    return p


def heading3(doc, text):
    """Sub-section heading - 14pt Bold."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after  = Pt(4)
    run = p.add_run(text)
    _set_font(run, 14, bold=True)
    return p


def body(doc, text):
    """Body paragraph - 14pt, justified, 1.15 line spacing."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after  = Pt(6)
    # 1.15 line spacing
    p.paragraph_format.line_spacing = Pt(14 * 1.15)
    run = p.add_run(text)
    _set_font(run, 14)
    return p


def bullet(doc, text, level=0):
    """Bullet point - 14pt."""
    p = doc.add_paragraph(style="List Bullet" if level == 0 else "List Bullet 2")
    p.paragraph_format.space_after = Pt(3)
    run = p.add_run(text)
    _set_font(run, 14)
    return p


def figure_caption(doc, number, text):
    """Figure caption below an image - 12pt italic, centered."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after  = Pt(14)
    run = p.add_run(f"Figure {number}: {text}")
    run.font.name   = "Calibri"
    run.font.size   = Pt(12)
    run.font.italic = True
    return p


def add_image(doc, filename, fig_num, caption, width=IMG_WIDTH):
    """Insert a centered image with figure caption below."""
    img_path = os.path.join(SCREENS_DIR, filename)
    if not os.path.exists(img_path):
        body(doc, f"[Screenshot not found: {filename}]")
        return
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    run = p.add_run()
    run.add_picture(img_path, width=width)
    figure_caption(doc, fig_num, caption)


def add_two_images(doc, file1, fig1, cap1, file2, fig2, cap2):
    """Place two phone screenshots side by side in a 2-column table."""
    tbl = doc.add_table(rows=2, cols=2)
    tbl.style = "Table Grid"
    # Remove all borders for a clean look
    for row in tbl.rows:
        for cell in row.cells:
            tc = cell._tc
            tcPr = tc.get_or_add_tcPr()
            tcBorders = OxmlElement("w:tcBorders")
            for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
                border = OxmlElement(f"w:{side}")
                border.set(qn("w:val"), "none")
                tcBorders.append(border)
            tcPr.append(tcBorders)

    def _img_cell(cell, filepath, width=IMG_WIDTH):
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if os.path.exists(filepath):
            run = p.add_run()
            run.add_picture(filepath, width=width)

    def _cap_cell(cell, fig_num, text):
        cell.vertical_alignment = WD_ALIGN_VERTICAL.TOP
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run(f"Figure {fig_num}: {text}")
        run.font.name   = "Calibri"
        run.font.size   = Pt(11)
        run.font.italic = True

    _img_cell(tbl.rows[0].cells[0], os.path.join(SCREENS_DIR, file1))
    _img_cell(tbl.rows[0].cells[1], os.path.join(SCREENS_DIR, file2))
    _cap_cell(tbl.rows[1].cells[0], fig1, cap1)
    _cap_cell(tbl.rows[1].cells[1], fig2, cap2)

    doc.add_paragraph()   # spacer


def page_break(doc):
    doc.add_page_break()


# ── Figure counter ────────────────────────────────────────────────────────────
fig = [1]

def F(caption, filename=None, filename2=None, caption2=None):
    """Return (fig_number, caption) and advance counter."""
    n = fig[0]
    fig[0] += 1
    if filename2:
        n2 = fig[0]
        fig[0] += 1
        return n, caption, n2, caption2
    return n, caption


# ═════════════════════════════════════════════════════════════════════════════
# BUILD DOCUMENT
# ═════════════════════════════════════════════════════════════════════════════

def build():
    doc = new_doc()

    # ── COVER / TITLE ─────────────────────────────────────────────────────────
    for _ in range(4):
        doc.add_paragraph()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("CHAPTER 5")
    _set_font(r, 16, bold=True)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("Mobile Application Implementation")
    _set_font(r, 22, bold=True)

    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("GenZ Studios — Flutter & AWS Amplify")
    _set_font(r, 14)

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.1  INTRODUCTION
    # ═══════════════════════════════════════════════════════════════════════════
    heading1(doc, "Chapter 5: Mobile Application Implementation")
    heading2(doc, "5.1  Introduction")

    body(doc,
         "This chapter presents the complete implementation of the GenZ Studios mobile "
         "application, a cross-platform studio-booking platform built with Flutter and "
         "powered by Amazon Web Services (AWS). The application serves two distinct user "
         "roles — clients who discover and book photography and recording studios, and "
         "employees who manage studio inventory, approve or reject booking requests, and "
         "communicate with clients through a live support chat system.")

    body(doc,
         "The implementation spans several interrelated subsystems: a Flutter front-end "
         "compiled to native Android and iOS binaries, an AWS Amplify back-end providing "
         "authentication (Amazon Cognito), a GraphQL API (AWS AppSync), a NoSQL database "
         "(Amazon DynamoDB), and object storage (Amazon S3). An AI chatbot hosted on an "
         "AWS EC2 instance provides instant, conversational answers to client questions "
         "about studio availability and pricing.")

    body(doc,
         "The chapter is organised as follows: Section 5.2 explains the technology stack "
         "and why each technology was selected. Section 5.3 walks through the application "
         "architecture. Sections 5.4–5.8 detail the client-side screens. Sections 5.9–5.14 "
         "cover the employee-side screens and management tools. Section 5.15 presents the "
         "data models, and Section 5.16 summarises the chapter.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.2  TECHNOLOGY STACK
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.2  Technology Stack")

    body(doc,
         "The GenZ Studios application is built on a carefully chosen set of modern "
         "technologies that balance developer productivity, runtime performance, and "
         "cloud scalability.")

    heading3(doc, "5.2.1  Flutter (Dart)")
    body(doc,
         "Flutter is Google's open-source UI framework that compiles Dart code directly "
         "to native ARM machine code using Ahead-of-Time (AOT) compilation. Unlike "
         "frameworks that rely on a JavaScript bridge, Flutter draws every pixel through "
         "the Skia/Impeller GPU renderer, achieving consistent 60–120 fps performance on "
         "both Android and iOS from a single codebase. The widget tree model, combined "
         "with hot reload during development, dramatically shortens the iteration cycle. "
         "Material Design 3 widgets provide a polished, accessible baseline that the "
         "application customises with its dark-mode colour palette.")

    heading3(doc, "5.2.2  AWS Amplify")
    body(doc,
         "AWS Amplify provides a set of Flutter libraries — amplify_flutter, "
         "amplify_auth_cognito, amplify_api, and amplify_storage_s3 — that connect the "
         "mobile client to the AWS back-end with minimal boilerplate. Amplify handles "
         "token management, request signing, and offline caching, allowing the application "
         "code to focus on business logic rather than infrastructure concerns.")

    heading3(doc, "5.2.3  Amazon Cognito")
    body(doc,
         "Amazon Cognito manages user authentication via a User Pool configured with "
         "email and password sign-in, email OTP verification, and two Cognito Groups: "
         "'Clients' and 'Employees'. At login, Cognito issues three JWTs — an ID token, "
         "an Access token, and a Refresh token — that are stored securely in the Android "
         "Keystore and iOS Keychain. The group membership embedded in the ID token drives "
         "the conditional navigation logic that routes users to the correct interface.")

    heading3(doc, "5.2.4  AWS AppSync (GraphQL)")
    body(doc,
         "AWS AppSync provides a managed GraphQL endpoint backed by DynamoDB resolvers. "
         "The schema uses @model directives for automatic CRUD resolvers and @auth "
         "directives to enforce owner-based and group-based access rules at the API layer. "
         "All GraphQL operations are signed with AWS SigV4 via the Cognito Access token, "
         "ensuring that unauthenticated requests are rejected before reaching the database.")

    heading3(doc, "5.2.5  Amazon DynamoDB")
    body(doc,
         "DynamoDB is the primary persistent store. Each Amplify @model maps to a "
         "DynamoDB table with an auto-generated string UUID as the partition key. The five "
         "core tables are: BookingRequest, Studio, AppNotification, ChatMessage, and "
         "ServiceItem. Because DynamoDB is eventually consistent, the application "
         "implements a polling strategy with per-entity refresh intervals to keep the UI "
         "up to date without WebSocket subscriptions.")

    heading3(doc, "5.2.6  Amazon S3")
    body(doc,
         "Amazon S3 stores studio photographs uploaded by employees. Each image is stored "
         "under a key derived from the studio ID, and the URL is embedded in the Studio "
         "record so the client can load it via HTTPS. The amplify_storage_s3 library "
         "handles multipart uploads and generates pre-signed download URLs.")

    heading3(doc, "5.2.7  AWS EC2 AI Chatbot")
    body(doc,
         "A Python Flask service running on an AWS EC2 instance at port 5000 exposes a "
         "/chat endpoint. The chatbot is specialised for the GenZ Studios domain: it can "
         "answer questions about studio types, pricing, availability, and the booking "
         "process. The Flutter client sends an HTTP POST with the user message and "
         "displays the plain-text response in a chat bubble interface.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.3  APPLICATION ARCHITECTURE
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.3  Application Architecture")

    body(doc,
         "The application follows a layered architecture with clear separation between "
         "the presentation layer, the data layer, and the cloud services layer.")

    body(doc,
         "At the top, Flutter screens (StatefulWidgets) own the UI state and call into "
         "the data layer directly via the Amplify API client. There is no intermediate "
         "state-management framework — setState and passed callbacks are sufficient for "
         "the current screen set, keeping the codebase lean and navigable.")

    body(doc,
         "The data layer (lib/data/) wraps every AppSync operation in typed Dart "
         "functions that handle GraphQL errors, parse JSON responses, and return strongly "
         "typed model objects. The aws_storage.dart file centralises all S3 operations. "
         "Model classes in lib/models/ are auto-generated by Amplify Codegen from the "
         "GraphQL schema and contain fromJson / toJson serialisation logic.")

    body(doc,
         "Because Amplify DataStore was disabled (its owner-auth rules conflicted with "
         "the multi-owner booking model), the application fetches fresh data on a set of "
         "Timer.periodic callbacks with the following intervals:")

    bullet(doc, "Studio list: every 90 seconds")
    bullet(doc, "Client bookings: every 12 seconds")
    bullet(doc, "Employee bookings: every 8 seconds")
    bullet(doc, "Chat messages: every 10 seconds")
    bullet(doc, "Client notifications: every 20 seconds")
    bullet(doc, "Employee notifications: every 15 seconds")

    body(doc,
         "This polling approach trades battery efficiency for architectural simplicity "
         "and avoids the complex conflict-resolution logic required by DataStore. The "
         "intervals are calibrated so that employees see booking updates within one "
         "polling cycle, giving a near-real-time experience in practice.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.4  ONBOARDING FLOW
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.4  Onboarding Flow")

    body(doc,
         "First-time users are greeted by a five-page onboarding carousel that explains "
         "the application's core features before they reach the main interface. The "
         "onboarding is stored in SharedPreferences after the first completion; returning "
         "users skip directly to login. Each page uses a colour-coded theme (purple, "
         "green, blue, purple, orange) to visually distinguish the topics.")

    add_two_images(doc,
        "screen_09.jpg", fig[0],   "Onboarding Page 1 — Welcome screen introducing the four core pillars of GenZ Studios: multiple studio types, easy booking, real-time updates, and 24/7 support.",
        "screen_10.jpg", fig[0]+1, "Onboarding Page 2 — Browse Studios guide showing the four steps to find and evaluate a studio using the home screen gallery.")
    fig[0] += 2

    add_two_images(doc,
        "screen_11.jpg", fig[0],   "Onboarding Page 3 — Book a Studio guide explaining the four-step booking flow from tapping Book to receiving an approval notification.",
        "screen_12.jpg", fig[0]+1, "Onboarding Page 4 — Track Your Bookings guide explaining booking statuses: Pending (awaiting approval), Approved (confirmed), and Done (session complete).")
    fig[0] += 2

    add_image(doc, "screen_13.jpg", fig[0],
              "Onboarding Page 5 — Support & Help guide presenting the four support channels: Live Chat, AI Assistant, My Tickets, and the App Tour replay option.")
    fig[0] += 1

    body(doc,
         "The onboarding carousel is implemented as a PageView widget with a "
         "PageController. Dot indicators at the bottom reflect the current page, and each "
         "page's Next button advances the controller. The final page shows a 'Get Started' "
         "button that marks onboarding as complete in SharedPreferences and navigates to "
         "the authentication screen.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.5  CLIENT HOME SCREEN
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.5  Client Home Screen")

    body(doc,
         "The Home Screen is the first screen a client sees after logging in. It serves "
         "as the central hub for discovering studios and initiating bookings. The screen "
         "is composed of three main zones: a personalised welcome banner, the studio list, "
         "and a floating AI chatbot button.")

    add_image(doc, "screen_00.jpg", fig[0],
              "Client Home Screen showing the personalised welcome banner with the client's name, "
              "an Instant Book shortcut button, the 'Our Studios' header, and the first two studio "
              "cards (Studio A at $1,500/hr and Studio B at $2,500/hr) each displaying a studio "
              "photo, name, category, price badge, and a Book button. The purple AI chatbot FAB "
              "is visible at the bottom-right.")
    fig[0] += 1

    heading3(doc, "5.5.1  Welcome Banner")
    body(doc,
         "The welcome banner is a purple gradient Card that greets the authenticated user "
         "by their display name retrieved from the Cognito ID token. It contains a camera "
         "icon placeholder for a future profile photo feature, and an 'Instant Book' "
         "button that scrolls the studio list into view, saving the client from scrolling "
         "manually after a long absence. The gradient runs from a deep indigo on the left "
         "to a lighter violet on the right, reflecting the application's brand colour.")

    heading3(doc, "5.5.2  Studio Cards")
    body(doc,
         "Each studio is rendered as a rounded Card containing a full-width hero image "
         "loaded from Amazon S3, an overlaid price badge (e.g. $1,500/hr), the studio "
         "name, category tag, and a Book button. Tapping the card opens the Studio Detail "
         "Screen; tapping Book directly opens the booking date/time picker. If a studio "
         "is marked unavailable by an employee, its Book button is hidden and a "
         "'Currently Unavailable' label is shown instead.")

    heading3(doc, "5.5.3  Navigation Drawer")
    body(doc,
         "The hamburger icon in the top-left opens a side Drawer with links to: "
         "My Bookings, My Tickets, Support Chat, Notifications, Settings, and App Tour. "
         "The drawer header shows the authenticated user's name and email address. "
         "The bell icon in the top-right AppBar is a shortcut to the Notifications screen "
         "and shows a red badge when unread notifications are present.")

    heading3(doc, "5.5.4  AI Chatbot FAB")
    body(doc,
         "A purple floating action button (FAB) in the bottom-right corner launches the "
         "GENZ AI chatbot screen. The FAB uses a robot emoji icon to signal the AI "
         "nature of the assistant. It is always visible on the Home Screen so clients "
         "can get instant answers without navigating through menus.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.6  MY BOOKINGS SCREEN
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.6  My Bookings Screen")

    body(doc,
         "The My Bookings screen provides a full history of all booking requests submitted "
         "by the authenticated client. Bookings are grouped into four tabs — All, Pending, "
         "Approved, and Rejected — with badge counts that update automatically every 12 "
         "seconds via the polling timer.")

    add_two_images(doc,
        "screen_01.jpg", fig[0],   "My Bookings — All tab showing 6 total bookings: two Rejected (red border, red price), three Approved (green border, green price), and one more below the fold. Each card shows the studio name, date range, time slot or session type, and total cost.",
        "screen_02.jpg", fig[0]+1, "My Bookings — Pending tab showing an empty state with a calendar icon and 'No bookings yet' message, indicating that all current bookings have already been processed.")
    fig[0] += 2

    add_two_images(doc,
        "screen_03.jpg", fig[0],   "My Bookings — Approved tab showing four approved bookings: a Service Request for 'mmm' at $100, and three Studio A bookings at $800 each across different dates.",
        "screen_04.jpg", fig[0]+1, "My Bookings — Rejected tab showing two rejected bookings: Studio C — Podcast & Content Studio for a Full Day session at $6,400, and Studio A for a standard 8-hour block at $800.")
    fig[0] += 2

    heading3(doc, "5.6.1  Booking Card Design")
    body(doc,
         "Each booking card uses a colour-coded top bar to communicate status at a glance: "
         "green for Approved, red for Rejected, and amber for Pending. The card body "
         "shows the studio or service name, date range, time slot, and the total price. "
         "A chevron arrow on the right indicates that tapping the card opens a detail "
         "view with the full booking breakdown.")

    heading3(doc, "5.6.2  Atomic Booking Prevention")
    body(doc,
         "On the server side, the saveBookingAtomic() function uses a DynamoDB "
         "conditional write to prevent double-bookings. If two clients attempt to book "
         "the same studio for the same time slot simultaneously, only the first write "
         "succeeds; the second receives a ConditionalCheckFailedException which the "
         "application translates into a user-friendly 'This slot was just taken' message.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.7  SUPPORT TICKETS (MY TICKETS)
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.7  Support Tickets (My Tickets)")

    body(doc,
         "The My Tickets screen allows clients to submit structured support requests "
         "categorised by topic (Payment, Booking, Technical, General). Unlike the live "
         "Support Chat, tickets persist indefinitely and can be reopened if the client "
         "has a follow-up question. Each ticket shows a reply count badge, the subject, "
         "a preview of the most recent message, and the submission date.")

    add_image(doc, "screen_05.jpg", fig[0],
              "My Tickets screen listing two Payment-category tickets, each showing a '1 reply' "
              "badge in green, the ticket subject, preview text, and submission date. A purple "
              "'+ New Ticket' FAB in the bottom-right opens the ticket creation form.")
    fig[0] += 1

    body(doc,
         "Tapping a ticket opens the ticket thread, where the client can read the "
         "employee's reply and add further messages. The '+ New Ticket' FAB at the "
         "bottom-right opens a modal form where the client selects a category, enters a "
         "subject, and writes an initial message. Tickets are stored as ChatMessage "
         "records in DynamoDB with a ticketId foreign key linking all messages in a "
         "thread together.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.8  SUPPORT CHAT
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.8  Support Chat")

    body(doc,
         "The Support Chat screen provides direct real-time communication between a "
         "client and the support team. Access to live chat is controlled by the employee: "
         "when the employee disables the chat globally, clients see a locked state "
         "instructing them to open a support ticket instead. When chat is enabled, clients "
         "can exchange messages with the support team in a WhatsApp-style bubble interface.")

    add_two_images(doc,
        "screen_06.jpg", fig[0],   "Support Chat — Disabled state showing a padlock icon, the message 'Live chat disabled. Open a support ticket.', and a 'Go Back' button. This state is controlled by the employee toggle in the Employee Settings screen.",
        "screen_15.jpg", fig[0]+1, "Support Chat — Active conversation showing the client's messages (right, purple gradient bubbles) and the support team's replies (left, dark bubbles) with timestamps. The message field and send button are at the bottom.")
    fig[0] += 2

    heading3(doc, "5.8.1  Chat Architecture")
    body(doc,
         "Chat messages are stored as ChatMessage records in DynamoDB. Each record "
         "contains the sender's user ID, the message body, a timestamp, and a boolean "
         "isEmployee flag. The client polls for new messages every 10 seconds using "
         "Timer.periodic. On the employee side, the same polling interval fetches all "
         "messages across all active tickets.")

    heading3(doc, "5.8.2  Optimistic UI")
    body(doc,
         "When a client sends a message, the UI immediately appends the bubble to the "
         "conversation list (optimistic update) before the AppSync mutation completes. "
         "If the mutation fails, the bubble is removed and an error snackbar is shown. "
         "This technique eliminates the perceived delay between tapping Send and seeing "
         "the message appear, giving a responsive, native-feel experience.")

    heading3(doc, "5.8.3  Chat Enable/Disable Toggle")
    body(doc,
         "The employee can toggle the live chat on or off from the Employee Settings "
         "screen. The toggle state is stored as a boolean field in the application's "
         "configuration record in DynamoDB. Clients check this flag on every polling "
         "cycle; if it changes from enabled to disabled while a client is in the chat "
         "screen, the screen transitions automatically to the locked state without "
         "requiring the client to navigate away and back.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.9  NOTIFICATIONS
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.9  Notifications Screen")

    body(doc,
         "The Notifications screen provides a chronological log of all system events "
         "relevant to the authenticated client. Notifications are grouped by date "
         "(Today, Yesterday, and older dates) and each entry shows an icon, a title, "
         "a description, a timestamp, and a coloured status badge. A refresh button in "
         "the AppBar allows the client to force an immediate fetch.")

    add_image(doc, "screen_07.jpg", fig[0],
              "Notifications screen showing a grouped list of events: a 'Booking Rejected' "
              "notification (red icon), a 'Booking Submitted' notification (blue bell icon), a "
              "'Booking Approved' notification (green checkmark icon), a 'Request Submitted' "
              "info notification, and a 'Chat Opened' notification (purple icon), each with a "
              "read/unread double-tick indicator and a coloured status badge.")
    fig[0] += 1

    body(doc,
         "Notification types include: Booking Submitted (info), Booking Approved "
         "(success/green), Booking Rejected (error/red), Chat Opened (info/purple), "
         "and New Message (info). Each notification is stored as an AppNotification record "
         "in DynamoDB with fields for type, title, body, isRead, and createdAt. The "
         "application polls for new notifications every 20 seconds (client) or 15 seconds "
         "(employee) to keep the badge count current.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.10  CLIENT SETTINGS
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.10  Client Settings Screen")

    body(doc,
         "The Settings screen gives clients control over their language preference, "
         "visual theme, and account actions. It is accessible from the navigation drawer "
         "and is identical in structure to the Employee Settings screen, differing only "
         "in that employees have an additional 'Enable Live Chat' toggle.")

    add_image(doc, "screen_08.jpg", fig[0],
              "Client Settings screen showing three sections: Language (English selected, Arabic "
              "available as an alternative), Appearance (Dark Mode selected from System Default / "
              "Light Mode / Dark Mode options), and Account (Logout and Delete Account in red), "
              "plus a Legal section with Privacy Policy and Terms of Service links.")
    fig[0] += 1

    heading3(doc, "5.10.1  Language Switching")
    body(doc,
         "The application supports full English and Arabic localisation using Flutter's "
         "AppLocalizations system with ARB files. Switching language immediately rebuilds "
         "the entire widget tree via a locale change notification, including RTL "
         "layout mirroring for Arabic. The preference is persisted in SharedPreferences "
         "and restored on next launch.")

    heading3(doc, "5.10.2  Theme Switching")
    body(doc,
         "Three appearance modes are available: System Default (follows the device's "
         "dark/light setting), Light Mode, and Dark Mode. The application is primarily "
         "designed and tested in Dark Mode. Theme changes are applied immediately via a "
         "ThemeMode state variable held at the root MaterialApp level.")

    heading3(doc, "5.10.3  Account Management")
    body(doc,
         "Logout calls Amplify.Auth.signOut(), clears all local state, and navigates to "
         "the authentication screen. Delete Account calls the Cognito deleteUser() API "
         "after a confirmation dialog, permanently removing the user's Cognito record "
         "and all associated DynamoDB data through a cascading deletion Lambda trigger.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.11  AI CHATBOT
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.11  AI Chatbot (GENZ AI)")

    body(doc,
         "The GENZ AI screen provides clients with an intelligent conversational assistant "
         "that can answer questions about the studio, pricing, booking procedures, and "
         "availability around the clock. Unlike the human support team, the AI responds "
         "instantly with no wait time.")

    add_image(doc, "screen_14.jpg", fig[0],
              "GENZ AI chatbot screen showing the AppBar with the robot icon avatar and 'Your "
              "studio assistant' subtitle, a client message bubble ('hi') on the right in purple, "
              "and the AI's response bubble on the left: 'Hello. How can I assist you today? Are "
              "you looking to book a studio or inquire about our services?' The clear-history "
              "button (red trash icon) is in the top-right corner.")
    fig[0] += 1

    heading3(doc, "5.11.1  Technical Implementation")
    body(doc,
         "The chatbot is implemented as a Python Flask application running on an AWS EC2 "
         "instance. The Flutter client sends an HTTP POST request to "
         "http://3.239.202.67:5000/chat with a JSON body containing the user's message. "
         "The Flask server processes the message, generates a contextually relevant "
         "response about GenZ Studios' offerings, and returns a plain-text reply. The "
         "client renders the response in a dark bubble aligned to the left of the screen.")

    heading3(doc, "5.11.2  Conversation History")
    body(doc,
         "The chat history is stored in local Flutter state (a List<ChatMessage> held "
         "in the widget's State object). It persists for the duration of the session. "
         "The red trash icon in the AppBar clears the history after a confirmation "
         "prompt, starting a fresh conversation with the AI.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.12  EMPLOYEE DASHBOARD
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.12  Employee Dashboard")

    body(doc,
         "The Employee Dashboard is the operational centre of the employee interface. "
         "It provides a real-time overview of booking activity through a set of KPI "
         "cards, a time-series bookings chart, an active bookings list, and an archive "
         "of past bookings. Employees spend the majority of their working time in this "
         "screen, approving or rejecting incoming requests and monitoring revenue.")

    add_two_images(doc,
        "screen_16.jpg", fig[0],   "Employee Dashboard — Statistics section showing a Today/This Week/This Month filter bar, a date navigation control (9 Jun 2026), and six KPI cards: Total Bookings, Approved, Pending, Rejected, Revenue ($), and Hours booked. Each card has a coloured icon and an animated dot indicating live data.",
        "screen_17.jpg", fig[0]+1, "Employee Dashboard — Bookings section showing the timeline chart (hourly view, 0h–21h), the Active Bookings filter tabs (All, Pending, Approved, Rejected), an empty active state, and the Archive accordion (9 items) with the most recent rejected booking visible.")
    fig[0] += 2

    add_image(doc, "screen_18.jpg", fig[0],
              "Employee Dashboard — Archive expanded showing all nine historical booking records "
              "with client names, studio names, date/time slots, duration, and colour-coded status "
              "badges (Rejected in red, Approved in green). The filter tabs (All, Approved, "
              "Rejected, Done, Expired) allow the employee to isolate specific status groups.")
    fig[0] += 1

    heading3(doc, "5.12.1  KPI Cards")
    body(doc,
         "The six KPI cards — Total, Approved, Pending, Rejected, Revenue, and Hours — "
         "display aggregated statistics for the selected time period. Each card has a "
         "distinct colour scheme: blue for Total, green for Approved, amber for Pending, "
         "red for Rejected, green for Revenue, and blue for Hours. A small animated dot "
         "in the top-right of each card pulses to signal that the data is live.")

    heading3(doc, "5.12.2  Bookings Chart")
    body(doc,
         "The chart is a line/area chart rendered using the fl_chart Flutter package. "
         "In Today mode, the x-axis represents hours of the day (0h–21h) and each data "
         "point represents the number of bookings starting in that hour. In This Week "
         "mode, the x-axis shows days; in This Month mode, it shows weeks. The chart "
         "updates each time the polling timer fires.")

    heading3(doc, "5.12.3  Approve / Reject Bookings")
    body(doc,
         "Tapping a booking card in the Active Bookings list opens a detail modal with "
         "the client's name, contact email, studio name, requested date and time, "
         "duration, and calculated total. Two buttons — Approve (green) and Reject (red) "
         "— allow the employee to act on the request. The action calls the updateBooking "
         "GraphQL mutation, which updates the status field in DynamoDB and triggers the "
         "notification polling to deliver a status notification to the client on the next "
         "cycle.")

    heading3(doc, "5.12.4  Archive")
    body(doc,
         "The Archive accordion at the bottom of the Dashboard shows all bookings with "
         "a final status: Approved, Rejected, Done, or Expired. Bookings move to the "
         "archive automatically when their end datetime passes. The employee can filter "
         "the archive by status and tap any record to view its full detail.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.13  EMPLOYEE SUPPORT TICKETS & CHAT
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.13  Employee Support Management")

    body(doc,
         "The Support Tickets screen gives employees a unified view of all client support "
         "requests. Each ticket card shows the client's name, the most recent message "
         "preview, and a coloured status icon (green = open/active, grey = closed). "
         "Employees can open any ticket to reply, or use the three-dot menu to mark it "
         "as resolved or delete it.")

    add_two_images(doc,
        "screen_19.jpg", fig[0],   "Employee Support Tickets screen listing three tickets: 'aaa' (green icon — active, with latest message preview), 'cccc' (grey icon — closed), and 'mostafa' (grey icon — closed). The bell and refresh icons appear in the AppBar.",
        "screen_20.jpg", fig[0]+1, "Employee Support Chat thread for the client 'aaa' (mmsleep95@gmail.com) showing the full conversation: four Payment-category messages from the client on the left (dark bubbles), employee replies on the right (purple gradient bubbles), with timestamps.")
    fig[0] += 2

    body(doc,
         "The chat thread view uses the same bubble UI as the client-side Support Chat, "
         "but with the perspective flipped: the employee's messages appear on the right "
         "in purple, and the client's messages appear on the left in dark grey. The "
         "employee can type in the message field at the bottom and tap Send to dispatch "
         "a reply, which the client will see on their next polling cycle (within 10 seconds).")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.14  STUDIO MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.14  Studio Management")

    body(doc,
         "Employees manage the studio catalogue from the Studios screen, which displays "
         "all studios in a responsive two-column grid. Each card shows the studio's hero "
         "image, name, type, price per hour, and two action buttons: a pencil icon to "
         "edit and a trash icon to delete. The '+ Add Studio' FAB at the bottom-right "
         "opens the New Studio form.")

    add_two_images(doc,
        "screen_21.jpg", fig[0],   "Employee Studios grid showing six studios in two columns: Studio A ($1,500/hr), Studio B ($2,500/hr), Studio C ($800/hr), Studio D ($1,500/hr), Studio E ($2,500/hr), and Studio F ($800/hr), each with a studio photo, name, type tag, edit (pencil) and delete (trash) buttons, plus the '+ Add Studio' FAB.",
        "screen_22.jpg", fig[0]+1, "New Studio form — top section with the Studio Photos picker (0/5 slots, Add Photo button), Studio Type selector (Portrait, Product, Wedding chips), Studio Name field, Description textarea, Price per Hour and Sort # fields, and Studio Size field.")
    fig[0] += 2

    add_image(doc, "screen_23.jpg", fig[0],
              "New Studio form — bottom section showing the Equipment & Features textarea, "
              "Services (Best For) textarea, an 'Available for Booking' toggle switch (currently ON "
              "in green), and a live Preview card that shows how the studio will appear in the "
              "client's studio list before saving.")
    fig[0] += 1

    heading3(doc, "5.14.1  Studio Photos")
    body(doc,
         "Employees can attach up to five photographs per studio. Each photo is selected "
         "from the device gallery using the image_picker Flutter package, resized to a "
         "maximum of 1080 pixels on the long edge, and uploaded to Amazon S3 using the "
         "amplify_storage_s3 library. The upload progress is shown as a linear progress "
         "indicator inside the photo slot. Once uploaded, the S3 key is saved in the "
         "Studio record's photos field as a JSON array of URL strings.")

    heading3(doc, "5.14.2  Studio Types")
    body(doc,
         "Studios are classified into five types represented by coloured chip selectors "
         "in the form: Portrait (purple), Product (green), Wedding (pink), Video (blue), "
         "and Fashion (orange). The selected type determines the icon shown on the studio "
         "card in the client-facing home screen.")

    heading3(doc, "5.14.3  Availability Toggle")
    body(doc,
         "The 'Available for Booking' toggle allows an employee to temporarily disable "
         "bookings for a studio without deleting it — useful when a studio is undergoing "
         "maintenance. When disabled, the studio still appears in the client's home "
         "screen but its Book button is replaced with an 'Unavailable' label.")

    heading3(doc, "5.14.4  Live Preview")
    body(doc,
         "The bottom of the New Studio form contains a Preview card that renders "
         "exactly as the studio will appear in the client's home screen. It updates "
         "reactively as the employee fills in the form fields, giving immediate visual "
         "feedback before the studio is saved to DynamoDB.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.15  SERVICES MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.15  Services Management")

    body(doc,
         "In addition to studio-time bookings, GenZ Studios offers a catalogue of "
         "add-on services — photography packages, video production, advertising, and "
         "more. The Services screen lists all service items grouped by category. Each "
         "item shows its name, duration label, an availability toggle, an edit button, "
         "and a delete button. The '+ Add Service' FAB opens the Add Service bottom sheet.")

    add_two_images(doc,
        "screen_24.jpg", fig[0],   "Employee Services screen showing two categories: 'Photography Packages' (5 items: Basic session/hour, Standard session/3 hours, Full day shoot/8 hours, Product photography/per product, E-commerce package/per 50 products) and 'Advertising & Marketing' (4 items visible). Each item has a toggle, pencil, and trash icon.",
        "screen_25.jpg", fig[0]+1, "Add Service bottom sheet overlaid on the Services list, containing fields for Category (dropdown), Service Name (EN), Service Name (AR), Description (optional), Price (EGP), Price Label, Sort Order, and an Available toggle. An 'Add Service' submit button is at the bottom.")
    fig[0] += 2

    body(doc,
         "The Add Service form supports bilingual naming (English and Arabic) to align "
         "with the application's localisation support. The Price Label field accepts "
         "free-form units such as '/hour', '/session', or 'per product', allowing "
         "flexible pricing display in the client-facing service catalogue. The Sort Order "
         "field controls the display position within the category group.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.16  REPORTS
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.16  Reports Screen")

    body(doc,
         "The Reports screen provides a year-level financial and operational summary for "
         "the studio business. The current year is highlighted as 'Current' and shows "
         "aggregate statistics: total bookings, total revenue, and total hours booked. "
         "Beneath the year header, each month is listed with its booking count, revenue "
         "badge, and a PDF export button.")

    add_image(doc, "screen_26.jpg", fig[0],
              "Reports screen for the year 2026 showing the year header ('9 bookings · $3,300 "
              "revenue · 33.0h') with a PDF export button, followed by a month-by-month breakdown: "
              "January (No bookings), February (3 bookings, $1,600, PDF), March (1 booking, $0, "
              "PDF), April (No bookings), May (3 bookings, $1,600, PDF), June Now (2 bookings, "
              "$100, PDF). Active months have a filled blue dot; inactive months have a grey dot.")
    fig[0] += 1

    body(doc,
         "Tapping a month row expands it to show the individual bookings for that month. "
         "Tapping the PDF icon generates and downloads a formatted PDF report for the "
         "selected period using the pdf Flutter package. The report includes a header "
         "with the studio name and period, a table of all bookings with client names, "
         "studios, dates, and amounts, and a summary row with totals.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.17  EMPLOYEE SETTINGS
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.17  Employee Settings Screen")

    body(doc,
         "The Employee Settings screen mirrors the Client Settings screen but omits the "
         "'Delete Account' option and adds operational controls specific to the employee "
         "role. The most significant addition is the Live Chat enable/disable toggle "
         "that controls whether clients can access the live support chat.")

    add_image(doc, "screen_27.jpg", fig[0],
              "Employee Settings screen showing the Language section (English selected), "
              "Appearance section (Dark Mode selected), and Account section with only a Logout "
              "button (no Delete Account option). A Legal section with Privacy Policy and Terms "
              "of Service links appears at the bottom. The 'About' section is partially visible "
              "at the very bottom showing the GENZ Studios app name.")
    fig[0] += 1

    body(doc,
         "The Live Chat toggle, implemented via a GenzService Amplify record, is the "
         "primary mechanism for managing support availability. When an employee is about "
         "to go offline or the support team is busy, they can disable the chat, "
         "automatically directing all clients to open support tickets instead. The "
         "toggle state propagates to all connected clients within one polling cycle "
         "(10 seconds).")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.18  DATA MODELS & GRAPHQL SCHEMA
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.18  Data Models and GraphQL Schema")

    body(doc,
         "The application's data layer is defined by a GraphQL schema that Amplify "
         "Codegen compiles into Dart model classes and DynamoDB table configurations. "
         "The schema uses five primary @model types, each with carefully crafted @auth "
         "rules to enforce the principle of least privilege.")

    heading3(doc, "5.18.1  Studio")
    body(doc,
         "The Studio model represents a bookable studio space. Fields include: id (UUID), "
         "name (String), description (String), studioType (StudioType enum), pricePerHour "
         "(Float), photos (List<String> — S3 URLs), equipment (String), services (String), "
         "size (Float), sortOrder (Int), and isAvailable (Boolean). The @auth rule "
         "restricts write access to the Employees group while allowing any authenticated "
         "user to read.")

    heading3(doc, "5.18.2  BookingRequest")
    body(doc,
         "The BookingRequest model is the central transactional record. Key fields: "
         "id, clientId (owner), clientName, clientEmail, studioId, studioName, "
         "startDateTime, endDateTime, totalHours, totalPrice, status (BookingStatus enum: "
         "PENDING | APPROVED | REJECTED | DONE | EXPIRED), bookingType "
         "(STUDIO | SERVICE), serviceId, and serviceName. The @auth rule uses "
         "owner: clientId so that each client can only read and create their own bookings, "
         "while Employees can read and update all bookings.")

    heading3(doc, "5.18.3  AppNotification")
    body(doc,
         "AppNotification stores in-app notification records. Fields: id, userId "
         "(owner), title, body, type (NotificationType enum), isRead (Boolean), "
         "bookingId (optional FK), and createdAt. The owner-based @auth rule ensures "
         "each user sees only their own notifications.")

    heading3(doc, "5.18.4  ChatMessage")
    body(doc,
         "ChatMessage stores both support ticket messages and live chat messages. Fields: "
         "id, senderId, senderName, receiverId, body, timestamp, isEmployee (Boolean), "
         "ticketId (optional — null for live chat), ticketSubject, ticketCategory, "
         "and isRead. The @auth rule grants Employees full access and allows each client "
         "to read and create only the records where their user ID matches senderId or "
         "receiverId.")

    heading3(doc, "5.18.5  ServiceItem")
    body(doc,
         "ServiceItem stores the service catalogue entries. Fields: id, nameEn, nameAr, "
         "category, description, price (Float), priceLabel, sortOrder, and isAvailable "
         "(Boolean). Write access is restricted to Employees; all authenticated users "
         "can read the catalogue.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.19  AUTHENTICATION FLOW
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.19  Authentication and Role-Based Routing")

    body(doc,
         "Authentication is handled entirely by AWS Cognito. The flow proceeds as follows:")

    bullet(doc, "Step 1 — Sign Up: The client enters their name, email, and password. "
                "Amplify.Auth.signUp() creates the Cognito user account and sends a "
                "6-digit OTP to the provided email address.")
    bullet(doc, "Step 2 — Email Verification: The user enters the OTP on the confirmation "
                "screen. Amplify.Auth.confirmSignUp() verifies the code and marks the "
                "account as confirmed in the User Pool.")
    bullet(doc, "Step 3 — Sign In: Amplify.Auth.signIn() authenticates the user and "
                "returns the three JWTs (ID, Access, Refresh). The tokens are stored "
                "in the Android Keystore / iOS Keychain by the Amplify Auth plugin.")
    bullet(doc, "Step 4 — Role Detection: The application reads the "
                "cognito:groups claim from the ID token. If the list contains 'Employees', "
                "the app navigates to EmployeeHomeScreen; otherwise it navigates to "
                "ClientHomeScreen.")
    bullet(doc, "Step 5 — Token Refresh: The Amplify Auth plugin automatically refreshes "
                "the Access token using the Refresh token when it approaches expiry, "
                "maintaining a seamless session without requiring re-login.")

    body(doc,
         "This approach means that role assignment is fully server-side: an administrator "
         "adds a user to the 'Employees' Cognito group via the AWS Console, and the "
         "user's next login automatically grants them the employee interface. No "
         "application update is required.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.20  DESIGN SYSTEM
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.20  Design System and UI Conventions")

    body(doc,
         "The GenZ Studios application uses a consistent dark-mode design system "
         "throughout both the client and employee interfaces.")

    heading3(doc, "5.20.1  Colour Palette")
    body(doc,
         "The primary brand colour is a deep purple (#6C63FF / indigo-500), used for "
         "primary buttons, the welcome banner gradient, active tab indicators, and FABs. "
         "The background uses a near-black (#0D0D0D) surface with slightly lighter cards "
         "(#1A1A2E). Status colours follow standard conventions: green (#22C55E) for "
         "approved/success states, red (#EF4444) for rejected/error states, and amber "
         "(#F59E0B) for pending/warning states.")

    heading3(doc, "5.20.2  Typography")
    body(doc,
         "All text uses the system-default sans-serif font (Roboto on Android, SF Pro "
         "on iOS). Text sizes follow a three-tier hierarchy: screen titles at 20pt bold, "
         "section headings at 16pt bold, and body text at 14pt regular. A global "
         "TextScaler.linear.clamp(0.85, 1.2) constraint prevents the layout from "
         "breaking on devices with extreme accessibility font scale settings.")

    heading3(doc, "5.20.3  Component Library")
    body(doc,
         "Reusable components include: BookingCard (status-coloured card with booking "
         "details), StudioCard (image + name + price + Book button), NotificationTile "
         "(icon + title + body + badge), ChatBubble (sender-aware left/right alignment), "
         "and StatCard (KPI card with icon, number, and label). These components are "
         "defined in lib/screens/ alongside their parent screens rather than in a "
         "separate component library, keeping related code co-located.")

    page_break(doc)

    # ═══════════════════════════════════════════════════════════════════════════
    # 5.21  SUMMARY
    # ═══════════════════════════════════════════════════════════════════════════
    heading2(doc, "5.21  Chapter Summary")

    body(doc,
         "This chapter has presented the complete implementation of the GenZ Studios "
         "mobile application, covering every screen from the five-page onboarding "
         "carousel to the employee reports dashboard. The application demonstrates how "
         "Flutter and AWS Amplify can be combined to deliver a production-quality, "
         "cloud-backed mobile application with minimal operational overhead.")

    body(doc,
         "Key engineering achievements include:")

    bullet(doc, "Role-based navigation driven by Cognito group membership embedded in the JWT ID token, requiring no application code change when promoting a user to employee status.")
    bullet(doc, "Atomic booking writes using DynamoDB conditional expressions to prevent race conditions between concurrent booking requests for the same studio slot.")
    bullet(doc, "An optimistic UI pattern in the chat screens that eliminates perceived latency without introducing complex rollback logic.")
    bullet(doc, "A polling-based sync strategy that bypasses DataStore's owner-auth incompatibilities while maintaining near-real-time data freshness.")
    bullet(doc, "Full bilingual (English/Arabic) localisation with automatic RTL layout mirroring.")
    bullet(doc, "An integrated AI chatbot hosted on EC2 that provides domain-specific answers about studio booking.")

    body(doc,
         "The application is currently deployed and operational. Potential future "
         "enhancements include push notification delivery via Amazon SNS, in-app "
         "payment processing via Stripe, a calendar-based booking view, and a "
         "customer review and rating system for completed studio sessions.")

    # ── Save ──────────────────────────────────────────────────────────────────
    doc.save(DOCX_PATH)
    print(f"Saved: {DOCX_PATH}")
    size_kb = os.path.getsize(DOCX_PATH) // 1024
    print(f"Size:  {size_kb} KB")
    print(f"Total figures: {fig[0] - 1}")


if __name__ == "__main__":
    build()
