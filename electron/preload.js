const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
  /** 保存 docx，返回 { ok, path } 或 { ok:false, canceled:true } 或 { ok:false, error } */
  saveDocx: (bytes, defaultName) => ipcRenderer.invoke('save-docx', bytes, defaultName),
  /** 监听启动进度消息（旧版兼容） */
  onStartupProgress: (callback) => ipcRenderer.on('startup-progress', (event, data) => callback(data)),
  /** 监听启动步骤初始化 */
  onStartupInit: (callback) => ipcRenderer.on('startup-init', (event, data) => callback(data)),
  /** 监听启动步骤更新 */
  onStartupStep: (callback) => ipcRenderer.on('startup-step', (event, data) => callback(data))
})
