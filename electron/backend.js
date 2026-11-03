/**
 * 后端（Spring Boot fat jar）子进程生命周期管理。
 *
 * 启动参数使用 --server.port=0 让系统分配随机端口，端口由后端打印的
 * APP_PORT=<port> 回传（见 com.latexonline.config.PortProbe），
 * 再用 /api/ping 探活，避免固定端口冲突。
 *
 * 前端资源不进 jar，而是用 --spring.web.resources.static-locations
 * 指向外部 webroot 目录，实现前后端同源（因此无需 CORS）。
 */
const fs = require('fs')
const path = require('path')
const http = require('http')
const { spawn, execSync } = require('child_process')

const START_TIMEOUT_MS = 60000

/** 把目录路径转成 Spring 能识别的 file: URL（斜杠 + 结尾斜杠） */
function toDirUrl(dir) {
  const p = dir.replace(/\\/g, '/')
  return 'file:' + (p.endsWith('/') ? p : p + '/')
}

function findJar(dir) {
  if (!fs.existsSync(dir)) return null
  const jar = fs
    .readdirSync(dir)
    .find((f) => f.endsWith('.jar') && !f.endsWith('-sources.jar') && !f.includes('.original'))
  return jar ? path.join(dir, jar) : null
}

function resolveJava(isPackaged) {
  if (isPackaged) {
    const exe = process.platform === 'win32' ? 'java.exe' : 'java'
    const bundled = path.join(process.resourcesPath, 'jre', 'bin', exe)
    // 捆绑运行时缺失时退回系统 java，保证 zip 解压后仍可能在装了 JDK 的机器上跑起来
    return fs.existsSync(bundled) ? bundled : exe
  }
  if (process.env.JAVA_HOME) {
    const exe = process.platform === 'win32' ? 'java.exe' : 'java'
    const fromHome = path.join(process.env.JAVA_HOME, 'bin', exe)
    if (fs.existsSync(fromHome)) return fromHome
  }
  return process.platform === 'win32' ? 'java.exe' : 'java'
}

/**
 * 解析各资源路径。
 * packaged: resources/backend/app.jar + resources/webroot + resources/jre
 * dev     : backend/target/*.jar     + frontend/dist    + 系统 java
 */
function resolveLayout(isPackaged) {
  const root = path.join(__dirname, '..')
  if (isPackaged) {
    const backendDir = path.join(process.resourcesPath, 'backend')
    // 固定名 app.jar 优先，缺失时退回目录内任意 jar（避免 pom 版本变动导致打包名不一致）
    const fixed = path.join(backendDir, 'app.jar')
    return {
      jar: fs.existsSync(fixed) ? fixed : findJar(backendDir),
      webroot: path.join(process.resourcesPath, 'webroot'),
      java: resolveJava(true)
    }
  }
  return {
    jar: findJar(path.join(root, 'backend', 'target')),
    webroot: path.join(root, 'frontend', 'dist'),
    java: resolveJava(false)
  }
}

/** 校验必需资源是否齐全，返回缺失项描述数组 */
function checkLayout(layout) {
  const missing = []
  if (!layout.jar || !fs.existsSync(layout.jar)) {
    missing.push('后端 jar：' + (layout.jar || '(未找到)') + '　→ 执行 mvn clean package')
  }
  if (!fs.existsSync(path.join(layout.webroot, 'index.html'))) {
    missing.push('前端资源：' + layout.webroot + '　→ 执行 npm run build（frontend）')
  }
  return missing
}

function ping(port) {
  return new Promise((resolve) => {
    const req = http.get(
      { host: '127.0.0.1', port, path: '/api/ping', timeout: 1000 },
      (res) => {
        res.resume()
        resolve(res.statusCode === 200)
      }
    )
    req.on('error', () => resolve(false))
    req.on('timeout', () => {
      req.destroy()
      resolve(false)
    })
  })
}

async function waitForPing(port) {
  for (let i = 0; i < 60; i++) {
    if (await ping(port)) return true
    await new Promise((r) => setTimeout(r, 500))
  }
  return false
}

/**
 * 启动后端，返回 { child, port }。
 * @param {object} layout resolveLayout() 的结果
 * @param {string} [logPath] 日志文件路径（打包模式写入 userData）
 */
function startBackend(layout, logPath) {
  return new Promise((resolve, reject) => {
    const args = [
      '-Dfile.encoding=UTF-8',
      '-jar',
      layout.jar,
      '--server.port=0',
      '--spring.main.banner-mode=off',
      '--spring.web.resources.static-locations=' + toDirUrl(layout.webroot)
    ]

    let logStream = null
    if (logPath) {
      try {
        fs.mkdirSync(path.dirname(logPath), { recursive: true })
        logStream = fs.createWriteStream(logPath, { flags: 'a' })
      } catch (_) {
        logStream = null
      }
    }

    const tail = []
    const collect = (chunk) => {
      const s = chunk.toString()
      tail.push(s)
      if (tail.length > 300) tail.shift()
      if (logStream) logStream.write(s)
    }

    const child = spawn(layout.java, args, {
      cwd: path.dirname(layout.jar),
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true
    })

    let settled = false
    const fail = (msg) => {
      if (settled) return
      settled = true
      clearTimeout(timer)
      reject(new Error(msg + '\n\n后端输出尾部：\n' + tail.slice(-60).join('')))
    }

    child.stdout.on('data', (d) => {
      collect(d)
      const m = d.toString().match(/APP_PORT=(\d+)/)
      if (m && !settled) {
        settled = true
        clearTimeout(timer)
        waitForPing(Number(m[1])).then((ok) => {
          if (ok) resolve({ child, port: Number(m[1]) })
          else fail('后端端口 ' + m[1] + ' 已分配但服务未就绪')
        }, (e) => fail(String(e)))
      }
    })
    child.stderr.on('data', collect)
    child.on('error', (e) => fail('无法启动 Java 进程（' + layout.java + '）：' + e.message))
    child.on('exit', (code, signal) => {
      if (!settled) fail('后端进程提前退出，code=' + code + ' signal=' + signal)
    })

    const timer = setTimeout(() => fail('后端启动超时（' + START_TIMEOUT_MS / 1000 + 's）'), START_TIMEOUT_MS)
  })
}

/** 优雅停止后端，Windows 下必要时用 taskkill 清理进程树 */
function stopBackend(child) {
  if (!child || child.exitCode !== null || child.signalCode !== null) {
    return Promise.resolve()
  }
  return new Promise((resolve) => {
    child.once('exit', resolve)
    child.kill()
    setTimeout(() => {
      if (child.exitCode === null && child.signalCode === null) {
        try {
          child.kill('SIGKILL')
        } catch (_) {
          /* noop */
        }
        if (process.platform === 'win32') {
          try {
            execSync('taskkill /pid ' + child.pid + ' /T /F', { stdio: 'ignore' })
          } catch (_) {
            /* noop */
          }
        }
      }
      setTimeout(resolve, 1500)
    }, 3000)
  })
}

module.exports = { resolveLayout, checkLayout, startBackend, stopBackend }
