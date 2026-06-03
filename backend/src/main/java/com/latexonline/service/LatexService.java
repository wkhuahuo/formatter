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
            String cc, String printUnit, String printDate, String printCopies
    ) throws Exception {

        StringBuilder tex = new StringBuilder();

        // --- Preamble ---
        tex.append("""
                \\documentclass[UTF8]{ctexart}
                \\usepackage{xcolor}
                \\usepackage{fancyhdr}
                \\usepackage{geometry}
                \\definecolor{chinaRed}{RGB}{238,0,0}
                """);

        boolean hasRedHeader = isSet(redHeader);

        // --- Page geometry per GB/T 9704-2012 ---
        // 版心 156mm×225mm, 天头37mm, 地脚35mm, 订口28mm, 翻口26mm
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

        // --- Red header, first page only ---
        // Red text and doc number extend 2cm beyond body margins on each side
        // Uses \makebox[0pt][c] to center the oversized content
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
            // Default: no header on other pages
            tex.append("\\pagestyle{empty}\n");
        } else {
            tex.append("\\pagestyle{empty}\n");
        }


        tex.append("\n\\begin{document}\n");
        if (hasRedHeader) {
            tex.append("\\thispagestyle{redfirst}\n");
        }

        // --- Title: GB/T 9704-2012 方正小标宋二号加粗居中 ---
        // 标题中空格用 \quad{} 保留
        // 与正文间距1行(28pt)
        if (isSet(title)) {
            tex.append("\\begin{center}\n");
            tex.append("{\\songti\\fontsize{22pt}{28pt}\\selectfont\\bfseries ");
            tex.append(escape(title).replace(" ", "\\quad{}"));
            tex.append("\\par}\n");
            tex.append("\\end{center}\n");
            tex.append("\\vspace{14pt}\n");
        }

        // --- Body: GB/T 9704-2012 ---
        // 仿宋三号 16pt, 固定行距28pt, 首行缩进2字符
        // 一级标题(一、): 黑体三号, 二级((一)): 楷体三号
        tex.append("\\fangsong\\fontsize{16pt}{28pt}\\selectfont\n");
        tex.append("\\setlength{\\parindent}{2\\ccwd}\n");
        if (isSet(body)) {
            tex.append(formatBody(body));
        }

        // --- Closing: 仿宋三号右对齐 ---
        boolean hasOrg = isSet(organization);
        boolean hasDate = isSet(date);
        if (hasOrg || hasDate) {
            tex.append("\\vspace{2em}\n\\begin{flushright}\n");
            if (hasOrg) {
                tex.append(escape(organization)).append(" \\\\[0.5em]\n");
            }
            if (hasDate) {
                tex.append(escape(date)).append("\n");
            }
            tex.append("\\end{flushright}\n");
        }

        // --- CC & distribution ---
        // 贴页面底部, tabular + hline 紧贴, 仿宋四号(14pt)
        boolean hasCc = isSet(cc);
        boolean hasPrintUnit = isSet(printUnit);
        if (hasCc || hasPrintUnit) {
            tex.append("\\vfill\n");
            tex.append("\\noindent\n");
            tex.append("{\\fangsong\\fontsize{14pt}{14pt}\\selectfont\n");
            tex.append("\\renewcommand{\\arraystretch}{0.85}\n");
            tex.append("\\setlength{\\tabcolsep}{0pt}\n");
            tex.append("\\begin{tabular}{@{}p{\\linewidth}@{}}\n");
            tex.append("\\hline\n");

            if (hasCc) {
                tex.append("抄送：").append(escape(cc)).append(" \\\\\n");
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

        // --- Compile ---
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

    // Format body text per GB/T 9704-2012:
    // 一级标题 "一、": \heiti, 二级 "(一)": \kaishu, 三级 "1.": default
    private String formatBody(String body) {
        StringBuilder out = new StringBuilder();
        String[] paragraphs = body.split("\n");
        for (int i = 0; i < paragraphs.length; i++) {
            String p = paragraphs[i].trim();
            if (p.isEmpty()) {
                out.append("\n\n");
                continue;
            }
            String cmd = classifyHeading(p);
            // Strip manual markers from display text
            String display = p;
            if (p.startsWith("## ")) {
                display = p.substring(3);
            } else if (p.startsWith("# ")) {
                display = p.substring(2);
            }
            if (cmd != null) {
                out.append("{\\").append(cmd).append(" ").append(escape(display)).append("}\n\n");
            } else {
                out.append(escape(display)).append("\n\n");
            }
        }
        return out.toString();
    }

    // Returns "heiti" for 一级标题, "kaishu" for 二级, null for body text
    // Supports both auto-detection and manual markers:
    //   auto: "一、..." → heiti, "（一）..." → kaishu
    //   manual: "# 一、..." → heiti, "## （一）..." → kaishu
    private String classifyHeading(String p) {
        // Manual marker: ## for level 2
        if (p.startsWith("## ")) {
            return "kaishu";
        }
        // Manual marker: # for level 1
        if (p.startsWith("# ")) {
            return "heiti";
        }
        // Auto-detect: 一级标题 "一、", "十一、", "二十一、" etc.
        if (p.matches("^[一二三四五六七八九十]{1,6}、.*")) {
            return "heiti";
        }
        // Auto-detect: 二级标题 "（一）", "（十一）" etc.
        if (p.matches("^（[一二三四五六七八九十]{1,6}）.*")) {
            return "kaishu";
        }
        return null;
    }

    private boolean isSet(String s) {
        return s != null && !s.isBlank();
    }

    private String escape(String input) {
        if (input == null) return "";
        return input
                .replace("\\", "\\textbackslash ")
                .replace("&", "\\&")
                .replace("%", "\\%")
                .replace("$", "\\$")
                .replace("#", "\\#")
                .replace("_", "\\_")
                .replace("{", "\\{")
                .replace("}", "\\}")
                .replace("~", "\\textasciitilde ")
                .replace("^", "\\textasciicircum ");
    }

    private void deleteDir(Path dir) {
        try {
            if (Files.exists(dir)) {
                try (var stream = Files.walk(dir)) {
                    stream.sorted(java.util.Comparator.reverseOrder())
                            .forEach(p -> {
                                try { Files.delete(p); } catch (IOException ignored) {}
                            });
                }
            }
        } catch (IOException ignored) {}
    }
}
