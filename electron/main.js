const { app, BrowserWindow, ipcMain, dialog } = require('electron')
const fs = require('fs')
const path = require('path')

const { resolveLayout, checkLayout, startBackend, stopBackend } = require('./backend')

let backendChild = null
let quitting = false

// 启动步骤定义
const STARTUP_STEPS = [
  { id: 'init', label: '初始化应用' },
  { id: 'check', label: '检查运行环境' },
  { id: 'java', label: '启动 Java 运行时' },
  { id: 'engine', label: '启动文档引擎' },
  { id: 'editor', label: '加载编辑器界面' }
]

function createWindow() {
  const win = new BrowserWindow({
    width: 500,
    height: 450,
    minWidth: 450,
    minHeight: 400,
    show: true,  // 立即显示，让用户知道点击成功
    title: 'WPS 公文编辑器 - 启动中',
    backgroundColor: '#f0f2f5',
    resizable: false,
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

// 发送启动步骤更新到渲染进程
function sendStepUpdate(win, stepId, status, detail) {
  if (win && !win.isDestroyed()) {
    win.webContents.send('startup-step', { stepId, status, detail })
  }
}

async function bootstrap() {
  console.log('[Bootstrap] Starting...')
  const layout = resolveLayout(app.isPackaged)
  console.log('[Bootstrap] Layout:', layout)
  
  const win = createWindow()
  
  // 等待渲染进程加载完成
  await new Promise(resolve => {
    win.webContents.once('did-finish-load', resolve)
  })
  
  // 发送步骤列表到渲染进程
  win.webContents.send('startup-init', { steps: STARTUP_STEPS })
  
  // 步骤1: 初始化应用
  sendStepUpdate(win, 'init', 'running', '正在初始化...')
  await new Promise(r => setTimeout(r, 200))  // 短暂延迟让用户看到
  sendStepUpdate(win, 'init', 'done')
  
  // 步骤2: 检查运行环境
  sendStepUpdate(win, 'check', 'running', '检查必需的运行资源...')
  const missing = checkLayout(layout)
  console.log('[Bootstrap] Missing resources:', missing)
  
  if (missing.length) {
    sendStepUpdate(win, 'check', 'error', '缺少运行资源')
    console.error('[Bootstrap] Missing resources, showing error dialog')
    dialog.showErrorBox(
      '启动失败：缺少运行资源',
      '请先执行 ./scripts/build.sh 完成构建：\n\n- ' + missing.join('\n- ')
    )
    app.quit()
    return
  }
  sendStepUpdate(win, 'check', 'done')

  const logPath = app.isPackaged
    ? path.join(app.getPath('userData'), 'logs', 'backend.log')
    : null
  console.log('[Bootstrap] Log path:', logPath)

  try {
    // 步骤3: 启动 Java 运行时
    sendStepUpdate(win, 'java', 'running', '正在启动 Java 运行时...')
    
    // 步骤4: 启动文档引擎
    sendStepUpdate(win, 'engine', 'running', '正在启动文档引擎，请稍候...')
    console.log('[Bootstrap] Starting backend...')
    
    const { child, port } = await startBackend(layout, logPath)
    console.log('[Bootstrap] Backend started on port:', port)
    backendChild = child
    sendStepUpdate(win, 'java', 'done')
    sendStepUpdate(win, 'engine', 'done')
    
    // 步骤5: 加载编辑器界面
    sendStepUpdate(win, 'editor', 'running', '正在加载编辑器界面...')
    console.log('[Bootstrap] Loading frontend from:', 'http://127.0.0.1:' + port + '/')
    
    await win.loadURL('http://127.0.0.1:' + port + '/')
    console.log('[Bootstrap] Frontend loaded successfully')
    sendStepUpdate(win, 'editor', 'done')
    
    // 调整窗口大小为正常尺寸
    win.setResizable(true)
    win.setSize(1440, 900)
    win.setMinimumSize(1100, 700)
    win.center()
  } catch (e) {
    console.error('[Bootstrap] Backend startup failed:', e)
    // 根据错误阶段显示不同的错误
    sendStepUpdate(win, 'engine', 'error', '启动失败')
    dialog.showErrorBox('后端启动失败', String((e && e.message) || e))
    app.quit()
  }
}

app.whenReady().then(async () => {
  // 单实例锁：避免第二个实例再拉起一个后端抢资源
  const gotLock = app.requestSingleInstanceLock()
  if (!gotLock) {
    // 已有实例运行中，提示用户并退出
    dialog.showMessageBox({
      type: 'info',
      title: '提示',
      message: 'WPS 公文编辑器已在运行中',
      detail: '请检查任务栏或系统托盘，如需退出请先关闭已有窗口。'
    })
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
