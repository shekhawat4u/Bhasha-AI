#!/usr/bin/env python3
"""Build a publication-style PDF from the Bhasha AI Markdown report."""

from __future__ import annotations

import html
import re
from pathlib import Path

from reportlab.graphics.shapes import Drawing, Line, Polygon, Rect, String
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    HRFlowable,
    KeepTogether,
    ListFlowable,
    ListItem,
    LongTable,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "BHASHA_AI_PROJECT_RESEARCH_REPORT.md"
OUTPUT = ROOT / "BHASHA_AI_PROJECT_RESEARCH_REPORT.pdf"

ACCENT = colors.HexColor("#C9362B")
ACCENT_DARK = colors.HexColor("#8F241D")
INK = colors.HexColor("#18212B")
MUTED = colors.HexColor("#596674")
LIGHT = colors.HexColor("#F3F5F7")
LINE_COLOR = colors.HexColor("#CCD3DA")
GREEN = colors.HexColor("#287D58")
BLUE = colors.HexColor("#2D5F91")


def register_fonts() -> None:
    base = Path("/usr/share/fonts/truetype/dejavu")
    pdfmetrics.registerFont(TTFont("Body", str(base / "DejaVuSans.ttf")))
    pdfmetrics.registerFont(TTFont("Body-Bold", str(base / "DejaVuSans-Bold.ttf")))
    pdfmetrics.registerFont(TTFont("Body-Italic", str(base / "DejaVuSans-Oblique.ttf")))
    pdfmetrics.registerFont(TTFont("Mono", str(base / "DejaVuSansMono.ttf")))
    pdfmetrics.registerFontFamily("Body", normal="Body", bold="Body-Bold", italic="Body-Italic")


register_fonts()


class ResearchDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str, **kwargs):
        super().__init__(filename, **kwargs)
        frame = Frame(
            self.leftMargin,
            self.bottomMargin,
            self.width,
            self.height,
            id="body",
            leftPadding=0,
            rightPadding=0,
            topPadding=0,
            bottomPadding=0,
        )
        self.addPageTemplates(
            [
                PageTemplate(id="cover", frames=[frame], onPage=self._cover_page),
                PageTemplate(id="body", frames=[frame], onPage=self._body_page),
            ]
        )

    def _cover_page(self, canvas, doc):
        canvas.saveState()
        canvas.setFillColor(ACCENT)
        canvas.rect(0, A4[1] - 18 * mm, A4[0], 18 * mm, fill=1, stroke=0)
        canvas.setFillColor(INK)
        canvas.rect(0, 0, A4[0], 10 * mm, fill=1, stroke=0)
        canvas.restoreState()

    def _body_page(self, canvas, doc):
        canvas.saveState()
        canvas.setStrokeColor(LINE_COLOR)
        canvas.setLineWidth(0.5)
        canvas.line(doc.leftMargin, A4[1] - 16 * mm, A4[0] - doc.rightMargin, A4[1] - 16 * mm)
        canvas.setFont("Body", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawString(doc.leftMargin, A4[1] - 12.5 * mm, "BHASHA AI  |  TECHNICAL RESEARCH REPORT")
        canvas.drawRightString(A4[0] - doc.rightMargin, 11 * mm, f"Page {canvas.getPageNumber()}")
        canvas.setStrokeColor(ACCENT)
        canvas.setLineWidth(1.2)
        canvas.line(doc.leftMargin, 15 * mm, doc.leftMargin + 18 * mm, 15 * mm)
        canvas.restoreState()

    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph):
            style = flowable.style.name
            if style in {"Heading1", "Heading2"}:
                level = 0 if style == "Heading1" else 1
                text = flowable.getPlainText()
                key = f"h{level}-{self.seq.nextf('heading')}"
                self.canv.bookmarkPage(key)
                self.canv.addOutlineEntry(text, key, level=level, closed=False)
                self.notify("TOCEntry", (level, text, self.page, key))


def make_styles():
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle(
            "CoverTitle",
            parent=base["Title"],
            fontName="Body-Bold",
            fontSize=25,
            leading=31,
            textColor=INK,
            alignment=TA_LEFT,
            spaceAfter=8 * mm,
        ),
        "cover_sub": ParagraphStyle(
            "CoverSub",
            fontName="Body",
            fontSize=11,
            leading=17,
            textColor=MUTED,
        ),
        "h1": ParagraphStyle(
            "Heading1",
            fontName="Body-Bold",
            fontSize=16,
            leading=20,
            textColor=INK,
            spaceBefore=8 * mm,
            spaceAfter=3.5 * mm,
            keepWithNext=True,
            borderWidth=0,
            borderPadding=0,
        ),
        "h2": ParagraphStyle(
            "Heading2",
            fontName="Body-Bold",
            fontSize=12,
            leading=15,
            textColor=ACCENT_DARK,
            spaceBefore=5 * mm,
            spaceAfter=2.5 * mm,
            keepWithNext=True,
        ),
        "body": ParagraphStyle(
            "BodyText",
            fontName="Body",
            fontSize=9.2,
            leading=13.5,
            textColor=INK,
            alignment=TA_JUSTIFY,
            spaceAfter=2.5 * mm,
            allowWidows=0,
            allowOrphans=0,
        ),
        "small": ParagraphStyle(
            "Small",
            fontName="Body",
            fontSize=7.2,
            leading=9.2,
            textColor=INK,
        ),
        "caption": ParagraphStyle(
            "Caption",
            fontName="Body-Italic",
            fontSize=7.5,
            leading=10,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=3 * mm,
        ),
        "code": ParagraphStyle(
            "Code",
            fontName="Mono",
            fontSize=6.7,
            leading=9,
            textColor=INK,
            leftIndent=3 * mm,
            rightIndent=3 * mm,
            borderColor=LINE_COLOR,
            borderWidth=0.5,
            borderPadding=4,
            backColor=LIGHT,
            spaceBefore=2 * mm,
            spaceAfter=3 * mm,
        ),
        "keyword": ParagraphStyle(
            "Keyword",
            fontName="Body",
            fontSize=8.5,
            leading=12,
            textColor=INK,
            backColor=colors.HexColor("#FCEDEB"),
            borderColor=colors.HexColor("#E8B8B3"),
            borderWidth=0.5,
            borderPadding=7,
            spaceBefore=2 * mm,
            spaceAfter=4 * mm,
        ),
    }


STYLES = make_styles()


def inline_markup(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r'<font name="Mono" size="7.8">\1</font>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    return text


def paragraph(text: str, style="body"):
    return Paragraph(inline_markup(text), STYLES[style])


def arrow(d: Drawing, x1, y1, x2, y2, color=BLUE):
    d.add(Line(x1, y1, x2, y2, strokeColor=color, strokeWidth=1.1))
    dx, dy = x2 - x1, y2 - y1
    length = max((dx * dx + dy * dy) ** 0.5, 1)
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    size = 4
    d.add(
        Polygon(
            [
                x2,
                y2,
                x2 - ux * size + px * size * 0.55,
                y2 - uy * size + py * size * 0.55,
                x2 - ux * size - px * size * 0.55,
                y2 - uy * size - py * size * 0.55,
            ],
            fillColor=color,
            strokeColor=color,
        )
    )


def box(d: Drawing, x, y, w, h, label, fill=LIGHT, stroke=LINE_COLOR, size=7.2):
    d.add(Rect(x, y, w, h, rx=5, ry=5, fillColor=fill, strokeColor=stroke, strokeWidth=0.8))
    words = label.split()
    lines, line = [], ""
    limit = max(int(w / (size * 0.55)), 8)
    for word in words:
        candidate = (line + " " + word).strip()
        if len(candidate) > limit and line:
            lines.append(line)
            line = word
        else:
            line = candidate
    if line:
        lines.append(line)
    start = y + h / 2 + (len(lines) - 1) * size * 0.55
    for i, txt in enumerate(lines[:4]):
        d.add(
            String(
                x + w / 2,
                start - i * size * 1.2,
                txt,
                fontName="Body-Bold" if i == 0 else "Body",
                fontSize=size,
                fillColor=INK,
                textAnchor="middle",
            )
        )


def diagram(index: int) -> Drawing:
    display_w = 165 * mm
    display_h = 72 * mm
    logical_w = 570
    logical_h = 250
    d = Drawing(logical_w, logical_h)
    d.add(Rect(0, 0, logical_w, logical_h, fillColor=colors.white, strokeColor=LINE_COLOR, strokeWidth=0.6, rx=6, ry=6))

    if index == 0:
        labels = ["Operator", "Flutter Client", "FastAPI GPU Engine", "Audio Conditioning", "SenseVoiceSmall", "Opus-MT zh-en", "Structured Results"]
        xs = [7, 73, 150, 238, 326, 405, 480]
        widths = [55, 66, 76, 76, 70, 65, 75]
        y = 118
        for i, (label, x, bw) in enumerate(zip(labels, xs, widths)):
            box(d, x, y, bw, 40, label, fill=colors.HexColor("#F8FAFC") if i not in (1, 2) else colors.HexColor("#FCEDEB"))
            if i:
                arrow(d, xs[i - 1] + widths[i - 1], y + 20, x, y + 20)
        box(d, 290, 38, 90, 40, "Faster-Whisper fallback", fill=colors.HexColor("#EEF5FB"))
        arrow(d, 276, 118, 320, 78)
        arrow(d, 380, 58, 437, 118)
        box(d, 140, 38, 90, 40, "FFmpeg video path", fill=colors.HexColor("#EEF5FB"))
        arrow(d, 111, 118, 170, 78)
        arrow(d, 230, 58, 276, 118)
    elif index == 1:
        labels = ["Flutter device", "Local workstation\nport 8000", "SSH tunnel", "Remote GPU host", "FastAPI and models"]
        xs = [20, 125, 235, 335, 435]
        for i, (label, x) in enumerate(zip(labels, xs)):
            box(d, x, 103, 85, 48, label, fill=colors.HexColor("#FCEDEB") if i == 0 else LIGHT)
            if i:
                arrow(d, xs[i - 1] + 85, 127, x, 127)
        box(d, 435, 35, 85, 38, "Temporary MP4 store", fill=colors.HexColor("#EEF5FB"))
        arrow(d, 477, 103, 477, 73)
    elif index == 2:
        labels = ["Upload", "16 kHz mono", "Peak normalize", "VAD split", "SenseVoice ASR", "Clean text", "Opus-MT", "API result"]
        xs = [10, 75, 145, 218, 288, 365, 433, 500]
        widths = [52, 58, 62, 58, 65, 56, 55, 55]
        y = 122
        for i, (label, x, bw) in enumerate(zip(labels, xs, widths)):
            box(d, x, y, bw, 38, label, fill=colors.HexColor("#F8FAFC"))
            if i:
                arrow(d, xs[i - 1] + widths[i - 1], y + 19, x, y + 19)
        box(d, 305, 43, 95, 40, "No transcript? Whisper fallback", fill=colors.HexColor("#EEF5FB"))
        arrow(d, 320, 122, 345, 83)
        arrow(d, 400, 63, 433, 122)
        d.add(String(20, 20, "Shorter than 250 ms: discard as likely click or noise", fontName="Body-Italic", fontSize=7.2, fillColor=MUTED))
    elif index == 3:
        actors = ["Flutter", "FastAPI", "FFmpeg", "Speech AI", "MP4 store"]
        xs = [65, 165, 270, 380, 490]
        for name, x in zip(actors, xs):
            box(d, x - 35, 170, 70, 28, name, fill=colors.HexColor("#FCEDEB"))
            d.add(Line(x, 20, x, 170, strokeColor=LINE_COLOR, strokeWidth=0.7))
        events = [
            (0, 1, 148, "POST video"),
            (1, 2, 124, "transcode and extract"),
            (2, 4, 100, "save MP4"),
            (2, 3, 76, "16 kHz WAV"),
            (3, 1, 52, "transcript and subtitles"),
            (1, 0, 28, "JSON and stream URL"),
        ]
        for a, b, y, label in events:
            arrow(d, xs[a], y, xs[b], y, ACCENT if a == 1 or b == 1 else BLUE)
            d.add(String((xs[a] + xs[b]) / 2, y + 4, label, fontName="Body", fontSize=6.5, fillColor=INK, textAnchor="middle"))
    elif index == 4:
        box(d, 235, 170, 90, 32, "Home", fill=colors.HexColor("#FCEDEB"), stroke=ACCENT)
        labels = ["Live Listening", "Audio", "Documents", "Video", "Audio Intel", "Broadcast RF", "Voice Auth", "Threat Scan", "Evidence Vault", "Settings"]
        cols = 5
        for i, label in enumerate(labels):
            row, col = divmod(i, cols)
            x = 18 + col * 108
            y = 105 - row * 67
            box(d, x, y, 88, 34, label, fill=colors.HexColor("#F8FAFC"))
            arrow(d, 280, 170, x + 44, y + 34)
    else:
        top = ["Authenticated Client", "TLS Gateway", "Validated Ingestion", "Model Router"]
        xs = [15, 145, 275, 410]
        for i, (label, x) in enumerate(zip(top, xs)):
            box(d, x, 168, 105, 35, label, fill=colors.HexColor("#FCEDEB") if i < 2 else LIGHT)
            if i:
                arrow(d, xs[i - 1] + 105, 185, x, 185)
        workers = ["Mandarin ASR", "Indic ASR", "Fallback ASR", "Translation", "Entity Validator"]
        for i, label in enumerate(workers):
            x = 28 + i * 105
            box(d, x, 99, 82, 34, label, fill=colors.HexColor("#EEF5FB"))
            if i < 3:
                arrow(d, 462, 168, x + 41, 133)
            elif i == 3:
                for j in range(3):
                    arrow(d, 69 + j * 105, 99, x, 116)
            else:
                arrow(d, 425, 99, x, 116)
        box(d, 160, 25, 110, 35, "Result Store", fill=colors.HexColor("#EEF7F1"), stroke=GREEN)
        box(d, 330, 25, 130, 35, "Audit and Provenance", fill=colors.HexColor("#EEF7F1"), stroke=GREEN)
        arrow(d, 489, 99, 270, 60, GREEN)
        arrow(d, 270, 42, 330, 42, GREEN)

    # Diagrams use a convenient logical coordinate system, then scale to the
    # report's printable width so every node remains inside the page frame.
    d.scale(display_w / logical_w, display_h / logical_h)
    d.width = display_w
    d.height = display_h
    return d


FIGURE_CAPTIONS = [
    "Figure 1. Logical architecture of the implemented translation path.",
    "Figure 2. Current SSH-tunneled physical deployment.",
    "Figure 3. Audio conditioning, recognition, and translation pipeline.",
    "Figure 4. Video processing and streaming sequence.",
    "Figure 5. Flutter navigation and functional modules.",
    "Figure 6. Recommended production architecture.",
]


def make_table(rows):
    count = max(len(r) for r in rows)
    width = 165 * mm
    if count == 2:
        widths = [0.31 * width, 0.69 * width]
    elif count == 3:
        widths = [0.25 * width, 0.38 * width, 0.37 * width]
    elif count == 4:
        widths = [0.27 * width, 0.22 * width, 0.22 * width, 0.29 * width]
    else:
        widths = [width / count] * count
    pdata = []
    for ridx, row in enumerate(rows):
        cells = []
        for cell in row:
            st = ParagraphStyle(
                f"table-{ridx}",
                parent=STYLES["small"],
                fontName="Body-Bold" if ridx == 0 else "Body",
                textColor=colors.white if ridx == 0 else INK,
                leading=9,
            )
            cells.append(Paragraph(inline_markup(cell), st))
        cells.extend([Paragraph("", STYLES["small"])] * (count - len(cells)))
        pdata.append(cells)
    table = LongTable(pdata, colWidths=widths, repeatRows=1, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), ACCENT_DARK),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.35, LINE_COLOR),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return table


def parse_markdown(text: str):
    lines = text.splitlines()
    story = []
    figure_index = 0
    i = 0
    para_lines = []
    list_items = []
    list_kind = None

    def flush_para():
        nonlocal para_lines
        if para_lines:
            joined = " ".join(x.strip() for x in para_lines).strip()
            if joined:
                style = "keyword" if joined.startswith("**Keywords:**") else "body"
                story.append(paragraph(joined, style))
            para_lines = []

    def flush_list():
        nonlocal list_items, list_kind
        if list_items:
            items = [ListItem(paragraph(item), leftIndent=6) for item in list_items]
            options = {
                "bulletType": "1" if list_kind == "number" else "bullet",
                "leftIndent": 15,
                "bulletFontName": "Body-Bold",
                "bulletFontSize": 8,
                "spaceAfter": 2.5 * mm,
            }
            if list_kind == "number":
                options["start"] = "1"
            story.append(ListFlowable(items, **options))
            list_items = []
            list_kind = None

    while i < len(lines):
        line = lines[i]
        if line.startswith("# "):
            i += 1
            continue
        if line.startswith("## "):
            flush_para(); flush_list()
            story.append(Paragraph(inline_markup(line[3:]), STYLES["h1"]))
            i += 1
            continue
        if line.startswith("### "):
            flush_para(); flush_list()
            story.append(Paragraph(inline_markup(line[4:]), STYLES["h2"]))
            i += 1
            continue
        if line.startswith("```"):
            flush_para(); flush_list()
            lang = line[3:].strip()
            code = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1
            if lang == "mermaid":
                story.append(KeepTogether([diagram(figure_index), Paragraph(FIGURE_CAPTIONS[figure_index], STYLES["caption"])]))
                figure_index += 1
            else:
                story.append(Preformatted("\n".join(code), STYLES["code"], maxLineLength=110))
            continue
        if line.startswith("|") and i + 1 < len(lines) and lines[i + 1].startswith("|"):
            flush_para(); flush_list()
            table_lines = []
            while i < len(lines) and lines[i].startswith("|"):
                table_lines.append(lines[i])
                i += 1
            parsed = []
            for tidx, table_line in enumerate(table_lines):
                cells = [c.strip() for c in table_line.strip().strip("|").split("|")]
                if tidx == 1 and all(re.fullmatch(r":?-{3,}:?", c) for c in cells):
                    continue
                parsed.append(cells)
            story.extend([Spacer(1, 1.5 * mm), make_table(parsed), Spacer(1, 3 * mm)])
            continue
        bullet = re.match(r"^-\s+(.*)", line)
        numbered = re.match(r"^\d+\.\s+(.*)", line)
        if bullet or numbered:
            flush_para()
            kind = "number" if numbered else "bullet"
            if list_kind and list_kind != kind:
                flush_list()
            list_kind = kind
            list_items.append((numbered or bullet).group(1))
            i += 1
            continue
        if line.strip() == "":
            flush_para(); flush_list()
            i += 1
            continue
        para_lines.append(line)
        i += 1

    flush_para(); flush_list()
    return story


def build_pdf():
    text = SOURCE.read_text(encoding="utf-8")
    title = text.splitlines()[0].removeprefix("# ")

    doc = ResearchDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        leftMargin=22 * mm,
        rightMargin=22 * mm,
        topMargin=22 * mm,
        bottomMargin=20 * mm,
        title=title,
        author="Bhasha AI Project",
        subject="Architecture, model inventory, implementation assessment, and evaluation",
    )

    story = [
        Spacer(1, 32 * mm),
        Paragraph("TECHNICAL RESEARCH REPORT", ParagraphStyle("eyebrow", fontName="Body-Bold", fontSize=10, textColor=ACCENT, leading=13, spaceAfter=5 * mm)),
        Paragraph(inline_markup(title), STYLES["cover_title"]),
        HRFlowable(width="34%", thickness=2, color=ACCENT, hAlign="LEFT", spaceAfter=8 * mm),
        Paragraph("A repository-grounded study of multimodal speech translation, model architecture, frontend and backend integration, benchmark evidence, and the path to production deployment.", STYLES["cover_sub"]),
        Spacer(1, 38 * mm),
        make_table(
            [
                ["Report field", "Value"],
                ["Assessment date", "7 October 2026"],
                ["Application", "Flutter 1.0.0+1"],
                ["Backend", "FastAPI GPU Engine 3.0.0"],
                ["Primary runtime models", "SenseVoiceSmall, Opus-MT zh-en, Faster-Whisper Large-v3"],
                ["Evaluation corpus", "50 operational Mandarin radio recordings"],
            ]
        ),
        Spacer(1, 7 * mm),
        Paragraph("Prepared from the complete checked-in source tree, datasets, benchmark outputs, architecture specifications, and automated verification results.", STYLES["caption"]),
        NextPageTemplate("body"),
        PageBreak(),
        Paragraph("Contents", STYLES["h1"]),
    ]

    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle("TOC1", fontName="Body-Bold", fontSize=9, leading=13, leftIndent=0, firstLineIndent=0, textColor=INK, spaceBefore=2),
        ParagraphStyle("TOC2", fontName="Body", fontSize=8, leading=11, leftIndent=14, firstLineIndent=0, textColor=MUTED),
    ]
    story.extend([toc, PageBreak()])

    body_lines = text.splitlines()[1:]
    while body_lines and (not body_lines[0].strip() or body_lines[0].startswith("**Project technical") or body_lines[0].startswith("**Repository assessment") or body_lines[0].startswith("**System version")):
        body_lines.pop(0)
    story.extend(parse_markdown("\n".join(body_lines)))
    doc.multiBuild(story)


if __name__ == "__main__":
    build_pdf()
    print(OUTPUT)
