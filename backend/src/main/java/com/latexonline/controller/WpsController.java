package com.latexonline.controller;

import com.latexonline.service.WpsService;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class WpsController {

    private final WpsService wpsService;

    public WpsController(WpsService wpsService) {
        this.wpsService = wpsService;
    }

    @PostMapping("/generate")
    public ResponseEntity<?> generate(@RequestBody Map<String, String> b) {
        try {
            String templateType = b.getOrDefault("templateType", "redHeader");
            byte[] docx;
            if ("meetingMinutes".equals(templateType)) {
                docx = wpsService.generateMeetingMinutes(
                        s(b, "title"), s(b, "meetingTime"), s(b, "meetingLocation"),
                        s(b, "host"), s(b, "recorder"), s(b, "attendees"),
                        s(b, "attendeesOther"), s(b, "agenda"), s(b, "content"),
                        s(b, "resolution"), s(b, "redHeader"), s(b, "documentNumber")
                );
            } else {
                docx = wpsService.generate(
                        s(b, "redHeader"), s(b, "documentNumber"),
                        s(b, "title"), s(b, "recipient"), s(b, "body"),
                        s(b, "organization"), s(b, "date"),
                        s(b, "note"), s(b, "cc"), s(b, "printUnit"), s(b, "printDate"), s(b, "printCopies")
                );
            }
            HttpHeaders h = new HttpHeaders();
            h.setContentType(MediaType.parseMediaType(
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"));
            h.setContentDisposition(ContentDisposition.attachment().filename("document.docx").build());
            return ResponseEntity.ok().headers(h).body(docx);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    private static String s(Map<String, String> b, String k) {
        return b.getOrDefault(k, "");
    }
}
