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
  if (!auth.isLoggedIn) {
    showLogin.value = true
  }
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
