import { apiPost } from './api.js'

/**
 * 文档历史：把当前生成的 docx 保存到后端 SQLite，
 * 首页"最近文档"可随时重新下载，应用重启不丢失。
 */

function blobToBase64(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      // result 形如 data:application/...;base64,xxxx
      const idx = reader.result.indexOf(',')
      resolve(reader.result.slice(idx + 1))
    }
    reader.onerror = () => reject(new Error('读取文档内容失败'))
    reader.readAsDataURL(blob)
  })
}

/** 保存一条文档历史，返回后端记录 id */
export async function saveDocument(docType, title, fileName, blob) {
  const contentBase64 = await blobToBase64(blob)
  const res = await apiPost('/documents', { docType, title, fileName, contentBase64 })
  return res.id
}

/** 触发浏览器下载（Web 兜底） */
export function browserDownload(blob, fileName) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = fileName
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

/**
 * 统一保存入口：优先 Electron SaveDialog（返回保存路径），
 * 否则浏览器下载。返回 { via, path }，via = 'electron' | 'browser'
 */
export async function saveToFile(blob, fileName) {
  if (window.electronAPI && window.electronAPI.saveDocx) {
    const buf = await blob.arrayBuffer()
    const r = await window.electronAPI.saveDocx(new Uint8Array(buf), fileName)
    if (r && r.ok) return { via: 'electron', path: r.path }
    if (r && r.canceled) return { via: 'canceled' }
    // IPC 失败时继续走浏览器兜底
  }
  browserDownload(blob, fileName)
  return { via: 'browser' }
}

export function formatSize(bytes) {
  if (!bytes && bytes !== 0) return ''
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1024 / 1024).toFixed(1) + ' MB'
}
