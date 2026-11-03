const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
  /** 保存 docx，返回 { ok, path } 或 { ok:false, canceled:true } 或 { ok:false, error } */
  saveDocx: (bytes, defaultName) => ipcRenderer.invoke('save-docx', bytes, defaultName)
})
