import { createRouter, createWebHistory } from 'vue-router'
import HomePage from './components/HomePage.vue'
import EditorPage from './components/EditorPage.vue'

const routes = [
  { path: '/', name: 'home', component: HomePage },
  { path: '/editor', name: 'editor', component: EditorPage },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to, from) => {
  const { auth } = await import('./auth.js')
  if (auth.ready && !auth.isLoggedIn) {
    auth.requireLogin()
    return false
  }
})

export default router
