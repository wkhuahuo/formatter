<template>
  <div class="editor-layout">
    <!-- Left: Form -->
    <div class="edit-panel">
      <h1 class="panel-title">LaTeX 在线编辑系统</h1>

      <!-- 1. 红头 -->
      <div class="section-title">红头</div>
      <div class="form-group">
        <label>红头单位</label>
        <input v-model="form.redHeader" type="text"
          placeholder="例如：沁雅花园第七届业主委员会文件"
          @input="scheduleCompile" />
      </div>
      <div class="form-group">
        <label>文号</label>
        <input v-model="form.documentNumber" type="text"
          placeholder="例如：沁业委发〔2026〕1号"
          @input="scheduleCompile" />
      </div>

      <div class="section-divider"></div>

      <!-- 2. 标题 -->
      <div class="section-title">标题</div>
      <div class="form-group">
        <label>文档标题</label>
        <input v-model="form.title" type="text"
          placeholder="请输入文档标题"
          @input="scheduleCompile" />
      </div>

      <div class="section-divider"></div>

      <!-- 3. 正文 -->
      <div class="section-title">正文</div>
      <div class="form-group">
        <label>正文内容</label>
        <textarea v-model="form.body" rows="10"
          placeholder="请输入正文内容，段落之间用空行分隔"
          @input="scheduleCompile"></textarea>
      </div>

      <div class="section-divider"></div>

      <!-- 4. 落款 -->
      <div class="section-title">落款</div>
      <div class="form-row">
        <div class="form-group">
          <label>落款单位</label>
          <input v-model="form.organization" type="text"
            placeholder="单位名称"
            @input="scheduleCompile" />
        </div>
        <div class="form-group">
          <label>落款时间</label>
          <input v-model="form.date" type="text"
            placeholder="例如：2026年6月2日"
            @input="scheduleCompile" />
        </div>
      </div>

      <div class="section-divider"></div>

      <!-- 5. 抄送 -->
      <div class="section-title">抄送</div>
      <div class="form-group">
        <label>抄送单位</label>
        <input v-model="form.cc" type="text"
          placeholder="抄送单位，以逗号分隔"
          @input="scheduleCompile" />
      </div>

      <div class="section-divider"></div>

      <!-- 6. 印发 -->
      <div class="section-title">印发</div>
      <div class="form-row">
        <div class="form-group">
          <label>印发单位</label>
          <input v-model="form.printUnit" type="text"
            placeholder="印发单位名称"
            @input="scheduleCompile" />
        </div>
        <div class="form-group">
          <label>印发日期</label>
          <input v-model="form.printDate" type="text"
            placeholder="印发日期"
            @input="scheduleCompile" />
        </div>
      </div>
      <button class="download-btn" @click="downloadPdf" :disabled="!pdfReady">
        下载 PDF
      </button>
    </div>

    <!-- Right: Preview -->
    <div class="preview-panel">
      <div class="preview-header">PDF 实时预览</div>
      <div class="preview-content" ref="previewContainer">
        <div v-if="loading" class="preview-placeholder">
          <div class="spinner"></div>
          <p>正在编译...</p>
        </div>
        <div v-else-if="!pdfUrl" class="preview-placeholder">
          <p>填写内容后自动预览</p>
        </div>
        <div v-else-if="compileError" class="preview-placeholder error">
          <p>编译失败</p>
          <pre>{{ compileError }}</pre>
        </div>
        <iframe
          v-show="pdfUrl && !loading && !compileError"
          :src="pdfUrl"
          class="pdf-frame"
        ></iframe>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'

const form = reactive({
  redHeader: '沁雅花园第七届业主委员会文件',
  documentNumber: '沁雅业委会发〔2026〕31号',
  title: '关于沁雅花园地下室闲置空间物资存放服务的招租通告',
  body: '沁雅花园各位业主及物业使用人：\n\n为有效盘活小区公共资产，提高地下室利用率，根据《杭州市物业管理条例》及本小区《管理规约》相关规定，经杭州市西湖区沁雅花园第七届业主委员会研究决定，现对小区内闲置地下室空间（约25平方米）面向小区业主/物业使用人公开招租，用于物资存放服务。具体招租事宜通告如下：\n\n一、项目概况\n\n招租单位：杭州市西湖区沁雅花园第七届业主委员会。\n项目名称：沁雅花园地下室物资存放空间租赁项目。\n项目地点：沁雅花园小区地下室内（具体位置由业委会现场指定）。\n使用面积：约25平方米。\n功能定位：仅限用于存放非易燃易爆的物资。\n\n二、租赁期限\n\n租赁期限为1年（自2026年6月1日起至2027年5月31日止）。期满后，同等条件下原承租人享有优先承租权，具体视届时小区管理政策而定。\n\n三、报名资格及要求\n\n优先对象：沁雅花园小区业主或合法物业使用人。\n基本条件：报名人须具有完全民事行为能力，且无拖欠本小区物业服务费及公摊费用的记录。\n\n特此通告。',
  organization: '杭州市西湖区沁雅花园第七届业主委员会',
  date: '2026年5月17日',
  cc: '文新街道、沁雅社区',
  printUnit: '杭州市西湖区沁雅花园第七届业主委员会',
  printDate: '2026年5月17日',
  printCopies: ''
})

const pdfUrl = ref(null)
const pdfReady = ref(false)
const loading = ref(false)
const compileError = ref('')
const previewContainer = ref(null)

let debounceTimer = null

function scheduleCompile() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(compile, 600)
}

function hasAnyContent() {
  for (const v of Object.values(form)) {
    if (v) return true
  }
  return false
}

async function compile() {
  if (!hasAnyContent()) {
    pdfUrl.value = null
    pdfReady.value = false
    return
  }

  loading.value = true
  compileError.value = ''

  try {
    const res = await fetch('/api/compile', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form)
    })

    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.error || '编译失败')
    }

    const blob = await res.blob()
    if (pdfUrl.value) {
      URL.revokeObjectURL(pdfUrl.value)
    }
    pdfUrl.value = URL.createObjectURL(blob)
    pdfReady.value = true
  } catch (e) {
    compileError.value = e.message
    pdfReady.value = false
  } finally {
    loading.value = false
  }
}

function downloadPdf() {
  if (!pdfUrl.value) return
  const a = document.createElement('a')
  a.href = pdfUrl.value
  a.download = 'document.pdf'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
}
</script>

<style scoped>
.editor-layout {
  display: flex;
  height: 100vh;
}

/* --- Left Panel --- */
.edit-panel {
  width: 460px;
  min-width: 460px;
  padding: 24px;
  background: #fff;
  border-right: 1px solid #e0e0e0;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.panel-title {
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 4px;
}

.section-title {
  font-size: 11px;
  font-weight: 700;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.section-divider {
  height: 1px;
  background: #e8e8e8;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.form-group label {
  font-size: 13px;
  font-weight: 600;
  color: #555;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 9px 12px;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  font-size: 14px;
  font-family: inherit;
  transition: border-color 0.2s;
  resize: vertical;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #4a90d9;
  box-shadow: 0 0 0 3px rgba(74, 144, 217, 0.12);
}

.form-row {
  display: flex;
  gap: 12px;
}

.download-btn {
  padding: 12px 24px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
  margin-top: 4px;
}

.download-btn:hover:not(:disabled) {
  background: #357abd;
}

.download-btn:disabled {
  background: #c0c0c0;
  cursor: not-allowed;
}

/* --- Right Panel --- */
.preview-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #e8e8e8;
}

.preview-header {
  padding: 12px 20px;
  background: #fff;
  border-bottom: 1px solid #e0e0e0;
  font-size: 14px;
  font-weight: 600;
  color: #555;
}

.preview-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: auto;
}

.pdf-frame {
  width: 100%;
  height: 100%;
  border: none;
  background: #fff;
}

.preview-placeholder {
  text-align: center;
  color: #999;
}

.preview-placeholder p {
  margin-top: 12px;
}

.preview-placeholder.error {
  color: #d32f2f;
}

.preview-placeholder.error pre {
  margin-top: 8px;
  font-size: 12px;
  text-align: left;
  max-width: 460px;
  white-space: pre-wrap;
  word-break: break-all;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #e0e0e0;
  border-top-color: #4a90d9;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin: 0 auto;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
