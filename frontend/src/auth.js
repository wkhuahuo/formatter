import { reactive } from 'vue'
import { apiGet, apiPost } from './api.js'

export const auth = reactive({
  user: null,
  token: localStorage.getItem('token') || '',
  needsLogin: false,
  ready: false,

  get isLoggedIn() {
    return !!this.token && !!this.user
  },

  get isAdmin() {
    return this.user?.role === 'ADMIN'
  },

  requireLogin() {
    this.needsLogin = true
  },

  async checkAuth() {
    if (!this.token) {
      this.ready = true
      return
    }
    try {
      this.user = await apiGet('/auth/me')
    } catch {
      this.logout()
    } finally {
      this.ready = true
    }
  },

  async login(username, password) {
    const res = await apiPost('/auth/login', { username, password })
    this.token = res.token
    localStorage.setItem('token', res.token)
    this.user = { username: res.username, role: res.role }
    return res
  },

  async register(username, password) {
    return await apiPost('/auth/register', { username, password })
  },

  logout() {
    this.token = ''
    this.user = null
    localStorage.removeItem('token')
  }
})
