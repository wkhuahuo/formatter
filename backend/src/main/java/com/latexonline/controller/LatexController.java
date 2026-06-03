package com.latexonline.controller;

import com.latexonline.service.LatexService;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class LatexController {

    private final LatexService latexService;

    public LatexController(LatexService latexService) {
        this.latexService = latexService;
    }

    @PostMapping("/compile")
    public ResponseEntity<?> compile(@RequestBody Map<String, String> body) {
        try {
            String redHeader = body.getOrDefault("redHeader", "");
            String documentNumber = body.getOrDefault("documentNumber", "");
            String title = body.getOrDefault("title", "");
            String content = body.getOrDefault("body", "");
            String organization = body.getOrDefault("organization", "");
            String date = body.getOrDefault("date", "");
            String note = body.getOrDefault("note", "");
            String cc = body.getOrDefault("cc", "");
            String printUnit = body.getOrDefault("printUnit", "");
            String printDate = body.getOrDefault("printDate", "");
            String printCopies = body.getOrDefault("printCopies", "");

            byte[] pdf = latexService.compile(
                    redHeader, documentNumber,
                    title, content,
                    organization, date,
                    note, cc, printUnit, printDate, printCopies
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDisposition(ContentDisposition.inline().filename("document.pdf").build());

            return ResponseEntity.ok().headers(headers).body(pdf);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
}
