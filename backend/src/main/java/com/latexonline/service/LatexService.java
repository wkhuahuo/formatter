package com.latexonline.service;

import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.*;
import java.util.UUID;

@Service
public class LatexService {

    private static final String TEMPLATE = """
            \\documentclass[UTF8]{ctexart}
            \\usepackage{geometry}
            \\geometry{a4paper, margin=2.5cm}
            \\pagestyle{empty}

            \\begin{document}

            \\begin{center}
            {\\LARGE\\bfseries %s}
            \\end{center}

            \\vspace{2em}

            %s

            \\vspace{3em}

            \\begin{flushright}
            %s \\\\[1em]
            %s
            \\end{flushright}

            \\end{document}
            """;

    public byte[] compile(String title, String body, String organization, String date) throws Exception {
        String texContent = String.format(TEMPLATE,
                escape(title),
                body.replace("\n", "\n\n"),
                escape(organization),
                escape(date));

        Path workDir = Files.createTempDirectory("latex_");
        File texFile = new File(workDir.toFile(), "document.tex");

        try (FileWriter writer = new FileWriter(texFile)) {
            writer.write(texContent);
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
        String stderr = new String(process.getInputStream().readAllBytes());
        int exitCode = process.waitFor();

        // Run twice for proper table of contents / references
        if (exitCode == 0) {
            new ProcessBuilder(
                    "xelatex",
                    "-interaction=nonstopmode",
                    "-output-directory=" + workDir.toString(),
                    texFile.getAbsolutePath()
            ).directory(workDir.toFile()).start().waitFor();
        } else {
            deleteDir(workDir);
            throw new RuntimeException("LaTeX compilation failed:\n" + stderr);
        }

        File pdfFile = new File(workDir.toFile(), "document.pdf");
        if (!pdfFile.exists()) {
            deleteDir(workDir);
            throw new RuntimeException("PDF not generated. Log:\n" + stderr);
        }

        byte[] pdfBytes = Files.readAllBytes(pdfFile.toPath());
        deleteDir(workDir);

        return pdfBytes;
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
