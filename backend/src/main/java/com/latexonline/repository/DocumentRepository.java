package com.latexonline.repository;

import com.latexonline.entity.Document;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    List<Document> findByUsernameOrderByCreatedAtDesc(String username);

    Optional<Document> findByIdAndUsername(Long id, String username);
}
