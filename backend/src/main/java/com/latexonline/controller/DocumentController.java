package com.latexonline.controller;

import com.latexonline.entity.Document;
import com.latexonline.entity.User;
import com.latexonline.repository.DocumentRepository;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Map;

/**
 * 文档历史：用户点击下载时落库一条记录（含 docx 内容），
 * 供"最近文档"列表展示与重新下载，桌面版重启不丢失。
 */
@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    private static final MediaType DOCX = MediaType.parseMediaType(
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document");

    private final DocumentRepository documentRepository;

    public DocumentController(DocumentRepository documentRepository) {
        this.documentRepository = documentRepository;
    }

    @GetMapping
    public ResponseEntity<?> list(@AuthenticationPrincipal User user) {
        List<Map<String, Object>> items = documentRepository
                .findByUsernameOrderByCreatedAtDesc(user.getUsername())
                .stream()
                .map(d -> Map.<String, Object>of(
                        "id", d.getId(),
                        "docType", d.getDocType(),
                        "title", d.getTitle(),
                        "fileName", d.getFileName(),
                        "sizeBytes", d.getSizeBytes(),
                        "createdAt", d.getCreatedAt().toString()))
                .toList();
        return ResponseEntity.ok(Map.of("success", true, "documents", items));
    }

    @PostMapping
    public ResponseEntity<?> save(@AuthenticationPrincipal User user,
                                   @RequestBody Map<String, String> b) {
        String base64 = b.get("contentBase64");
        if (base64 == null || base64.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "文档内容为空"));
        }

        byte[] content;
        try {
            content = Base64.getDecoder().decode(base64);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "文档内容编码错误"));
        }

        String fileName = b.get("fileName");
        if (fileName == null || fileName.isBlank()) {
            fileName = "document.docx";
        }

        Document doc = new Document();
        doc.setUsername(user.getUsername());
        doc.setDocType(b.getOrDefault("docType", "redHeader"));
        doc.setTitle(orEmpty(b.get("title")));
        doc.setFileName(fileName);
        doc.setSizeBytes(content.length);
        doc.setContent(content);
        doc.setCreatedAt(LocalDateTime.now());

        Document saved = documentRepository.save(doc);
        return ResponseEntity.ok(Map.of("success", true, "id", saved.getId()));
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<byte[]> download(@AuthenticationPrincipal User user, @PathVariable Long id) {
        Document doc = documentRepository.findByIdAndUsername(id, user.getUsername()).orElse(null);
        if (doc == null) {
            return ResponseEntity.notFound().build();
        }
        String encoded = URLEncoder.encode(doc.getFileName(), StandardCharsets.UTF_8).replace("+", "%20");
        return ResponseEntity.ok()
                .contentType(DOCX)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encoded)
                .body(doc.getContent());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@AuthenticationPrincipal User user, @PathVariable Long id) {
        Document doc = documentRepository.findByIdAndUsername(id, user.getUsername()).orElse(null);
        if (doc == null) {
            return ResponseEntity.notFound().build();
        }
        documentRepository.delete(doc);
        return ResponseEntity.ok(Map.of("success", true));
    }

    private static String orEmpty(String s) {
        return s == null ? "" : s;
    }
}
