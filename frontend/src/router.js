import { createRouter, createWebHistory } from 'vue-router'
import HomePage from './components/HomePage.vue'
import EditorPage from './components/EditorPage.vue'

const routes = [
  { path: '/', name: 'home', component: HomePage },
  { path: '/editor', name: 'editor', component: EditorPage },
]

export default createRouter({
  history: createWebHistory(),
  routes,
})
