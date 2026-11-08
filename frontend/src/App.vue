<template>
  <div class="app-container">
    <header class="top-bar">
      <span class="app-name" @click="$router.push('/')">WPS 在线工具集</span>
      <div class="top-right">
        <template v-if="auth.isLoggedIn">
          <button v-if="auth.isAdmin" class="admin-btn" @click="showAdmin = true">用户管理</button>
          <span class="username">{{ auth.user?.username }}</span>
          <button class="auth-btn" @click="auth.logout()">退出</button>
        </template>
        <template v-else>
          <button class="auth-btn" @click="showLogin = true">登录</button>
        </template>
      </div>
    </header>
    <div class="main-content">
      <router-view />
    </div>
    <LoginModal :visible="showLogin" @close="onLoginClose" />
    <AdminPanel :visible="showAdmin" @close="showAdmin = false" />
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import LoginModal from './components/LoginModal.vue'
import AdminPanel from './components/AdminPanel.vue'
import { auth } from './auth.js'

const showLogin = ref(false)
const showAdmin = ref(false)

onMounted(async () => {
  await auth.checkAuth()
  // 不自动弹出登录框，允许未登录使用
  // if (!auth.isLoggedIn) {
  //   showLogin.value = true
  // }
})

watch(() => auth.needsLogin, (val) => {
  if (val) showLogin.value = true
})

function onLoginClose() {
  showLogin.value = false
  auth.needsLogin = false
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Noto Sans SC', sans-serif;
  background: #f0f2f5;
  color: #333;
}

/* ── 中文字体别名映射 ──
   docx-preview 将 .docx 中的字体名直接输出为 CSS font-family，
   但浏览器默认没有 "仿宋""楷体" 等字体。以下 @font-face 将
   文档字体名映射到 macOS / Windows 系统自带中文字体，保证预览
   与 Word/WPS 实际渲染效果一致。 */
@font-face {
  font-family: '仿宋';
  src: local('仿宋'), local('STFangsong'), local('FangSong'), local('华文仿宋'),
       local('Zhuque Fangsong (technical preview)'), local('朱雀仿宋（预览测试版）');
}
@font-face {
  font-family: '黑体';
  src: local('黑体'), local('Heiti SC'), local('SimHei'), local('STHeiti'),
       local('Noto Sans CJK SC'), local('Source Han Sans SC');
}
@font-face {
  font-family: '楷体';
  src: local('楷体'), local('Kaiti SC'), local('KaiTi'), local('STKaiti'),
       local('LXGW WenKai'), local('霞鹜文楷');
}
@font-face {
  font-family: '宋体';
  src: local('宋体'), local('Songti SC'), local('SimSun'), local('STSong'),
       local('Noto Serif CJK SC'), local('Source Han Serif SC');
}
@font-face {
  font-family: '方正小标宋简体';
  src: local('方正小标宋简体'), local('FZXiaoBiaoSong-B05S'),
       local('Songti SC'), local('SimSun'), local('STSong'), local('宋体'),
       local('Noto Serif CJK SC'), local('Source Han Serif SC');
}

.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.top-bar {
  height: 48px;
  background: #fff;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  flex-shrink: 0;
}

.app-name {
  font-size: 16px;
  font-weight: 700;
  color: #1a1a1a;
  cursor: pointer;
  transition: color 0.2s;
}

.app-name:hover {
  color: #4a90d9;
}

.top-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.username {
  font-size: 14px;
  color: #555;
}

.auth-btn {
  padding: 6px 16px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 5px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.auth-btn:hover {
  background: #357abd;
}

.admin-btn {
  padding: 6px 16px;
  background: #f5f5f5;
  color: #333;
  border: 1px solid #d0d0d0;
  border-radius: 5px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.admin-btn:hover {
  background: #e8e8e8;
}

.main-content {
  flex: 1;
}

@media (max-width: 600px) {
  .top-bar {
    padding: 0 12px;
  }

  .app-name {
    font-size: 14px;
  }

  .username {
    display: none;
  }

  .auth-btn,
  .admin-btn {
    font-size: 12px;
    padding: 5px 10px;
  }

  .top-right {
    gap: 8px;
  }
}
</style>
