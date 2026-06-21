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
  const res = await fetch(BASE + path, { ...options, headers })
  const data = await res.json()
  if (!res.ok) {
    if (res.status === 401 || res.status === 403) {
      import('./auth.js').then(m => m.auth.requireLogin())
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

  const res = await fetch(BASE + path, {
    method: 'POST',
    headers,
    body: JSON.stringify(body)
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: '请求失败' }))
    if (res.status === 401 || res.status === 403) {
      import('./auth.js').then(m => m.auth.requireLogin())
    }
    throw new Error(err.message || err.error || '请求失败')
  }
  return res.blob()
}
