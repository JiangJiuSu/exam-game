import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/', name: 'Dashboard', component: () => import('./views/Dashboard.vue') },
  { path: '/tasks', name: 'Tasks', component: () => import('./views/Tasks.vue') },
  { path: '/achievements', name: 'Achievements', component: () => import('./views/Achievements.vue') },
  { path: '/settings', name: 'Settings', component: () => import('./views/Settings.vue') }
]

export default createRouter({
  history: createWebHashHistory(),
  routes
})
