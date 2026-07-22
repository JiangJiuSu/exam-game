<template>
  <aside class="sidebar">
    <div class="logo">
      <span class="logo-icon">📚</span>
      <span class="logo-text">考研游戏</span>
    </div>

    <nav class="nav">
      <router-link to="/" class="nav-item" :class="{ active: $route.path === '/' }">
        <span class="nav-icon">📊</span>
        <span class="nav-label">主面板</span>
      </router-link>
      <router-link to="/tasks" class="nav-item" :class="{ active: $route.path === '/tasks' }">
        <span class="nav-icon">📝</span>
        <span class="nav-label">任务管理</span>
      </router-link>
      <router-link to="/achievements" class="nav-item" :class="{ active: $route.path === '/achievements' }">
        <span class="nav-icon">🏆</span>
        <span class="nav-label">成就徽章</span>
      </router-link>
      <router-link to="/settings" class="nav-item" :class="{ active: $route.path === '/settings' }">
        <span class="nav-icon">⚙️</span>
        <span class="nav-label">设置</span>
      </router-link>
    </nav>

    <div class="streak-badge" v-if="streakStore.currentDays > 0">
      <span class="streak-fire">🔥</span>
      <span class="streak-count">{{ streakStore.currentDays }}天</span>
      <span class="streak-multi">×{{ streakStore.currentMultiplier }}</span>
    </div>
  </aside>
</template>

<script setup>
import { useStreakStore } from '../stores/streakStore'

const streakStore = useStreakStore()
</script>

<style scoped>
.sidebar {
  width: 200px;
  background: #1e1e2e;
  color: #cdd6f4;
  display: flex;
  flex-direction: column;
  padding: 20px 0;
  flex-shrink: 0;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 20px 24px;
  border-bottom: 1px solid #313244;
}

.logo-icon {
  font-size: 24px;
}

.logo-text {
  font-size: 18px;
  font-weight: 700;
  color: #fff;
}

.nav {
  flex: 1;
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 8px;
  text-decoration: none;
  color: #a6adc8;
  transition: all 0.2s;
}

.nav-item:hover {
  background: #313244;
  color: #cdd6f4;
}

.nav-item.active {
  background: #4f46e5;
  color: #fff;
}

.nav-icon {
  font-size: 18px;
}

.nav-label {
  font-size: 14px;
}

.streak-badge {
  margin: 12px 16px;
  padding: 12px;
  background: linear-gradient(135deg, #f97316, #ef4444);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}

.streak-fire {
  font-size: 20px;
}

.streak-count {
  font-size: 16px;
  font-weight: 700;
  color: #fff;
}

.streak-multi {
  font-size: 13px;
  color: #fde68a;
  font-weight: 600;
}
</style>
