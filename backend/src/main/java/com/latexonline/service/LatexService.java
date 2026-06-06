package com.latexonline.service;

import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.*;
import java.util.regex.*;

@Service
public class LatexService {

    // Minimum bottom margin in cm — never shrink below this
    private static final double MIN_BOTTOM_CM = 2.0;
    // Default bottom margin per GB/T 9704-2012
    private static final double DEFAULT_BOTTOM_CM = 3.5;
    // Threshold: deficit must be ≤ 2 body lines to trigger adjustment
    private static final double TWO_LINES_CM = 2 * 28 * 0.03514598; // 28pt * 2 ≈ 1.97cm

    @SuppressWarnings("unused")
    public byte[] compile(
            String redHeader, String documentNumber,
            String title, String body,
            String organization, String date,
            String note, String cc, String printUnit, String printDate, String printCopies
    ) throws Exception {

        // --- first attempt with default bottom margin ---
        String tex = buildLatex(
                redHeader, documentNumber, title, body,
                organization, date, note, cc, printUnit, printDate, printCopies,
                DEFAULT_BOTTOM_CM
        );

        Path[] workDirHolder = new Path[1];
        byte[] pdfBytes = compileTexKeepDir(tex, workDirHolder);
        Path workDir = workDirHolder[0];

        if (pdfBytes == null) {
            throw new RuntimeException("LaTeX compilation failed");
        }

        // --- orphan detection: check .orph file written by LaTeX measurement ---
        File orphanFile = new File(workDir.toFile(), "document.orph");
        double deficitCm = 0;

        if (orphanFile.exists()) {
            try {
                String content = Files.readString(orphanFile.toPath());
                Matcher m = Pattern.compile("DEFICIT=([0-9]+(?:\\.[0-9]+)?)pt").matcher(content);
                if (m.find()) {
                    double deficitPt = Double.parseDouble(m.group(1));
                    deficitCm = deficitPt * 0.03514598; // TeX pt → cm
                }
            } catch (Exception ignored) {
            }
        }

        deleteDir(workDir);

        // If deficit is within 2-line threshold, rebuild with smaller bottom margin
        if (deficitCm > 0 && deficitCm <= TWO_LINES_CM) {
            double newBottom = DEFAULT_BOTTOM_CM - deficitCm;
            if (newBottom >= MIN_BOTTOM_CM) {
                String adjustedTex = buildLatex(
                        redHeader, documentNumber, title, body,
                        organization, date, note, cc, printUnit, printDate, printCopies,
                        newBottom
                );
                byte[] adjustedPdf = compileOnce(adjustedTex);
                if (adjustedPdf != null) {
                    return adjustedPdf;
                }
            }
        }

        return pdfBytes;
    }

    /**
     * Compile a tex string (two xelatex passes). Returns PDF bytes,
     * and keeps workDir alive via outWorkDir so caller can inspect aux files.
     * Returns null on failure (workDir already cleaned up).
     */
    private byte[] compileTexKeepDir(String tex, Path[] outWorkDir) throws Exception {
        Path workDir = Files.createTempDirectory("latex_");
        outWorkDir[0] = workDir;

        File texFile = new File(workDir.toFile(), "document.tex");
        try (FileWriter writer = new FileWriter(texFile)) {
            writer.write(tex);
        }

        // First pass
        ProcessBuilder pb = new ProcessBuilder(
                "xelatex", "-interaction=nonstopmode", "-halt-on-error",
                "-output-directory=" + workDir.toString(), texFile.getAbsolutePath()
        );
        pb.directory(workDir.toFile());
        Process process = pb.start();
        String stdout = new String(process.getInputStream().readAllBytes());
        int exitCode = process.waitFor();

        if (exitCode != 0) {
            deleteDir(workDir);
            outWorkDir[0] = null;
            return null;
        }

        // Second pass
        new ProcessBuilder(
                "xelatex", "-interaction=nonstopmode",
                "-output-directory=" + workDir.toString(), texFile.getAbsolutePath()
        ).directory(workDir.toFile()).start().waitFor();

        File pdfFile = new File(workDir.toFile(), "document.pdf");
        if (!pdfFile.exists()) {
            deleteDir(workDir);
            outWorkDir[0] = null;
            return null;
        }

        return Files.readAllBytes(pdfFile.toPath());
    }

    /**
     * Compile a tex string, return PDF bytes, clean up workDir.
     */
    private byte[] compileOnce(String tex) throws Exception {
        Path[] holder = new Path[1];
        byte[] pdf = compileTexKeepDir(tex, holder);
        if (holder[0] != null) {
            deleteDir(holder[0]);
        }
        return pdf;
    }

    private String buildLatex(
            String redHeader, String documentNumber,
            String title, String body,
            String organization, String date,
            String note, String cc, String printUnit, String printDate, String printCopies,
            double bottomCm
    ) {
        StringBuilder tex = new StringBuilder();

        boolean hasRedHeader = isSet(redHeader);

        // === Preamble ===
        tex.append("\\documentclass[UTF8]{ctexart}\n");
        tex.append("\\usepackage{xcolor}\n");
        tex.append("\\usepackage{fancyhdr}\n");
        tex.append("\\usepackage{geometry}\n");
        tex.append("\\usepackage{array}\n");
        tex.append("\\definecolor{chinaRed}{RGB}{238,0,0}\n");

        // === Page geometry ===
        if (hasRedHeader) {
            tex.append(String.format("""
                    \\geometry{
                      a4paper,
                      top=4.5cm,
                      bottom=%.1fcm,
                      left=2.8cm,
                      right=2.6cm,
                      headheight=2.5cm,
                      headsep=0.5cm,
                      footskip=1.75cm
                    }
                    """, bottomCm));
        } else {
            tex.append(String.format("""
                    \\geometry{
                      a4paper,
                      top=3.7cm,
                      bottom=%.1fcm,
                      left=2.8cm,
                      right=2.6cm
                    }
                    """, bottomCm));
        }

        // === Red header ===
        if (hasRedHeader) {
            tex.append("\\fancypagestyle{redfirst}{\n");
            tex.append("  \\fancyhf{}\n");
            tex.append("  \\fancyhead[C]{\n");
            tex.append("    \\makebox[0pt][c]{\n");
            tex.append("      \\begin{minipage}{\\dimexpr\\textwidth+4cm\\relax}\n");
            tex.append("        \\centering\n");
            tex.append("        {\\color{chinaRed}\\songti\\fontsize{36pt}{42pt}\\selectfont ");
            tex.append(escape(redHeader));
            tex.append("}");

            if (isSet(documentNumber)) {
                tex.append("\\\\[8pt]\n");
                tex.append("        {\\fangsong\\fontsize{16pt}{20pt}\\selectfont ");
                tex.append(escape(documentNumber));
                tex.append("}");
            }

            tex.append("\\\\[6pt]\n");
            tex.append("        \\textcolor{chinaRed}{\\rule{\\linewidth}{1.5pt}}");
            tex.append("\n      \\end{minipage}\n");
            tex.append("    }\n");
            tex.append("  }\n");
            tex.append("  \\renewcommand{\\headrulewidth}{0pt}\n");
            tex.append("}\n");
            tex.append("\\pagestyle{empty}\n");
        } else {
            tex.append("\\pagestyle{empty}\n");
        }

        tex.append("\n\\begin{document}\n");
        if (hasRedHeader) {
            tex.append("\\thispagestyle{redfirst}\n");
        }

        // === Title ===
        if (isSet(title)) {
            tex.append("\\begin{center}\n");
            tex.append("{\\songti\\fontsize{22pt}{28pt}\\selectfont\\bfseries ");
            tex.append(escape(title).replace(" ", "\\quad{}"));
            tex.append("\\par}\n");
            tex.append("\\end{center}\n");
            tex.append("\\vspace{14pt}\n");
        }

        // === Body ===
        tex.append("\\fangsong\\fontsize{16pt}{28pt plus 0pt minus 3pt}\\selectfont\n");
        tex.append("\\setlength{\\parskip}{4pt plus 2pt minus 4pt}\n");
        tex.append("\\setlength{\\parindent}{2\\ccwd}\n");
        if (isSet(body)) {
            tex.append(formatBody(body));
        }

        // === Closing block ===
        boolean hasOrg = isSet(organization);
        boolean hasDate = isSet(date);
        boolean hasCc = isSet(cc);
        boolean hasPrintUnit = isSet(printUnit);
        boolean hasLuokuan = hasOrg || hasDate;
        boolean hasNote = isSet(note);
        boolean hasBanji = hasCc || hasPrintUnit;
        boolean hasClosingBlock = hasLuokuan || hasNote || hasBanji;

        if (hasClosingBlock) {

            // ---- orphan detection: measure closing block height vs remaining page space ----
            tex.append("\n% --- orphan detection ---\n");
            tex.append("\\newwrite\\orphanfile\n");
            tex.append("\\newsavebox{\\closingBox}\n");
            tex.append("\\savebox{\\closingBox}{%\n");
            tex.append("\\begin{minipage}{\\linewidth}\n");

            // 落款
            if (hasLuokuan) {
                tex.append("\\begin{flushright}\n");
                if (hasOrg) {
                    tex.append(escape(organization)).append(" \\\\\n");
                    tex.append("\\vspace{0.5em plus 0em minus 0.3em}\n");
                }
                if (hasDate) {
                    tex.append(escape(date)).append("\n");
                }
                tex.append("\\end{flushright}\n");
            }

            // 附注
            if (hasNote) {
                tex.append("\\fangsong\\fontsize{16pt}{28pt plus 0pt minus 3pt}\\selectfont\n");
                tex.append("\\hspace{2\\ccwd}（").append(escape(note)).append("）\n\n");
            }

            // 版记
            if (hasBanji) {
                if (hasLuokuan || hasNote) {
                    tex.append("\\vspace{1em plus 0em minus 0.5em}\n");
                }
                tex.append("\\noindent\n");
                tex.append("{\\fangsong\\fontsize{14pt}{14pt}\\selectfont\n");
                tex.append("\\renewcommand{\\arraystretch}{0.85}\n");
                tex.append("\\setlength{\\tabcolsep}{0pt}\n");
                tex.append("\\begin{tabular}{@{}p{\\linewidth}@{}}\n");
                tex.append("\\hline\n");

                if (hasCc) {
                    tex.append("\\hspace{1em}抄送：")
                        .append(escape(stripTrailingPeriod(cc)))
                        .append("\\hspace{1em} \\\\\n");
                    tex.append("\\hline\n");
                }

                if (hasPrintUnit) {
                    if (!hasCc) {
                        tex.append("\\hline\n");
                    }
                    tex.append("\\makebox[\\linewidth][s]{");
                    tex.append(escape(printUnit));
                    if (isSet(printDate)) {
                        tex.append("\\hfill ").append(escape(printDate)).append("印发");
                    }
                    tex.append("} \\\\\n");
                    tex.append("\\hline\n");
                }

                tex.append("\\end{tabular}\n");
                tex.append("}\n");
            }

            tex.append("\\end{minipage}%\n");
            tex.append("}\n");  // end \savebox

            // ---- compare remaining space on current page with closing block height ----
            tex.append("\\newdimen\\pageRemaining\n");
            tex.append("\\pageRemaining=\\dimexpr\\pagegoal-\\pagetotal\\relax\n");
            tex.append("\\newdimen\\closingNeed\n");
            tex.append("\\closingNeed=\\dimexpr\\ht\\closingBox+\\dp\\closingBox+14pt\\relax\n");
            tex.append("\\ifdim\\closingNeed>\\pageRemaining\n");
            tex.append("  \\newdimen\\orphDeficit\n");
            tex.append("  \\orphDeficit=\\dimexpr\\closingNeed-\\pageRemaining\\relax\n");
            tex.append("  \\ifdim\\orphDeficit<2\\baselineskip\n");
            tex.append("    \\immediate\\openout\\orphanfile=\\jobname.orph\n");
            tex.append("    \\immediate\\write\\orphanfile{DEFICIT=\\the\\orphDeficit}\n");
            tex.append("    \\immediate\\closeout\\orphanfile\n");
            tex.append("  \\fi\n");
            tex.append("\\fi\n");

            // ---- place the closing block with elastic leading space ----
            tex.append("\n% --- closing block ---\n");
            tex.append("\\vspace{3cm plus 0pt minus 2.5cm}\n");
            tex.append("\\usebox{\\closingBox}\n");
        }

        tex.append("\\end{document}\n");
        return tex.toString();
    }

    // Format body: blank lines in input become paragraph breaks.
    // Spacing is governed by \parskip (elastic) set before the body.
    private String formatBody(String body) {
        StringBuilder out = new StringBuilder();
        String[] paragraphs = body.split("\n");
        for (String p : paragraphs) {
            String t = p.trim();
            if (t.isEmpty()) {
                out.append("\n");
                continue;
            }
            String cmd = classifyHeading(t);
            String display = t;
            if (t.startsWith("## ")) {
                display = t.substring(3);
            } else if (t.startsWith("# ")) {
                display = t.substring(2);
            }
            if (cmd != null) {
                out.append("{\\").append(cmd).append(" ").append(escape(display)).append("}\n\n");
            } else {
                out.append(escape(display)).append("\n\n");
            }
        }
        return out.toString();
    }

    private String classifyHeading(String text) {
        if (text.matches("^[（(][一二三四五六七八九十]+[）)].*")) return "kaishu";
        if (text.matches("^[一二三四五六七八九十]+、.*")) return "heiti";
        if (text.startsWith("# ")) return "heiti";
        if (text.startsWith("## ")) return "kaishu";
        return null;
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\textbackslash{}")
                .replace("&", "\\&")
                .replace("%", "\\%")
                .replace("$", "\\$")
                .replace("#", "\\#")
                .replace("_", "\\_")
                .replace("{", "\\{")
                .replace("}", "\\}")
                .replace("~", "\\textasciitilde{}")
                .replace("^", "\\textasciicircum{}");
    }

    private String stripTrailingPeriod(String s) {
        if (s == null) return "";
        return s.replaceAll("[。.]$", "");
    }

    private boolean isSet(String s) {
        return s != null && !s.isBlank();
    }

    private void deleteDir(Path dir) {
        try {
            if (Files.exists(dir)) {
                try (var files = Files.walk(dir)) {
                    files.sorted(java.util.Comparator.reverseOrder())
                         .forEach(p -> { try { Files.delete(p); } catch (IOException ignored) {} });
                }
            }
        } catch (IOException ignored) {}
    }
}
