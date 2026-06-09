<template>
  <div v-if="visible" class="modal-overlay" @click.self="close">
    <div class="modal-box">
      <h2>{{ isRegister ? '注册' : '登录' }}</h2>

      <div class="form-group">
        <label>用户名</label>
        <input v-model="username" type="text" placeholder="请输入用户名" @keyup.enter="submit" />
      </div>
      <div class="form-group">
        <label>密码</label>
        <input v-model="password" type="password" placeholder="请输入密码" @keyup.enter="submit" />
      </div>
      <div v-if="isRegister" class="form-group">
        <label>确认密码</label>
        <input v-model="confirmPassword" type="password" placeholder="请再次输入密码" @keyup.enter="submit" />
      </div>

      <div v-if="error" class="error-msg">{{ error }}</div>
      <div v-if="success" class="success-msg">{{ success }}</div>

      <button class="submit-btn" @click="submit" :disabled="loading">
        {{ loading ? '处理中...' : (isRegister ? '提交注册' : '登录') }}
      </button>

      <div class="switch-link">
        <span v-if="!isRegister">
          没有账号？<a href="#" @click.prevent="switchToRegister">去注册</a>
        </span>
        <span v-else>
          已有账号？<a href="#" @click.prevent="switchToLogin">去登录</a>
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { auth } from '../auth.js'

const props = defineProps({
  visible: { type: Boolean, default: false }
})
const emit = defineEmits(['close'])

const isRegister = ref(false)
const username = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref('')
const success = ref('')

function close() {
  reset()
  emit('close')
}

function reset() {
  error.value = ''
  success.value = ''
  loading.value = false
}

function switchToRegister() {
  reset()
  isRegister.value = true
}

function switchToLogin() {
  reset()
  isRegister.value = false
}

async function submit() {
  error.value = ''
  success.value = ''

  if (!username.value.trim() || !password.value) {
    error.value = '请填写用户名和密码'
    return
  }
  if (isRegister.value && password.value !== confirmPassword.value) {
    error.value = '两次密码输入不一致'
    return
  }

  loading.value = true
  try {
    if (isRegister.value) {
      const res = await auth.register(username.value.trim(), password.value)
      success.value = res.message
      setTimeout(() => {
        switchToLogin()
      }, 1500)
    } else {
      await auth.login(username.value.trim(), password.value)
      close()
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-box {
  background: #fff;
  border-radius: 10px;
  padding: 32px 28px;
  width: 380px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.18);
}

.modal-box h2 {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 20px;
  text-align: center;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 14px;
}

.form-group label {
  font-size: 13px;
  font-weight: 600;
  color: #555;
}

.form-group input {
  width: 100%;
  padding: 9px 12px;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  font-size: 14px;
  font-family: inherit;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #4a90d9;
  box-shadow: 0 0 0 3px rgba(74, 144, 217, 0.12);
}

.error-msg {
  color: #d32f2f;
  font-size: 13px;
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #fdecea;
  border-radius: 6px;
}

.success-msg {
  color: #2e7d32;
  font-size: 13px;
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #e8f5e9;
  border-radius: 6px;
}

.submit-btn {
  width: 100%;
  padding: 10px 0;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.submit-btn:hover:not(:disabled) {
  background: #357abd;
}

.submit-btn:disabled {
  background: #c0c0c0;
  cursor: not-allowed;
}

.switch-link {
  text-align: center;
  margin-top: 14px;
  font-size: 13px;
  color: #888;
}

.switch-link a {
  color: #4a90d9;
  text-decoration: none;
  font-weight: 600;
}

.switch-link a:hover {
  text-decoration: underline;
}

@media (max-width: 480px) {
  .modal-box {
    width: calc(100vw - 32px);
    padding: 24px 20px;
    border-radius: 8px;
  }
}
</style>
