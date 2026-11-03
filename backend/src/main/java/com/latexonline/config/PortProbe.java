package com.latexonline.config;

import org.springframework.boot.web.context.WebServerInitializedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 桌面版以 --server.port=0 启动（随机端口），Electron 主进程需要拿到真实端口。
 * 这里在 WebServer 就绪后向 stdout 打印一行 APP_PORT=<port>，供主进程解析。
 */
@Component
public class PortProbe {

    @EventListener(WebServerInitializedEvent.class)
    public void onWebServerReady(WebServerInitializedEvent event) {
        System.out.println("APP_PORT=" + event.getWebServer().getPort());
        System.out.flush();
    }
}
