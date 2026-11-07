import { createRouter, createWebHistory } from 'vue-router'
import HomePage from './components/HomePage.vue'
import EditorPage from './components/EditorPage.vue'
import MeetingMinutesPage from './components/MeetingMinutesPage.vue'

const routes = [
  { path: '/', name: 'home', component: HomePage },
  { path: '/editor', name: 'editor', component: EditorPage },
  { path: '/meeting-minutes', name: 'meetingMinutes', component: MeetingMinutesPage },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to, from) => {
  const { auth } = await import('./auth.js')
  // 允许未登录访问，不强制登录
  // if (auth.ready && !auth.isLoggedIn) {
  //   auth.requireLogin()
  //   return false
  // }
})

export default router
