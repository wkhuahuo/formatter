package com.latexonline.service;

import com.latexonline.entity.User;
import com.latexonline.repository.UserRepository;
import com.latexonline.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public Map<String, Object> register(String username, String password) {
        if (userRepository.existsByUsername(username)) {
            return Map.of("success", false, "message", "用户名已存在");
        }
        User user = new User(username, passwordEncoder.encode(password), false);
        userRepository.save(user);
        return Map.of("success", true, "message", "注册成功，请等待管理员审批");
    }

    public Map<String, Object> login(String username, String password) {
        Optional<User> userOpt = userRepository.findByUsername(username);
        if (userOpt.isEmpty()) {
            return Map.of("success", false, "message", "用户名或密码错误");
        }
        User user = userOpt.get();
        if (!passwordEncoder.matches(password, user.getPassword())) {
            return Map.of("success", false, "message", "用户名或密码错误");
        }
        if (!user.isApproved()) {
            return Map.of("success", false, "message", "账号尚未通过审批，请等待管理员审批");
        }
        String token = jwtUtil.generateToken(user.getUsername(), user.getId());
        String role = user.getUsername().equals("admin") ? "ADMIN" : "USER";
        return Map.of("success", true, "token", token, "username", user.getUsername(), "role", role);
    }

    public Map<String, Object> me(User user) {
        String role = user.getUsername().equals("admin") ? "ADMIN" : (user.isApproved() ? "USER" : "PENDING");
        return Map.of("username", user.getUsername(), "approved", user.isApproved(), "role", role);
    }

    public Map<String, Object> listUsers() {
        List<Map<String, Object>> users = userRepository.findAll().stream()
                .map(u -> Map.<String, Object>of(
                        "id", u.getId(),
                        "username", u.getUsername(),
                        "approved", u.isApproved()))
                .toList();
        return Map.of("success", true, "users", users);
    }

    public Map<String, Object> approve(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return Map.of("success", false, "message", "用户不存在");
        }
        User user = userOpt.get();
        user.setApproved(true);
        userRepository.save(user);
        return Map.of("success", true, "message", "已通过用户 " + user.getUsername() + " 的审批");
    }
}
