import { createApp } from 'vue'
import App from './App.vue'
import router from './router.js'
// 公文标准字体族名映射（宋体/仿宋/黑体/楷体），供 docx-preview 预览使用
import './styles/fonts.css'

const app = createApp(App)
app.use(router)
router.isReady().then(() => {
  app.mount('#app')
})
