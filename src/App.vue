<template>
  <div class="app-container">
    <Sidebar />
    <main class="main-content">
      <router-view />
    </main>

    <!-- 成就弹窗 -->
    <AchievementPopup
      v-if="currentAchievement"
      :achievement="currentAchievement"
      @close="nextAchievement"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import Sidebar from './components/Sidebar.vue'
import AchievementPopup from './components/AchievementPopup.vue'
import { initApp } from './utils/initApp'

const achievementQueue = ref([])
const currentAchievement = ref(null)

// 全局成就弹窗事件
window.showAchievement = (achievement) => {
  if (currentAchievement.value) {
    achievementQueue.value.push(achievement)
  } else {
    currentAchievement.value = achievement
  }
}

function nextAchievement() {
  if (achievementQueue.value.length > 0) {
    currentAchievement.value = achievementQueue.value.shift()
  } else {
    currentAchievement.value = null
  }
}

onMounted(() => {
  initApp()
})
</script>

<style scoped>
.app-container {
  display: flex;
  height: 100vh;
  background: #f5f7fa;
}

.main-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}
</style>
