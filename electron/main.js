const { app, BrowserWindow, ipcMain, dialog } = require('electron')
const fs = require('fs')
const path = require('path')

const { resolveLayout, checkLayout, startBackend, stopBackend } = require('./backend')

let backendChild = null
let quitting = false

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1100,
    minHeight: 700,
    show: false,
    title: 'WPS 公文编辑器',
    backgroundColor: '#f0f2f5',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  })
  win.setMenuBarVisibility(false)
  win.loadFile(path.join(__dirname, 'splash.html'))
  return win
}

async function bootstrap() {
  const layout = resolveLayout(app.isPackaged)
  const missing = checkLayout(layout)

  const win = createWindow()

  if (missing.length) {
    win.show()
    dialog.showErrorBox(
      '启动失败：缺少运行资源',
      '请先执行 ./scripts/build.sh 完成构建：\n\n- ' + missing.join('\n- ')
    )
    app.quit()
    return
  }

  const logPath = app.isPackaged
    ? path.join(app.getPath('userData'), 'logs', 'backend.log')
    : null

  try {
    const { child, port } = await startBackend(layout, logPath)
    backendChild = child
    await win.loadURL('http://127.0.0.1:' + port + '/')
    win.show()
  } catch (e) {
    win.show()
    dialog.showErrorBox('后端启动失败', String((e && e.message) || e))
    app.quit()
  }
}

app.whenReady().then(async () => {
  // 单实例：避免第二个实例再拉起一个后端抢资源
  if (!app.requestSingleInstanceLock()) {
    app.quit()
    return
  }

  ipcMain.handle('save-docx', async (event, bytes, defaultName) => {
    const win = BrowserWindow.getFocusedWindow()
    const res = await dialog.showSaveDialog(win, {
      title: '保存公文',
      defaultPath: defaultName || 'document.docx',
      filters: [{ name: 'Word 文档', extensions: ['docx'] }]
    })
    if (res.canceled || !res.filePath) return { ok: false, canceled: true }
    try {
      await fs.promises.writeFile(res.filePath, Buffer.from(bytes))
      return { ok: true, path: res.filePath }
    } catch (e) {
      return { ok: false, error: String((e && e.message) || e) }
    }
  })

  await bootstrap()
})

app.on('second-instance', () => {
  const win = BrowserWindow.getAllWindows()[0]
  if (win) {
    if (win.isMinimized()) win.restore()
    win.focus()
  }
})

app.on('window-all-closed', () => {
  app.quit()
})

app.on('before-quit', (event) => {
  if (backendChild && !quitting) {
    event.preventDefault()
    quitting = true
    const child = backendChild
    backendChild = null
    stopBackend(child).then(() => app.quit())
  }
})

app.on('will-quit', () => {
  if (backendChild) {
    try {
      backendChild.kill()
    } catch (_) {
      /* noop */
    }
    backendChild = null
  }
})
