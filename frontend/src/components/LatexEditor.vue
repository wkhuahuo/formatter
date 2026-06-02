<template>
  <div class="editor-layout">
    <!-- Left: Form -->
    <div class="edit-panel">
      <h1 class="panel-title">LaTeX 在线编辑系统</h1>

      <div class="form-group">
        <label>标题</label>
        <input
          v-model="form.title"
          type="text"
          placeholder="请输入文档标题"
          @input="scheduleCompile"
        />
      </div>

      <div class="form-group">
        <label>正文</label>
        <textarea
          v-model="form.body"
          rows="14"
          placeholder="请输入正文内容，段落之间用空行分隔"
          @input="scheduleCompile"
        ></textarea>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>落款单位</label>
          <input
            v-model="form.organization"
            type="text"
            placeholder="单位名称"
            @input="scheduleCompile"
          />
        </div>
        <div class="form-group">
          <label>落款时间</label>
          <input
            v-model="form.date"
            type="text"
            placeholder="例如：2026年6月2日"
            @input="scheduleCompile"
          />
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
  title: '',
  body: '',
  organization: '',
  date: ''
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

async function compile() {
  // Don't compile if all fields are empty
  if (!form.title && !form.body && !form.organization && !form.date) {
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
  width: 420px;
  min-width: 420px;
  padding: 24px;
  background: #fff;
  border-right: 1px solid #e0e0e0;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.panel-title {
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 4px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #555;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 10px 12px;
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
  max-width: 500px;
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
