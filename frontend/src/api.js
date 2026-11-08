import { auth } from './auth.js'

const BASE = '/api'

function getToken() {
  return localStorage.getItem('token')
}

async function request(path, options = {}) {
  const headers = { ...options.headers }
  if (options.body) {
    headers['Content-Type'] = 'application/json'
  }
  const token = getToken()
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }
  let res
  try {
    res = await fetch(BASE + path, { ...options, headers })
  } catch (e) {
    throw new Error('无法连接后端服务，请确认应用已正常启动')
  }
  const data = await res.json()
  if (!res.ok) {
    if (res.status === 401 || res.status === 403) {
      auth.requireLogin()
    }
    throw new Error(data.message || '请求失败')
  }
  return data
}

export function apiGet(path) {
  return request(path)
}

export function apiPost(path, body) {
  return request(path, { method: 'POST', body: JSON.stringify(body) })
}

export function apiPut(path, body) {
  const options = { method: 'PUT' }
  if (body !== undefined) {
    options.body = JSON.stringify(body)
  }
  return request(path, options)
}

export async function apiPostBlob(path, body) {
  const headers = { 'Content-Type': 'application/json' }
  const token = localStorage.getItem('token')
  if (token) headers['Authorization'] = `Bearer ${token}`

  let res
  try {
    res = await fetch(BASE + path, {
      method: 'POST',
      headers,
      body: JSON.stringify(body)
    })
  } catch (e) {
    throw new Error('无法连接后端服务，请确认应用已正常启动')
  }
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: '请求失败' }))
    if (res.status === 401 || res.status === 403) {
      auth.requireLogin()
    }
    throw new Error(err.message || err.error || '请求失败')
  }
  return res.blob()
}

export function apiDelete(path) {
  return request(path, { method: 'DELETE' })
}

export async function apiGetBlob(path) {
  const headers = {}
  const token = localStorage.getItem('token')
  if (token) headers['Authorization'] = `Bearer ${token}`

  let res
  try {
    res = await fetch(BASE + path, { headers })
  } catch (e) {
    throw new Error('无法连接后端服务，请确认应用已正常启动')
  }
  if (!res.ok) {
    if (res.status === 401 || res.status === 403) {
      auth.requireLogin()
    }
    throw new Error('下载失败')
  }
  return res.blob()
}
