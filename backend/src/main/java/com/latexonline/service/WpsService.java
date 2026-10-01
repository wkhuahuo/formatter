package com.latexonline.service;

import com.latexonline.util.TextUtils;
import org.apache.poi.xwpf.usermodel.*;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.*;
import org.springframework.stereotype.Service;

import java.io.*;
import java.math.BigInteger;

@Service
public class WpsService {

    // --- GB/T 9704-2012 page constants ---
    private static final double CM_TO_TWIPS = 567.0;
    private static final double DEFAULT_BOTTOM_CM = 3.5;
    private static final double MIN_BOTTOM_CM = 2.0;
    private static final double TOP_CM_RED = 4.5;
    private static final double TOP_CM_NO_RED = 3.7;
    private static final double LEFT_CM = 2.8;
    private static final double RIGHT_CM = 2.6;
    private static final double HEADER_FROM_TOP_CM = 1.5;
    private static final double FOOTER_FROM_BOTTOM_CM = 1.75;

    // --- font sizes (pt) ---
    private static final double RED_HEADER_SIZE = 36;
    private static final double DOC_NUMBER_SIZE = 16;
    private static final double TITLE_SIZE = 16;   // 三号
    private static final double BODY_SIZE = 16;
    private static final double BANJI_SIZE = 14;

    // --- line / paragraph spacing (pt unless noted) ---
    private static final double BODY_LINE_HEIGHT = 28.0;   // 1.5x at 16pt
    private static final double BODY_PARAGRAPH_GAP = 4.0;  // \parskip base
    private static final double BODY_LINE_SHRINK = 3.0;    // minus 3pt
    private static final double CLOSING_LEADING_SPACE_CM = 3.0;   // vspace before closing
    private static final double CLOSING_LEADING_SHRINK_CM = 2.5;  // minus 2.5cm
    private static final double CLOSING_SAFETY_PT = 14.0;  // margin above closing block

    // orphan threshold: 2 body lines ≈ 1.97 cm
    private static final double TWO_LINES_CM = 2 * 28 * 0.03514598;

    // --- colors ---
    private static final String CHINA_RED = "FF0000";   // 正红色

    // --- 字体族名（写进 docx，实际字形取决于打开文档的环境）---
    // 前端 frontend/src/styles/fonts.css 用同名 @font-face 把这些族名映射到工程字体库，
    // 因此换字体只需换字体文件 / 改那一份 CSS，后端无需改动。
    private static final String FONT_SONG = "宋体";        // 红头、文档标题
    private static final String FONT_FANGSONG = "仿宋";    // 正文、主送机关、附注、抄送、印发
    private static final String FONT_HEI = "黑体";         // 正文一级标题 一、
    private static final String FONT_KAI = "楷体";         // 正文二级标题 （一）

    public byte[] generate(
            String redHeader, String documentNumber,
            String title, String recipient, String body,
            String organization, String date,
            String note, String cc, String printUnit, String printDate, String printCopies
    ) throws Exception {

        boolean hasRedHeader = TextUtils.isSet(redHeader);

        // Pass 1
        byte[] docxBytes = buildDocument(
                redHeader, documentNumber, title, recipient, body,
                organization, date, note, cc, printUnit, printDate,
                hasRedHeader, DEFAULT_BOTTOM_CM, false
        );

        double deficitCm = estimateDeficit(body, organization, date, note, cc, printUnit, printDate, hasRedHeader);

        // Pass 2
        if (deficitCm > 0 && deficitCm <= TWO_LINES_CM) {
            double newBottom = DEFAULT_BOTTOM_CM - deficitCm;
            if (newBottom >= MIN_BOTTOM_CM) {
                byte[] adjusted = buildDocument(
                        redHeader, documentNumber, title, recipient, body,
                        organization, date, note, cc, printUnit, printDate,
                        hasRedHeader, newBottom, true
                );
                if (adjusted != null) return adjusted;
            }
        }

        return docxBytes;
    }

    // ═══════════════════════════════════════════════════════════
    //  Document builder
    // ═══════════════════════════════════════════════════════════

    private byte[] buildDocument(
            String redHeader, String documentNumber,
            String title, String recipient, String body,
            String organization, String date,
            String note, String cc, String printUnit, String printDate,
            boolean hasRedHeader, double bottomCm, boolean compress
    ) throws Exception {

        try (XWPFDocument doc = new XWPFDocument()) {

            // --- page setup: always 37mm top margin ---
            setPageMargins(doc, 3.7, bottomCm,
                    LEFT_CM, RIGHT_CM, HEADER_FROM_TOP_CM, FOOTER_FROM_BOTTOM_CM);

            // --- red header in body (not page header) ---
            if (hasRedHeader) {
                addRedHeaderInBody(doc, redHeader, documentNumber);
            }

            // --- title ---
            if (TextUtils.isSet(title)) {
                addTitle(doc, title);
            }

            // --- 主送机关 (title下空一行，居左顶格) ---
            if (TextUtils.isSet(recipient)) {
                XWPFParagraph rp = doc.createParagraph();
                rp.setAlignment(ParagraphAlignment.LEFT);
                rp.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
                rp.setSpacingBefore(0);
                rp.setSpacingAfter(0);
                rp.setIndentationFirstLine(0);
                XWPFRun rr = rp.createRun();
                rr.setText(recipient);
                rr.setFontSize(BODY_SIZE);
                setEastAsianFont(rr, FONT_FANGSONG);
            }

            // --- body ---
            java.util.List<XWPFParagraph> bodyParagraphs = null;
            if (TextUtils.isSet(body)) {
                bodyParagraphs = addBody(doc, body, compress);
            }

            // --- closing block ---
            boolean hasOrg = TextUtils.isSet(organization);
            boolean hasDate = TextUtils.isSet(date);
            boolean hasNote = TextUtils.isSet(note);
            boolean hasCc = TextUtils.isSet(cc);
            boolean hasPrintUnit = TextUtils.isSet(printUnit);
            boolean hasLuokuan = hasOrg || hasDate;
            boolean hasBanji = hasCc || hasPrintUnit;
            boolean hasClosing = hasLuokuan || hasNote || hasBanji;

            XWPFParagraph lastBodyPara = (bodyParagraphs != null && !bodyParagraphs.isEmpty())
                    ? bodyParagraphs.get(bodyParagraphs.size() - 1) : null;

            if (hasClosing) {
                // Estimate content to calculate elastic spacing
                int bodyH = estimateBodyHeight(body);
                int luokuanH = hasLuokuan ? estimateLuokuanHeight(organization, date) : 0;
                int noteH = hasNote ? ptToTwips(BODY_LINE_HEIGHT) : 0;
                int banjiH = hasBanji ? estimateBanjiHeight(hasCc, TextUtils.isSet(printUnit)) : 0;

                // Page content height in twips (A4 29.7cm - top 3.7cm - bottom DEFAULT)
                int pageH = (int)((29.7 - 3.7 - DEFAULT_BOTTOM_CM) * CM_TO_TWIPS);

                // Estimate space used by title + redHeader + recipient (rough)
                int headerOverhead = ptToTwips(28 + 14 + 28 + 28); // title spacing + recipient

                int usedSoFar = headerOverhead + bodyH;
                int pagesUsed = (int)Math.ceil((double)usedSoFar / pageH);
                int usedOnLastPage = usedSoFar - (pagesUsed - 1) * pageH;
                if (usedOnLastPage <= 0) usedOnLastPage = bodyH;

                int remaining = pageH - usedOnLastPage;
                int banjiNeed = banjiH + ptToTwips(4); // small margin
                int totalClosingNeed = luokuanH + noteH + banjiNeed;

                // Distribute remaining space: luokuan in middle, banji at bottom
                int spacerBeforeLuokuan = Math.max(0, (remaining - totalClosingNeed) / 2);
                int spacerBeforeBanji = remaining - spacerBeforeLuokuan - luokuanH - noteH - banjiNeed;
                if (spacerBeforeBanji < 0) spacerBeforeBanji = 0;

                if (lastBodyPara != null) {
                    lastBodyPara.setKeepNext(true);
                }

                // Spacer before 落款
                XWPFParagraph sp1 = doc.createParagraph();
                sp1.setSpacingBefore(spacerBeforeLuokuan);
                sp1.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);

                java.util.List<XWPFParagraph> closingParas = new java.util.ArrayList<>();
                if (hasLuokuan) {
                    closingParas.addAll(addLuokuan(doc, organization, date, compress));
                }
                if (hasNote) {
                    closingParas.add(addNote(doc, note, compress));
                }
                if (hasBanji) {
                    // Push banji to page bottom
                    XWPFParagraph sp2 = doc.createParagraph();
                    sp2.setSpacingBefore(spacerBeforeBanji);
                    sp2.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
                    closingParas.add(sp2);
                    closingParas.addAll(addBanji(doc, cc, printUnit, printDate, hasCc, hasLuokuan || hasNote, compress));
                }

                for (int i = 0; i < closingParas.size(); i++) {
                    XWPFParagraph cp = closingParas.get(i);
                    cp.setKeepNext(i < closingParas.size() - 1);
                    setKeepLines(cp, true);
                }
            }

            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            doc.write(bos);
            return bos.toByteArray();
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  Page setup
    // ═══════════════════════════════════════════════════════════

    private void setPageMargins(XWPFDocument doc, double topCm, double bottomCm,
                                 double leftCm, double rightCm,
                                 double headerCm, double footerCm) {
        CTSectPr sectPr = doc.getDocument().getBody().isSetSectPr()
                ? doc.getDocument().getBody().getSectPr()
                : doc.getDocument().getBody().addNewSectPr();

        CTPageMar pageMar = sectPr.isSetPgMar() ? sectPr.getPgMar() : sectPr.addNewPgMar();

        pageMar.setTop(BigInteger.valueOf((long)(topCm * CM_TO_TWIPS)));
        pageMar.setBottom(BigInteger.valueOf((long)(bottomCm * CM_TO_TWIPS)));
        pageMar.setLeft(BigInteger.valueOf((long)(leftCm * CM_TO_TWIPS)));
        pageMar.setRight(BigInteger.valueOf((long)(rightCm * CM_TO_TWIPS)));
        pageMar.setHeader(BigInteger.valueOf((long)(headerCm * CM_TO_TWIPS)));
        pageMar.setFooter(BigInteger.valueOf((long)(footerCm * CM_TO_TWIPS)));

        // A4 paper size
        CTPageSz pageSz = sectPr.isSetPgSz() ? sectPr.getPgSz() : sectPr.addNewPgSz();
        pageSz.setW(BigInteger.valueOf((long)(21.0 * CM_TO_TWIPS)));
        pageSz.setH(BigInteger.valueOf((long)(29.7 * CM_TO_TWIPS)));
    }

    // ═══════════════════════════════════════════════════════════
    //  Red header — in body, not page header
    // ═══════════════════════════════════════════════════════════

    private void addRedHeaderInBody(XWPFDocument doc, String redHeader, String documentNumber) {
        int negIndent = -cmToTwips(2.0);

        XWPFParagraph p1 = doc.createParagraph();
        p1.setAlignment(ParagraphAlignment.CENTER);
        p1.setIndentationLeft(negIndent);
        p1.setIndentationRight(negIndent);
        // 要求：红头单倍行距（显式声明，不依赖文档默认值）
        p1.setSpacingBetween(1.0, LineSpacingRule.AUTO);
        p1.setSpacingBefore(0);
        p1.setSpacingAfter(0);
        XWPFRun r1 = p1.createRun();
        r1.setText(redHeader);
        r1.setFontSize(RED_HEADER_SIZE);
        r1.setColor(CHINA_RED);
        setEastAsianFont(r1, FONT_SONG);
        r1.setBold(false);

        // 发文字号 — 仿宋3号，与发文机关标志空二行
        if (TextUtils.isSet(documentNumber)) {
            // 空一行（按3号字体）
            XWPFParagraph sp = doc.createParagraph();
            sp.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
            sp.setSpacingBefore(0);
            sp.setSpacingAfter(0);
            XWPFRun sr = sp.createRun();
            sr.setFontSize(DOC_NUMBER_SIZE);
            setEastAsianFont(sr, FONT_FANGSONG);

            XWPFParagraph p2 = doc.createParagraph();
            p2.setAlignment(ParagraphAlignment.CENTER);
            p2.setIndentationLeft(0);
            p2.setIndentationRight(0);
            p2.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
            p2.setSpacingBefore(0);
            p2.setSpacingAfter(0);
            XWPFRun r2 = p2.createRun();
            r2.setText(documentNumber);
            r2.setFontSize(DOC_NUMBER_SIZE);
            setEastAsianFont(r2, FONT_FANGSONG);

            // 红色分隔线 —— 直接作为发文字号段的“下框线”（12/8 pt = 1.5磅），
            // 随该段 -2cm 的左右缩进一起向两侧延伸出版心。
            setParagraphBottomBorder(p2, CHINA_RED, 12, 6);
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  Title
    // ═══════════════════════════════════════════════════════════

    private void addTitle(XWPFDocument doc, String title) {
        // 段前1行(28pt)，段后0.5行(14pt)
        XWPFParagraph p = doc.createParagraph();
        p.setAlignment(ParagraphAlignment.CENTER);
        p.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
        p.setSpacingBefore(ptToTwips(28));
        p.setSpacingAfter(ptToTwips(14));

        XWPFRun r = p.createRun();
        r.setText(title);
        r.setFontSize(TITLE_SIZE);
        r.setBold(false);
        setEastAsianFont(r, FONT_SONG);
    }

    // ═══════════════════════════════════════════════════════════
    //  Body
    // ═══════════════════════════════════════════════════════════

    private java.util.List<XWPFParagraph> addBody(XWPFDocument doc, String body, boolean compress) {
        java.util.List<XWPFParagraph> paragraphs = new java.util.ArrayList<>();
        String[] rawParas = body.split("\n");

        double lineHt = compress ? BODY_LINE_HEIGHT - BODY_LINE_SHRINK : BODY_LINE_HEIGHT;

        for (String raw : rawParas) {
            String text = raw.trim();
            if (text.isEmpty()) {
                XWPFParagraph blank = doc.createParagraph();
                blank.setSpacingBetween(lineHt, LineSpacingRule.EXACT);
                blank.setSpacingBefore(0);
                blank.setSpacingAfter(0);
                paragraphs.add(blank);
                continue;
            }

            int level = classifyHeading(text);
            String fontFamily;
            boolean isBold = false;
            boolean isHeading = level > 0;

            String display = text;
            if (level == 1) {
                fontFamily = FONT_HEI;
                if (text.startsWith("# ")) display = text.substring(2);
            } else if (level == 2) {
                fontFamily = FONT_KAI;
                if (text.startsWith("## ")) display = text.substring(3);
            } else if (level == 3 || level == 4) {
                fontFamily = FONT_FANGSONG;
                if (text.startsWith("### ")) display = text.substring(4);
            } else {
                fontFamily = FONT_FANGSONG;
            }

            XWPFParagraph p = doc.createParagraph();
            p.setAlignment(isHeading ? ParagraphAlignment.LEFT : ParagraphAlignment.BOTH);
            p.setSpacingBetween(lineHt, LineSpacingRule.EXACT);
            p.setSpacingBefore(0);
            p.setSpacingAfter(0);
            p.setIndentationFirstLine(ptToTwips(BODY_SIZE * 2));

            XWPFRun r = p.createRun();
            r.setText(display);
            r.setFontSize(BODY_SIZE);
            r.setBold(isBold);
            setEastAsianFont(r, fontFamily);

            paragraphs.add(p);
        }
        return paragraphs;
    }

    // ═══════════════════════════════════════════════════════════
    //  Luokuan (落款) — right-aligned unit + date
    // ═══════════════════════════════════════════════════════════

    private java.util.List<XWPFParagraph> addLuokuan(XWPFDocument doc, String organization,
                                                       String date, boolean compress) {
        java.util.List<XWPFParagraph> paras = new java.util.ArrayList<>();
        int luokuanGap = compress ? 0 : ptToTwips(6);

        if (TextUtils.isSet(organization)) {
            XWPFParagraph p = doc.createParagraph();
            p.setAlignment(ParagraphAlignment.RIGHT);
            p.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
            XWPFRun r = p.createRun();
            r.setText(organization);
            r.setFontSize(BODY_SIZE);
            setEastAsianFont(r, FONT_FANGSONG);
            p.setSpacingAfter(luokuanGap);
            paras.add(p);
        }

        if (TextUtils.isSet(date)) {
            XWPFParagraph p = doc.createParagraph();
            p.setAlignment(ParagraphAlignment.RIGHT);
            p.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
            // 日期居中于落款单位下方：用右缩进精确控制，避免空格宽度不准
            if (TextUtils.isSet(organization)) {
                int orgWidthTwips = visualWidthTwips(organization);
                int dateWidthTwips = visualWidthTwips(date);
                if (orgWidthTwips > dateWidthTwips) {
                    p.setIndentationRight((orgWidthTwips - dateWidthTwips) / 2);
                }
            }
            XWPFRun r = p.createRun();
            r.setText(date);
            r.setFontSize(BODY_SIZE);
            setEastAsianFont(r, FONT_FANGSONG);
            paras.add(p);
        }

        return paras;
    }

    private int visualLength(String s) {
        return TextUtils.visualLength(s);
    }

    /** 将 visualLength 单位转换为 twips（基于正文字号 BODY_SIZE 16pt）。
     *  visualLength: CJK=2 单位, ASCII=1 单位。1 单位 ≈ 半角宽 ≈ 8pt ≈ 160 twips。 */
    private int visualWidthTwips(String s) {
        return visualLength(s) * ptToTwips(BODY_SIZE) / 2;
    }

    // ═══════════════════════════════════════════════════════════
    //  Note (附注)
    // ═══════════════════════════════════════════════════════════

    private XWPFParagraph addNote(XWPFDocument doc, String note, boolean compress) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingBetween(BODY_LINE_HEIGHT, LineSpacingRule.EXACT);
        p.setSpacingBefore(compress ? 0 : ptToTwips(6));
        XWPFRun r = p.createRun();
        r.setText("（" + note + "）");
        r.setFontSize(BODY_SIZE);
        setEastAsianFont(r, FONT_FANGSONG);
        p.setIndentationFirstLine(ptToTwips(BODY_SIZE * 2));
        return p;
    }

    // ═══════════════════════════════════════════════════════════
    //  Banji (版记) — cc + print info, using paragraph borders
    //  Avoids tables for consistent rendering across docx-preview and Word.
    // ═══════════════════════════════════════════════════════════

    private java.util.List<XWPFParagraph> addBanji(XWPFDocument doc, String cc, String printUnit,
                                                     String printDate, boolean hasCc,
                                                     boolean hasBefore, boolean compress) {
        java.util.List<XWPFParagraph> paras = new java.util.ArrayList<>();
        double lineHt = BANJI_SIZE * 1.2;

        boolean first = true;

        // ── CC ──
        if (hasCc) {
            XWPFParagraph cp = doc.createParagraph();
            cp.setAlignment(ParagraphAlignment.LEFT);
            cp.setSpacingBetween(lineHt, LineSpacingRule.EXACT);
            cp.setSpacingBefore(0);
            cp.setSpacingAfter(0);
            setSnapToGrid(cp, false);
            setTightTopBorder(cp, "000000");
            setTightBottomBorder(cp, "000000");
            XWPFRun cr = cp.createRun();
            cr.setText("抄送：" + cc);
            cr.setFontSize(BANJI_SIZE);
            setEastAsianFont(cr, FONT_FANGSONG);
            if (first) { cp.setSpacingBefore(ptToTwips(12)); first = false; }
            paras.add(cp);
        }

        // ── Print ──
        if (TextUtils.isSet(printUnit)) {
            XWPFParagraph pp = doc.createParagraph();
            pp.setSpacingBetween(lineHt, LineSpacingRule.EXACT);
            pp.setSpacingBefore(0);
            pp.setSpacingAfter(0);
            setSnapToGrid(pp, false);
            // Top border (only if no CC above, otherwise CC's bottom serves as middle rule)
            if (!hasCc) {
                setTightTopBorder(pp, "000000");
            }
            setTightBottomBorder(pp, "000000");

            XWPFRun ur = pp.createRun();
            ur.setText(printUnit);
            ur.setFontSize(BANJI_SIZE);
            setEastAsianFont(ur, FONT_FANGSONG);

            if (TextUtils.isSet(printDate)) {
                CTTabStop tab = pp.getCTP().getPPr().addNewTabs().addNewTab();
                tab.setVal(STTabJc.RIGHT);
                tab.setPos(BigInteger.valueOf((long)((21.0 - LEFT_CM - RIGHT_CM) * CM_TO_TWIPS)));
                XWPFRun dr = pp.createRun();
                dr.setText("\t" + printDate + "印发");
                dr.setFontSize(BANJI_SIZE);
                setEastAsianFont(dr, FONT_FANGSONG);
            }
            paras.add(pp);
        }

        return paras;
    }

    // ═══════════════════════════════════════════════════════════
    //  Orphan detection
    // ═══════════════════════════════════════════════════════════

    @SuppressWarnings("unused")
    private double estimateDeficit(String body, String organization, String date,
                                    String note, String cc, String printUnit, String printDate,
                                    boolean hasRedHeader) {
        if (body == null || body.isBlank()) return 0;

        double topCm = 3.7;

        // Available page content height (excluding margins)
        // A4 height = 29.7cm
        double contentHeightCm = 29.7 - topCm - DEFAULT_BOTTOM_CM;
        int contentHeightTwips = (int)(contentHeightCm * CM_TO_TWIPS);

        // Title overhead (if present)
        int titleOverhead = (int)(TITLE_SIZE * 20 * 2.5); // ~2.5 lines for title + spacing

        // Estimate body height
        int bodyHeight = estimateParagraphsHeight(body, contentHeightTwips);

        // Estimate closing block height
        int closingHeight = estimateClosingHeight(organization, date, note, cc, printUnit, printDate);

        // Total needed on last page: last body text + closing block
        // We care about: content after the last page break
        // Simplification: content that overflows onto the last page
        int totalNeeded = bodyHeight + titleOverhead;
        int pagesNeeded = (int)Math.ceil((double)totalNeeded / contentHeightTwips);
        int usedOnLastPage = totalNeeded - (pagesNeeded - 1) * contentHeightTwips;
        if (usedOnLastPage <= 0) usedOnLastPage = bodyHeight; // all on first page

        int remainingAfterBody = contentHeightTwips - usedOnLastPage;
        int closingNeed = closingHeight + ptToTwips(CLOSING_SAFETY_PT); // safety margin

        if (closingNeed > remainingAfterBody) {
            int deficitTwips = closingNeed - remainingAfterBody;
            return deficitTwips * 0.03514598 / 20.0; // twips → pt → cm
        }

        return 0;
    }

    private int estimateParagraphsHeight(String body, int pageWidthTwips) {
        int total = 0;
        String[] rawParas = body.split("\n");
        int charWidth = ptToTwips(BODY_SIZE); // Chinese char ≈ font size in width
        int indentWidth = ptToTwips(BODY_SIZE * 2);
        int lineHeight = ptToTwips(BODY_LINE_HEIGHT);
        int paraGap = ptToTwips(BODY_PARAGRAPH_GAP);

        for (String raw : rawParas) {
            String t = raw.trim();
            if (t.isEmpty()) {
                total += paraGap + ptToTwips(4);
                continue;
            }
            // Strip heading markers for length calculation
            String display = t;
            if (t.startsWith("## ")) display = t.substring(3);
            else if (t.startsWith("# ")) display = t.substring(2);

            boolean isHeading = classifyHeading(t) > 0;
            int effectiveWidth = isHeading ? pageWidthTwips : pageWidthTwips - indentWidth;
            int charsPerLine = Math.max(1, effectiveWidth / charWidth);

            // Count chars (Chinese: 1 char = 1 width unit; ASCII letters: 0.5 width unit)
            int totalWidthUnits = countCharWidthUnits(display);
            int lines = (int)Math.ceil((double)totalWidthUnits / charsPerLine);
            if (lines < 1) lines = 1;

            total += lines * lineHeight + paraGap;
        }

        return total;
    }

    private int countCharWidthUnits(String s) {
        int units = 0;
        for (int i = 0; i < s.length(); i++) {
            units += TextUtils.charWidth(s.charAt(i));
        }
        return units;
    }

    private int estimateBodyHeight(String body) {
        if (body == null || body.isBlank()) return 0;
        int h = 0;
        for (String line : body.split("\n")) {
            if (line.trim().isEmpty()) h += ptToTwips(BODY_LINE_HEIGHT);
            else h += ptToTwips(BODY_LINE_HEIGHT);
        }
        return h;
    }

    private int estimateLuokuanHeight(String org, String date) {
        int h = 0;
        if (TextUtils.isSet(org)) h += ptToTwips(BODY_LINE_HEIGHT);
        if (TextUtils.isSet(date)) h += ptToTwips(BODY_LINE_HEIGHT);
        return h;
    }

    private int estimateBanjiHeight(boolean hasCc, boolean hasPrint) {
        int h = 0;
        if (hasCc) h += ptToTwips(BANJI_SIZE * 1.2) + ptToTwips(4);
        if (hasPrint) h += ptToTwips(BANJI_SIZE * 1.2) + ptToTwips(4);
        return h;
    }

    private int estimateClosingHeight(String organization, String date, String note,
                                       String cc, String printUnit, String printDate) {
        int h = cmToTwips(CLOSING_LEADING_SPACE_CM);
        boolean hasOrg = TextUtils.isSet(organization);
        boolean hasDate = TextUtils.isSet(date);
        boolean hasNote = TextUtils.isSet(note);
        boolean hasCc = TextUtils.isSet(cc);
        boolean hasPrintUnit = TextUtils.isSet(printUnit);

        if (hasOrg || hasDate) {
            h += estimateLuokuanHeight(organization, date);
            if (hasOrg && hasDate) h += ptToTwips(6);
        }
        if (hasNote) h += ptToTwips(BODY_LINE_HEIGHT) + ptToTwips(6);
        if (hasCc || hasPrintUnit) {
            h += estimateBanjiHeight(hasCc, hasPrintUnit);
            h += ptToTwips(12);
        }
        return h;
    }

    // ═══════════════════════════════════════════════════════════
    //  Heading detection (same logic as LatexService)
    // ═══════════════════════════════════════════════════════════

    private int classifyHeading(String text) {
        if (text == null) return 0;
        // GB/T 9704-2012 7.3.3:
        // 一、 → 第一层 黑体
        if (text.matches("^[一二三四五六七八九十]+、.*")) return 1;
        if (text.startsWith("# ")) return 1;
        // （一） → 第二层 楷体
        if (text.matches("^[（(][一二三四五六七八九十]+[）)].*")) return 2;
        if (text.startsWith("## ")) return 2;
        // (1) → 第四层 仿宋 (check before 1. to avoid confusion)
        if (text.matches("^[（(]\\d+[）)].*")) return 4;
        // 1. → 第三层 仿宋
        if (text.matches("^\\d+[.].*")) return 3;
        if (text.startsWith("### ")) return 3;
        return 0;
    }

    // ═══════════════════════════════════════════════════════════
    //  Utility methods
    // ═══════════════════════════════════════════════════════════

    private int cmToTwips(double cm) {
        return (int)(cm * CM_TO_TWIPS);
    }

    private int ptToTwips(double pt) {
        return (int)(pt * 20);
    }

    private void setEastAsianFont(XWPFRun run, String fontFamily) {
        run.setFontFamily(fontFamily);
    }

    private void setTightTopBorder(XWPFParagraph p, String color) {
        CTPPr ppr = p.getCTP().isSetPPr() ? p.getCTP().getPPr() : p.getCTP().addNewPPr();
        CTPBdr borders = ppr.isSetPBdr() ? ppr.getPBdr() : ppr.addNewPBdr();
        CTBorder top = borders.isSetTop() ? borders.getTop() : borders.addNewTop();
        top.setVal(STBorder.SINGLE);
        top.setSz(BigInteger.valueOf(4));
        top.setColor(color);
        top.setSpace(BigInteger.valueOf(0));
    }

    private void setTightBottomBorder(XWPFParagraph p, String color) {
        CTPPr ppr = p.getCTP().isSetPPr() ? p.getCTP().getPPr() : p.getCTP().addNewPPr();
        CTPBdr borders = ppr.isSetPBdr() ? ppr.getPBdr() : ppr.addNewPBdr();
        CTBorder bottom = borders.isSetBottom() ? borders.getBottom() : borders.addNewBottom();
        bottom.setVal(STBorder.SINGLE);
        bottom.setSz(BigInteger.valueOf(4));
        bottom.setColor(color);
        bottom.setSpace(BigInteger.valueOf(0));
    }

    private void setParagraphBottomBorder(XWPFParagraph p, String color, int sizeEighthsPt, int spacePt) {
        CTPPr ppr = p.getCTP().isSetPPr() ? p.getCTP().getPPr() : p.getCTP().addNewPPr();
        CTPBdr borders = ppr.isSetPBdr() ? ppr.getPBdr() : ppr.addNewPBdr();
        CTBorder bottom = borders.isSetBottom() ? borders.getBottom() : borders.addNewBottom();
        bottom.setVal(STBorder.SINGLE);
        bottom.setSz(BigInteger.valueOf(sizeEighthsPt));
        bottom.setColor(color);
        bottom.setSpace(BigInteger.valueOf(spacePt));
    }

    private void setSnapToGrid(XWPFParagraph p, boolean snap) {
        CTPPr ppr = p.getCTP().isSetPPr() ? p.getCTP().getPPr() : p.getCTP().addNewPPr();
        CTOnOff grid = ppr.isSetSnapToGrid() ? ppr.getSnapToGrid() : ppr.addNewSnapToGrid();
        grid.setVal(snap);
    }

    private void setKeepLines(XWPFParagraph p, boolean keep) {
        CTPPr ppr = p.getCTP().isSetPPr() ? p.getCTP().getPPr() : p.getCTP().addNewPPr();
        if (keep) {
            CTOnOff keepLines = ppr.isSetKeepLines() ? ppr.getKeepLines() : ppr.addNewKeepLines();
            keepLines.setVal(true);
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  Meeting Minutes Generator
    // ═══════════════════════════════════════════════════════════

    private static final double MM_TITLE_SIZE = 16;
    private static final double MM_HEADING_SIZE = 16;
    private static final double MM_BODY_SIZE = 16;
    private static final double MM_RED_HEADER_SIZE = 22;
    private static final double MM_DOC_NUMBER_SIZE = 16;
    private static final double MM_LINE_HEIGHT = 28.0;
    private static final double MM_TOP_CM = 3.7;
    private static final double MM_BOTTOM_CM = 3.5;
    private static final double MM_LEFT_CM = 2.8;
    private static final double MM_RIGHT_CM = 2.6;
    private static final double MM_HEADER_CM = 1.5;
    private static final double MM_FOOTER_CM = 1.75;

    public byte[] generateMeetingMinutes(
            String title, String meetingTime, String meetingLocation,
            String host, String recorder, String attendees, String attendeesOther,
            String agenda, String content, String resolution,
            String redHeader, String documentNumber
    ) throws Exception {

        boolean hasRedHeader = TextUtils.isSet(redHeader);

        try (XWPFDocument doc = new XWPFDocument()) {

            setPageMargins(doc, MM_TOP_CM, MM_BOTTOM_CM, MM_LEFT_CM, MM_RIGHT_CM,
                    MM_HEADER_CM, MM_FOOTER_CM);

            // ── Red header ──
            if (hasRedHeader) {
                addMmRedHeader(doc, redHeader, documentNumber);
            }

            // ── Title ──
            if (TextUtils.isSet(title)) {
                XWPFParagraph tp = doc.createParagraph();
                tp.setAlignment(ParagraphAlignment.CENTER);
                tp.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
                tp.setSpacingBefore(ptToTwips(28));
                tp.setSpacingAfter(ptToTwips(14));
                XWPFRun tr = tp.createRun();
                tr.setText(title);
                tr.setFontSize(MM_TITLE_SIZE);
                setEastAsianFont(tr, "黑体");
            }

            // ── 一、会议基本信息 ──
            if (hasAnyInfo(meetingTime, meetingLocation, host, recorder, attendees, attendeesOther)) {
                addMmSectionHeading(doc, "一、会议基本信息");

                addMmInfoLine(doc, "会议时间：", meetingTime);
                addMmInfoLine(doc, "会议地点：", meetingLocation);
                addMmInfoLine(doc, "主 持 人：", host);
                addMmInfoLine(doc, "记 录 人：", recorder);
                addMmInfoLine(doc, "出席人员：", attendees);
                if (TextUtils.isSet(attendeesOther)) {
                    addMmInfoLine(doc, "列席人员：", attendeesOther);
                }
            }

            // ── 二、会议议题 ──
            if (TextUtils.isSet(agenda)) {
                addMmSectionHeading(doc, "二、会议议题");
                addMmBodyParagraph(doc, agenda, true);
            }

            // ── 三、会议主要内容及议定事项 ──
            if (TextUtils.isSet(content)) {
                addMmSectionHeading(doc, "三、会议主要内容及议定事项");

                String[] bodyParas = content.split("\n");
                for (String para : bodyParas) {
                    String text = para.trim();
                    if (text.isEmpty()) continue;
                    addMmBodyParagraph(doc, text, true);
                }
            }

            // ── 会议决议 ──
            if (TextUtils.isSet(resolution)) {
                addMmSectionHeading(doc, "四、会议决议");
                String[] resParas = resolution.split("\n");
                for (String para : resParas) {
                    String text = para.trim();
                    if (text.isEmpty()) continue;
                    addMmBodyParagraph(doc, text, true);
                }
            }

            // ── 签字 ──
            XWPFParagraph sigHead = doc.createParagraph();
            sigHead.setAlignment(ParagraphAlignment.LEFT);
            sigHead.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
            sigHead.setSpacingBefore(ptToTwips(12));
            sigHead.setSpacingAfter(0);
            sigHead.setIndentationFirstLine(0);
            XWPFRun sigr = sigHead.createRun();
            sigr.setText("五、签字");
            sigr.setFontSize(MM_HEADING_SIZE);
            setEastAsianFont(sigr, "黑体");

            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            doc.write(bos);
            return bos.toByteArray();
        }
    }

    private boolean hasAnyInfo(String... values) {
        for (String v : values) {
            if (TextUtils.isSet(v)) return true;
        }
        return false;
    }

    private void addMmSectionHeading(XWPFDocument doc, String heading) {
        XWPFParagraph p = doc.createParagraph();
        p.setAlignment(ParagraphAlignment.LEFT);
        p.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
        p.setSpacingBefore(ptToTwips(6));
        p.setSpacingAfter(0);
        p.setIndentationFirstLine(0);
        XWPFRun r = p.createRun();
        r.setText(heading);
        r.setFontSize(MM_HEADING_SIZE);
        setEastAsianFont(r, "黑体");
    }

    private void addMmRedHeader(XWPFDocument doc, String redHeader, String documentNumber) {
        int negIndent = -cmToTwips(2.0);

        // Red header unit — 方正小标宋 22pt, red, centered, extended beyond margins
        XWPFParagraph p1 = doc.createParagraph();
        p1.setAlignment(ParagraphAlignment.CENTER);
        p1.setIndentationLeft(negIndent);
        p1.setIndentationRight(negIndent);
        p1.setSpacingBefore(0);
        p1.setSpacingAfter(0);
        XWPFRun r1 = p1.createRun();
        r1.setText(redHeader);
        r1.setFontSize(MM_RED_HEADER_SIZE);
        r1.setColor(CHINA_RED);
        setEastAsianFont(r1, "方正小标宋简体");

        // Document number — 仿宋 16pt, centered
        if (TextUtils.isSet(documentNumber)) {
            XWPFParagraph sp = doc.createParagraph();
            sp.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
            sp.setSpacingBefore(0);
            sp.setSpacingAfter(0);
            XWPFRun sr = sp.createRun();
            sr.setFontSize(MM_DOC_NUMBER_SIZE);
            setEastAsianFont(sr, "仿宋");

            XWPFParagraph p2 = doc.createParagraph();
            p2.setAlignment(ParagraphAlignment.CENTER);
            p2.setIndentationLeft(0);
            p2.setIndentationRight(0);
            p2.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
            p2.setSpacingBefore(0);
            p2.setSpacingAfter(0);
            XWPFRun r2 = p2.createRun();
            r2.setText(documentNumber);
            r2.setFontSize(MM_DOC_NUMBER_SIZE);
            setEastAsianFont(r2, "仿宋");

            // Red separator line — fixed 1pt, no spacing before/after
            XWPFParagraph p3 = doc.createParagraph();
            p3.setAlignment(ParagraphAlignment.CENTER);
            p3.setSpacingBetween(1.0, LineSpacingRule.EXACT);
            p3.setSpacingBefore(0);
            p3.setSpacingAfter(0);
            XWPFRun r3 = p3.createRun();
            r3.setColor(CHINA_RED);
            setParagraphBottomBorder(p3, CHINA_RED, 12);
        }
    }

    private void addMmInfoLine(XWPFDocument doc, String label, String value) {
        if (!TextUtils.isSet(value)) return;
        XWPFParagraph p = doc.createParagraph();
        p.setAlignment(ParagraphAlignment.LEFT);
        p.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
        p.setSpacingBefore(0);
        p.setSpacingAfter(0);
        p.setIndentationFirstLine(0);
        XWPFRun r = p.createRun();
        r.setText(label + "  " + value);
        r.setFontSize(MM_BODY_SIZE);
        setEastAsianFont(r, "仿宋");
    }

    private void addMmBodyParagraph(XWPFDocument doc, String text, boolean indent) {
        XWPFParagraph p = doc.createParagraph();
        p.setAlignment(ParagraphAlignment.BOTH);
        p.setSpacingBetween(MM_LINE_HEIGHT, LineSpacingRule.EXACT);
        p.setSpacingBefore(0);
        p.setSpacingAfter(0);
        if (indent) {
            p.setIndentationFirstLine(ptToTwips(MM_BODY_SIZE * 2));
        }
        XWPFRun r = p.createRun();
        r.setText(text);
        r.setFontSize(MM_BODY_SIZE);
        setEastAsianFont(r, "仿宋");
    }
}
