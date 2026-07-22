<template>
  <div class="achievements-page fade-in">
    <h1 class="page-title">成就徽章</h1>

    <div class="achievement-stats">
      <div class="stat-item">
        <span class="stat-value">{{ unlockedCount }}</span>
        <span class="stat-label">已解锁</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ totalCount }}</span>
        <span class="stat-label">总成就</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ creditStore.totalHours }}h</span>
        <span class="stat-label">总学习时长</span>
      </div>
    </div>

    <div class="achievement-grid">
      <div
        v-for="achievement in allAchievements"
        :key="achievement.id"
        class="achievement-card"
        :class="{ unlocked: isUnlocked(achievement.id) }"
      >
        <span class="achievement-icon">{{ achievement.icon }}</span>
        <span class="achievement-name">{{ achievement.name }}</span>
        <span class="achievement-desc">{{ achievement.description }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useCreditStore } from '../stores/creditStore'
import { ACHIEVEMENTS } from '../utils/achievements'

const creditStore = useCreditStore()

const allAchievements = ACHIEVEMENTS
const isUnlocked = (id) => creditStore.achievements.includes(id)
const unlockedCount = computed(() => creditStore.achievements.length)
const totalCount = computed(() => ACHIEVEMENTS.length)
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 700; margin-bottom: 20px; color: #1e1e2e; }

.achievement-stats { display: flex; gap: 24px; margin-bottom: 24px; }
.stat-item { background: #fff; padding: 16px 24px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); text-align: center; }
.stat-value { font-size: 28px; font-weight: 700; color: #4f46e5; display: block; }
.stat-label { font-size: 13px; color: #999; }

.achievement-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; }

.achievement-card {
  background: #fff; padding: 20px; border-radius: 12px; text-align: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06); opacity: 0.4; filter: grayscale(1); transition: all 0.3s;
}
.achievement-card.unlocked { opacity: 1; filter: none; }
.achievement-icon { font-size: 36px; display: block; margin-bottom: 8px; }
.achievement-name { font-size: 14px; font-weight: 600; display: block; margin-bottom: 4px; }
.achievement-desc { font-size: 12px; color: #999; }
</style>
