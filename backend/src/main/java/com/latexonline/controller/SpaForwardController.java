package com.latexonline.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * vue-router 使用 history 模式，桌面端（Electron）或浏览器在 /editor 等路径上
 * 刷新/重载时，请求会直接打到后端。后端没有对应资源会返回 404，
 * 这里把已知的前端路由转发到 index.html，交给前端路由接管。
 */
@Controller
public class SpaForwardController {

    @GetMapping({"/editor", "/meeting-minutes", "/admin", "/login"})
    public String forwardToIndex() {
        return "forward:/index.html";
    }
}
