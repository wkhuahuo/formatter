package com.latexonline.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/**
 * 生成文档的历史记录，docx 二进制随记录存入 SQLite，
 * 保证桌面版重启后仍可在"最近文档"中查看和重新下载。
 */
@Entity
@Table(name = "doc_record")
public class Document {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 归属用户（登录名） */
    @Column(nullable = false)
    private String username;

    /** redHeader / meetingMinutes */
    @Column(nullable = false)
    private String docType;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String fileName;

    @Column(nullable = false)
    private long sizeBytes;

    @Lob
    @Column(nullable = false, columnDefinition = "BLOB")
    private byte[] content;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Document() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getDocType() { return docType; }
    public void setDocType(String docType) { this.docType = docType; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public long getSizeBytes() { return sizeBytes; }
    public void setSizeBytes(long sizeBytes) { this.sizeBytes = sizeBytes; }
    public byte[] getContent() { return content; }
    public void setContent(byte[] content) { this.content = content; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
