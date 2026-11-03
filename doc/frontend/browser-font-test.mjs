// 公文预览字体端到端实测脚本
//   用法：CHROME_PATH=/path/to/chrome-headless-shell BASE_URL=http://localhost:5174 \
//         OUT_DIR=/tmp node browser-font-test.mjs
//   依赖：frontend 下需能解析到 puppeteer-core（npm i --no-save puppeteer-core）
//   注意：chrome-headless-shell 可从 Chrome for Testing 下载
//         https://storage.googleapis.com/chrome-for-testing-public/<版本>/linux64/chrome-headless-shell-linux64.zip
import puppeteer from 'puppeteer-core'
import fs from 'node:fs'

const EXE = process.env.CHROME_PATH
const BASE = process.env.BASE_URL || 'http://localhost:5174'
const OUT = process.env.OUT_DIR || '.'
if (!EXE) { console.error('请通过 CHROME_PATH 指定 chrome-headless-shell 可执行文件'); process.exit(1) }

const log = (...a) => console.log(...a)
const sleep = ms => new Promise(r => setTimeout(r, ms))

const browser = await puppeteer.launch({
  executablePath: EXE,
  headless: 'shell',
  args: ['--no-sandbox', '--disable-dev-shm-usage', '--font-render-hinting=none'],
})

const page = await browser.newPage()
await page.setViewport({ width: 1600, height: 1100, deviceScaleFactor: 1 })

const fontNet = []
const consoleErrors = []
page.on('response', r => {
  const u = r.url()
  if (/\.(woff2?|ttf|otf)(\?|$)/.test(u)) fontNet.push({ url: u.replace(BASE, ''), status: r.status() })
})
page.on('requestfailed', r => {
  const u = r.url()
  if (/\.(woff2?|ttf|otf)(\?|$)/.test(u)) fontNet.push({ url: u.replace(BASE, ''), status: 'FAILED: ' + r.failure()?.errorText })
})
page.on('console', m => { if (m.type() === 'error') consoleErrors.push(m.text()) })
page.on('pageerror', e => consoleErrors.push('pageerror: ' + e.message))

// ── 1. 打开首页 ────────────────────────────────────────────────
await page.goto(BASE + '/', { waitUntil: 'networkidle2', timeout: 60000 })
await sleep(1000)
log('\n===== 1) 首页加载 =====')
log('  title:', await page.title())

// ── 2. 四个族名的 @font-face 是否被浏览器接受 ──────────────────
const faceInfo = await page.evaluate(async () => {
  const names = ['宋体', '仿宋', '黑体', '楷体']
  const out = []
  for (const n of names) {
    let loaded = false, err = null
    try { const r = await document.fonts.load(`16px "${n}"`, '公文测试'); loaded = r.length > 0 }
    catch (e) { err = String(e) }
    out.push({ name: n, loadReturned: loaded, check: document.fonts.check(`16px "${n}"`), err })
  }
  return out
})
log('\n===== 2) @font-face 加载结果 =====')
for (const f of faceInfo) log(`  ${f.name}: load()返回=${f.loadReturned} check()=${f.check}${f.err ? ' err=' + f.err : ''}`)

// ── 3. 字宽比对：自定义字体是否真的生效 ────────────────────────
// 注意：CJK 全角字在所有中文字体里宽度恒为 1em，测不出差异，
//       所以必须用含拉丁字母的串来区分字形来源。
const widthProbe = await page.evaluate(() => {
  const c = document.createElement('canvas').getContext('2d')
  const probes = {
    latin: 'Handgloves ABC abc 123',
    cjk: '沁雅花园第七届业主委员会',
    mixed: '2026年5月17日 Ag',
  }
  const fams = ['sans-serif', 'serif', '宋体', '仿宋', '黑体', '楷体']
  const out = {}
  for (const [pk, s] of Object.entries(probes)) {
    out[pk] = {}
    for (const f of fams) {
      c.font = `32px ${f.includes('-') ? f : `"${f}"`}`
      out[pk][f] = Math.round(c.measureText(s).width * 10) / 10
    }
  }
  return out
})
log('\n===== 3) canvas 测量宽度（px）=====')
for (const [pk, row] of Object.entries(widthProbe)) log(`  [${pk}] ` + JSON.stringify(row))

// ── 4. 登录拿 token ───────────────────────────────────────────
const login = await page.evaluate(async () => {
  const r = await fetch('/api/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'admin123' }),
  })
  const d = await r.json()
  if (d.token) localStorage.setItem('token', d.token)
  return { status: r.status, role: d.role, hasToken: !!d.token }
})
log('\n===== 4) 登录 =====')
log(' ', JSON.stringify(login))

// ── 5. 进编辑器，等 docx 渲染完成 ─────────────────────────────
await page.goto(BASE + '/editor', { waitUntil: 'networkidle2', timeout: 60000 })
await page.waitForSelector('.docx-renderer', { timeout: 60000 })
await page.waitForFunction(
  () => document.querySelector('.docx-renderer')?.innerText?.trim().length > 50,
  { timeout: 90000, polling: 500 },
)
await sleep(2500)

const rendered = await page.evaluate(() => {
  const root = document.querySelector('.docx-renderer')
  return root ? root.innerText.slice(0, 120) : null
})
log('\n===== 5) docx 预览渲染 =====')
log('  预览文本前 120 字:', JSON.stringify(rendered))

// ── 6. CDP：查某个节点实际用的字体 ────────────────────────────
const client = await page.createCDPSession()
await client.send('DOM.enable')
await client.send('CSS.enable')
const { root } = await client.send('DOM.getDocument', { depth: -1 })

async function platformFonts(selector, label) {
  try {
    const { nodeId } = await client.send('DOM.querySelector', { nodeId: root.nodeId, selector })
    if (!nodeId) return log(`  ${label.padEnd(18)} <未找到 ${selector}>`)
    const { fonts } = await client.send('CSS.getPlatformFontsForNode', { nodeId })
    const txt = await page.evaluate(s => document.querySelector(s)?.innerText?.slice(0, 18) ?? '', selector)
    const fam = await page.evaluate(s => getComputedStyle(document.querySelector(s)).fontFamily, selector)
    log(`  ${label.padEnd(18)} 实际字体=${JSON.stringify(fonts)} CSS族名=${fam} 文本=${JSON.stringify(txt)}`)
  } catch (e) {
    log(`  ${label}: CDP 调用失败 -> ${e.message}`)
  }
}

log('\n===== 6) 实际渲染字体（CDP CSS.getPlatformFontsForNode）=====')
const paraSel = await page.evaluate(() => {
  const root = document.querySelector('.docx-renderer')
  if (!root) return []
  const ps = [...root.querySelectorAll('p')]
  return ps.map((p, i) => {
    const t = (p.innerText || '').trim()
    return t ? { i, t: t.slice(0, 20) } : null
  }).filter(Boolean).slice(0, 8)
})
log('  预览里的段落:', JSON.stringify(paraSel, null, 0))

// 给前几个段落打上唯一 id，便于用 CSS 选择器定位
await page.evaluate(() => {
  const root = document.querySelector('.docx-renderer')
  ;[...root.querySelectorAll('p')].forEach((p, i) => p.setAttribute('data-pi', String(i)))
})
const paraCount = await page.evaluate(() => document.querySelectorAll('.docx-renderer p').length)
for (let i = 0; i < Math.min(paraCount, 8); i++) {
  await platformFonts(`.docx-renderer p[data-pi="${i}"]`, `p[${i}]`)
}

// ── 7. 字体网络请求 ───────────────────────────────────────────
log('\n===== 7) 字体文件网络请求 =====')
if (!fontNet.length) log('  (无字体请求)')
for (const f of fontNet) log(`  ${f.status}  ${f.url}`)

// ── 8. 截图 ───────────────────────────────────────────────────
fs.mkdirSync(OUT, { recursive: true })
await page.screenshot({ path: `${OUT}/editor.png`, fullPage: false })
// 只截预览区
const el = await page.$('.preview-panel')
if (el) await el.screenshot({ path: `${OUT}/preview.png` })
log('\n===== 8) 截图 =====')
log('  ' + OUT + '/editor.png')
log('  ' + OUT + '/preview.png')

log('\n===== 控制台错误 =====')
if (!consoleErrors.length) log('  (无)')
else consoleErrors.slice(0, 15).forEach(e => log('  ' + e))

await browser.close()
