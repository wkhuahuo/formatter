<template>
  <div class="editor-layout">
    <!-- Left: Form -->
    <div class="edit-panel">
      <h1 class="panel-title">会议纪要编辑</h1>

      <div class="section-title">红头</div>
      <div class="form-group">
        <label>红头单位</label>
        <input v-model="form.redHeader" type="text"
          placeholder="例如：沁雅花园第七届业主委员会会议纪要"
          @input="scheduleCompile" />
      </div>
      <div class="form-group">
        <label>文号</label>
        <input v-model="form.documentNumber" type="text"
          placeholder="例如：沁雅业委会〔2026〕5-2号"
          @input="scheduleCompile" />
      </div>

      <div class="section-divider"></div>

      <div class="section-title">标题</div>
      <div class="form-group">
        <label>会议标题</label>
        <input v-model="form.title" type="text"
          placeholder="例如：关于确认消防设计单位的会议纪要"
          @input="scheduleCompile" />
      </div>

      <div class="section-divider"></div>

      <div class="section-title">会议基本信息</div>
      <div class="form-group">
        <label>会议时间</label>
        <input v-model="form.meetingTime" type="text"
          placeholder="例如：2026年5月9日"
          @input="scheduleCompile" />
      </div>
      <div class="form-group">
        <label>会议地点</label>
        <input v-model="form.meetingLocation" type="text"
          placeholder="例如：沁雅花园19幢业委会办公室"
          @input="scheduleCompile" />
      </div>
      <div class="form-row">
        <div class="form-group">
          <label>主持人</label>
          <input v-model="form.host" type="text" placeholder="主持人姓名" @input="scheduleCompile" />
        </div>
        <div class="form-group">
          <label>记录人</label>
          <input v-model="form.recorder" type="text" placeholder="记录人姓名" @input="scheduleCompile" />
        </div>
      </div>
      <div class="form-group">
        <label>出席人员</label>
        <input v-model="form.attendees" type="text"
          placeholder="出席人员，以顿号分隔"
          @input="scheduleCompile" />
      </div>
      <div class="form-group">
        <label>列席人员</label>
        <input v-model="form.attendeesOther" type="text"
          placeholder="列席人员，以顿号分隔。不需要请留空"
          @input="scheduleCompile" />
      </div>

      <div class="section-divider"></div>

      <div class="section-title">会议议题</div>
      <div class="form-group">
        <label>议题内容</label>
        <textarea v-model="form.agenda" rows="3"
          placeholder="请输入会议议题，多个议题用换行分隔"
          @input="scheduleCompile"></textarea>
      </div>

      <div class="section-divider"></div>

      <div class="section-title">会议主要内容及议定事项</div>
      <div class="form-group">
        <label>主要内容</label>
        <textarea v-model="form.content" rows="10"
          placeholder="请输入会议主要内容和议定事项。段落之间用空行分隔。"
          @input="scheduleCompile"></textarea>
      </div>

      <div class="section-divider"></div>

      <div class="section-title">会议决议</div>
      <div class="form-group">
        <label>决议内容</label>
        <textarea v-model="form.resolution" rows="4"
          placeholder="请输入会议决议。段落之间用空行分隔。"
          @input="scheduleCompile"></textarea>
      </div>

      <button class="download-btn" @click="downloadDocx" :disabled="!docxReady">
        下载 .docx
      </button>
    </div>

    <!-- Right: Preview -->
    <div class="preview-panel">
      <div class="preview-header">
        <span>实时预览</span>
        <button
          class="download-btn-small"
          @click="downloadDocx"
          :disabled="!docxReady"
          v-show="docxReady"
        >下载 .docx</button>
      </div>
      <div class="preview-content">
        <div v-if="loading" class="preview-placeholder">
          <div class="spinner"></div>
          <p>正在生成文档...</p>
        </div>
        <div v-else-if="compileError" class="preview-placeholder error">
          <p>生成失败</p>
          <pre>{{ compileError }}</pre>
        </div>
        <div v-else-if="!docxReady" class="preview-placeholder">
          <p>填写内容后自动预览</p>
        </div>
        <div v-else ref="docxRenderer" class="docx-renderer"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, nextTick } from 'vue'
import { renderAsync } from 'docx-preview'
import { apiPostBlob } from '../api.js'

const form = reactive({
  templateType: 'meetingMinutes',
  redHeader: '沁雅花园第七届业主委员会会议纪要',
  documentNumber: '沁雅业委会〔2026〕5-2号',
  title: '关于确认消防设计单位的会议纪要',
  meetingTime: '2026年5月9日',
  meetingLocation: '沁雅花园19幢业委会办公室',
  host: '肖俊',
  recorder: '王锴',
  attendees: '肖俊、王建江、王锴、张月美、孙晓美',
  attendeesOther: '鲍伊凡、钱渭平',
  agenda: '商议聘用哪一家消防设计单位。',
  content: '消防问题是涉及安全的是沁雅花园小区亟待解决的重大问题。本次会议对有意愿承担沁雅花园消防改造工程的单位进行审议和决定。结合此前针对本小区消防问题的沟通以及接收到的两家单位资料，从设计单位资质、价格、经验三个方面进行评估择优评估。\n' +
    '本次一共收到了两份消防设计单位愿意承担沁雅花园消防设计工程：1、浙江南方建筑设计有限公司。2、华城博远工程技术集团有限公司。\n' +
    '\n' +
    '浙江南方建筑设计有限公司：总投资（暂定）200万元，专业系数1，复杂系数1，附加调整系数1.7，费率4.5%，优惠折扣0，设计费15.3万元，综合设计费率7.65。\n' +
    '\n' +
    '华城博远工程技术集团有限公司：总投资（暂定）260万元，专业系数1，复杂系数-，附加调整系数1.2，费率4.2%，优惠折扣0.8，设计费10.4832万元，综合设计费率4.032。\n' +
    '\n' +
    '考虑到后续工程预估与实际造价波动时仍需对设计费做相应调整，因此使用综合设计费率来评估实际哪家价格有优势。',
  resolution: '经过商议，决定选择华城博远工程技术集团有限公司作为本小区消防设计改造的设计单位。'
})

const docxReady = ref(false)
const loading = ref(false)
const compileError = ref('')
const docxRenderer = ref(null)

let debounceTimer = null
let docxBlob = null

function scheduleCompile() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(compile, 600)
}

function hasAnyContent() {
  return Object.values(form).some(v => v)
}

async function compile() {
  if (!hasAnyContent()) {
    docxReady.value = false
    docxBlob = null
    return
  }

  loading.value = true
  compileError.value = ''

  try {
    const blob = await apiPostBlob('/generate', form)
    docxBlob = blob
    docxReady.value = true
    loading.value = false

    await nextTick()
    if (docxRenderer.value) {
      docxRenderer.value.innerHTML = ''
      await renderAsync(blob, docxRenderer.value, undefined, {
        className: 'docx-preview-page',
        inWrapper: true,
        ignoreWidth: false,
        ignoreHeight: false,
        ignoreFonts: false,
        breakPages: true,
        ignoreLastRenderedPageBreak: true,
        trimXmlDeclaration: true,
        useBase64URL: false,
        renderChanges: false,
        renderHeaders: true,
        renderFooters: true,
        renderFootnotes: true,
        renderEndnotes: true,
      })
    }
  } catch (e) {
    compileError.value = e.message
    docxReady.value = false
    docxBlob = null
    loading.value = false
  }
}

function downloadDocx() {
  if (!docxBlob) return
  const url = URL.createObjectURL(docxBlob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'meeting-minutes.docx'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

compile()
</script>

<style scoped>
.editor-layout {
  display: flex;
  flex-wrap: wrap;
  min-height: calc(100vh - 48px);
}

.edit-panel {
  flex: 1 1 380px;
  min-width: 0;
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
  font-size: 13px;
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

.preview-panel {
  flex: 1 0 auto;
  display: flex;
  flex-direction: column;
  background: #e8e8e8;
  min-width: 300px;
}

.preview-header {
  padding: 10px 20px;
  background: #fff;
  border-bottom: 1px solid #e0e0e0;
  font-size: 14px;
  font-weight: 600;
  color: #555;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.download-btn-small {
  padding: 6px 16px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 5px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.download-btn-small:hover:not(:disabled) {
  background: #357abd;
}

.download-btn-small:disabled {
  background: #c0c0c0;
  cursor: not-allowed;
}

.preview-content {
  flex: 1;
  overflow: auto;
  position: relative;
}

.docx-renderer {
  min-height: 100%;
  padding: 20px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.preview-placeholder {
  text-align: center;
  color: #999;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
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

@media (max-width: 900px) {
  .editor-layout {
    flex-direction: column;
    min-height: auto;
  }

  .edit-panel {
    flex: 0 0 auto;
    border-right: none;
    border-bottom: 1px solid #e0e0e0;
    max-height: none;
  }

  .preview-panel {
    flex: 1 1 auto;
    min-height: 60vh;
  }

  .docx-renderer {
    padding: 12px;
  }
}

@media (max-width: 480px) {
  .edit-panel {
    padding: 16px;
    gap: 10px;
  }

  .panel-title {
    font-size: 17px;
  }

  .form-row {
    flex-direction: column;
  }

  .form-group input,
  .form-group textarea {
    padding: 8px 10px;
    font-size: 13px;
  }

  .download-btn {
    padding: 10px 16px;
    font-size: 14px;
  }

  .preview-header {
    padding: 8px 12px;
    font-size: 13px;
  }
}
</style>

<style>
.docx-preview-page {
  background: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  margin: 0 auto 20px auto;
  padding: 0;
  width: 210mm;
  max-width: 100%;
}

.docx-renderer .docx-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
