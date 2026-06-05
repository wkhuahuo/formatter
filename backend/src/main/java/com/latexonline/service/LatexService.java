package com.latexonline.service;

import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.*;

@Service
public class LatexService {

    @SuppressWarnings("unused")
    public byte[] compile(
            String redHeader, String documentNumber,
            String title, String body,
            String organization, String date,
            String note, String cc, String printUnit, String printDate, String printCopies
    ) throws Exception {

        StringBuilder tex = new StringBuilder();

        // === Preamble: GB/T 9704-2012 ===
        // 版心 156mm×225mm, 天头37mm, 地脚35mm, 订口28mm, 翻口26mm
        tex.append("""
                \\documentclass[UTF8]{ctexart}
                \\usepackage{xcolor}
                \\usepackage{fancyhdr}
                \\usepackage{geometry}
                \\usepackage{array}
                \\definecolor{chinaRed}{RGB}{238,0,0}
                """);

        boolean hasRedHeader = isSet(redHeader);

        // Page geometry — exact GB/T 9704-2012 values
        if (hasRedHeader) {
            tex.append("""
                    \\geometry{
                      a4paper,
                      top=4.5cm,
                      bottom=3.5cm,
                      left=2.8cm,
                      right=2.6cm,
                      headheight=2.5cm,
                      headsep=0.5cm,
                      footskip=1.75cm
                    }
                    """);
        } else {
            tex.append("""
                    \\geometry{
                      a4paper,
                      top=3.7cm,
                      bottom=3.5cm,
                      left=2.8cm,
                      right=2.6cm
                    }
                    """);
        }

        // Red header — first page only, extends 2cm beyond body margins
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

        // Title: 方正小标宋二号(22pt) 加粗居中, 与正文间距半行(14pt)
        if (isSet(title)) {
            tex.append("\\begin{center}\n");
            tex.append("{\\songti\\fontsize{22pt}{28pt}\\selectfont\\bfseries ");
            tex.append(escape(title).replace(" ", "\\quad{}"));
            tex.append("\\par}\n");
            tex.append("\\end{center}\n");
            tex.append("\\vspace{14pt}\n");
        }

        // --- 严格对标 WPS 固定值28磅 ---
        // \fontsize{16pt}{28pt} = 基线距28pt, WPS"固定值28磅"的精确等效
        // \parskip=0pt 消除额外段间距, 段落间仅靠基线距区分

        // --- 四级空间压缩策略 (WPS 28磅基线 + 弹性压缩) ---
        // P1: 正文→落款间距 3cm 可压至 1cm (主弹性点)
        // P2: 正文行距 28pt 可微压至 27pt
        // P3: 段落间隙 4pt 可压至 0pt
        // P4: 版心下延 1.2cm 侵入地脚

        // Body: 仿宋三号(16pt), P2行距含微压缩
        tex.append("\\fangsong\\fontsize{16pt}{28pt plus 0pt minus 1pt}\\selectfont\n");
        tex.append("\\setlength{\\parskip}{0pt}\n");
        tex.append("\\setlength{\\parindent}{2\\ccwd}\n");
        if (isSet(body)) {
            tex.append(formatBody(body));
        }

        // Closing + Note + Banji
        boolean hasOrg = isSet(organization);
        boolean hasDate = isSet(date);
        boolean hasCc = isSet(cc);
        boolean hasPrintUnit = isSet(printUnit);
        boolean hasBanji = hasCc || hasPrintUnit;

        // P4: 版心下延
        if (hasBanji) {
            tex.append("\\enlargethispage{1.2cm}\n");
        }

        // P1: "特此通告"与落款之间 — 主弹性胶水，正常3cm可压至1cm
        if (hasOrg || hasDate) {
            tex.append("\\vspace{3cm plus 0pt minus 2cm}\n");
            tex.append("\\begin{flushright}\n");
            if (hasOrg) {
                tex.append(escape(organization)).append(" \\\\[0.5em]\n");
            }
            if (hasDate) {
                tex.append(escape(date)).append("\n");
            }
            tex.append("\\end{flushright}\n");
        }

        // Note: 居左空二字加圆括号, 仿宋三号
        if (isSet(note)) {
            tex.append("\\fangsong\\fontsize{16pt}{28pt}\\selectfont\n");
            tex.append("\\hspace{2\\ccwd}（").append(escape(note)).append("）\n\n");
        }

        // Banji: \vspace*{\fill} 确保换页后仍贴底（不会被页首吞掉）
        if (hasBanji) {
            tex.append("\\vspace*{\\fill}\n");
            tex.append("\\noindent\n");
            tex.append("{\\fangsong\\fontsize{14pt}{14pt}\\selectfont\n");
            tex.append("\\renewcommand{\\arraystretch}{0.85}\n");
            tex.append("\\setlength{\\tabcolsep}{0pt}\n");
            tex.append("\\begin{tabular}{@{}p{\\linewidth}@{}}\n");
            tex.append("\\hline\n");

            if (hasCc) {
                tex.append("\\hspace{1em}抄送：").append(escape(stripTrailingPeriod(cc))).append("\\hspace{1em} \\\\\n");
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

        tex.append("\\end{document}\n");

        // === Compile with xelatex ===
        Path workDir = Files.createTempDirectory("latex_");
        File texFile = new File(workDir.toFile(), "document.tex");

        try (FileWriter writer = new FileWriter(texFile)) {
            writer.write(tex.toString());
        }

        ProcessBuilder pb = new ProcessBuilder(
                "xelatex",
                "-interaction=nonstopmode",
                "-halt-on-error",
                "-output-directory=" + workDir.toString(),
                texFile.getAbsolutePath()
        );
        pb.directory(workDir.toFile());

        Process process = pb.start();
        String log = new String(process.getInputStream().readAllBytes());
        int exitCode = process.waitFor();

        if (exitCode == 0) {
            new ProcessBuilder(
                    "xelatex",
                    "-interaction=nonstopmode",
                    "-output-directory=" + workDir.toString(),
                    texFile.getAbsolutePath()
            ).directory(workDir.toFile()).start().waitFor();
        } else {
            deleteDir(workDir);
            throw new RuntimeException("LaTeX compilation failed:\n" + log);
        }

        File pdfFile = new File(workDir.toFile(), "document.pdf");
        if (!pdfFile.exists()) {
            deleteDir(workDir);
            throw new RuntimeException("PDF not generated. Log:\n" + log);
        }

        byte[] pdfBytes = Files.readAllBytes(pdfFile.toPath());
        deleteDir(workDir);

        return pdfBytes;
    }

    // Format body paragraphs: blank lines in input = paragraph break
    // GB/T 9704 → 仿宋三号 16pt/28pt, 首行缩进2字符在正文区设置
    private String formatBody(String body) {
        StringBuilder out = new StringBuilder();
        String[] paragraphs = body.split("\n");
        for (String p : paragraphs) {
            String t = p.trim();
            if (t.isEmpty()) {
                // P3: 段落间隙小弹性 4pt→0pt
                out.append("\\vspace{4pt plus 2pt minus 4pt}\n");
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

    // Auto-detect heading level: 一级 "一、" → heiti, 二级 "(一)" → kaishu
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
