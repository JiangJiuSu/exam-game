<template>
  <div class="school-progress">
    <div class="progress-header">
      <div class="progress-info">
        <h3 class="progress-title">🎯 目标：{{ creditStore.targetSchool.name }}</h3>
        <div class="progress-durations">
          <span class="duration-item">
            <span class="duration-label">真实学习</span>
            <span class="duration-value real">{{ creditStore.totalRealHours }}小时</span>
          </span>
          <span class="duration-divider">→</span>
          <span class="duration-item">
            <span class="duration-label">有效学习</span>
            <span class="duration-value effective">{{ creditStore.totalHours }}小时</span>
          </span>
          <span class="duration-item target">
            <span class="duration-label">目标</span>
            <span class="duration-value">{{ targetHours }}小时</span>
          </span>
        </div>
      </div>
      <span class="progress-percent" :class="percentClass">
        {{ creditStore.progressPercent }}%
      </span>
    </div>

    <div class="progress-bar-container">
      <div class="progress-bar" :style="{ width: creditStore.progressPercent + '%' }">
        <div class="progress-bar-glow"></div>
      </div>
    </div>

    <div class="progress-hint">
      <span v-if="creditStore.progressPercent < 100">
        还差 <strong>{{ remainingHours }}</strong> 小时达到目标
      </span>
      <span v-else class="goal-reached">
        🎉 恭喜！已达到目标学习时长！
      </span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useCreditStore } from '../stores/creditStore'

const creditStore = useCreditStore()

const targetHours = computed(() => {
  return (creditStore.targetSchool.requiredMinutes / 60).toFixed(0)
})

const remainingHours = computed(() => {
  const remaining = Math.max(0, creditStore.targetSchool.requiredMinutes - creditStore.totalMinutes)
  return (remaining / 60).toFixed(0)
})

const percentClass = computed(() => {
  const p = creditStore.progressPercent
  if (p >= 100) return 'gold'
  if (p >= 75) return 'green'
  if (p >= 50) return 'blue'
  return ''
})
</script>

<style scoped>
.school-progress { padding: 4px 0; }

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.progress-title { font-size: 20px; font-weight: 700; color: #1e1e2e; margin-bottom: 8px; }

.progress-durations {
  display: flex;
  align-items: center;
  gap: 12px;
}

.duration-item {
  display: flex;
  flex-direction: column;
}

.duration-label {
  font-size: 11px;
  color: #999;
  margin-bottom: 2px;
}

.duration-value {
  font-size: 18px;
  font-weight: 700;
  color: #333;
}

.duration-value.real { color: #6366f1; }
.duration-value.effective { color: #10b981; }

.duration-divider {
  font-size: 16px;
  color: #ccc;
  margin-top: 10px;
}

.duration-item.target .duration-value {
  color: #f59e0b;
}

.progress-percent { font-size: 32px; font-weight: 800; color: #4f46e5; }
.progress-percent.green { color: #10b981; }
.progress-percent.gold { color: #f59e0b; }

.progress-bar-container { height: 24px; background: #e5e7eb; border-radius: 12px; overflow: hidden; }

.progress-bar {
  height: 100%;
  background: linear-gradient(90deg, #4f46e5, #7c3aed);
  border-radius: 12px;
  transition: width 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  min-width: 2%;
}

.progress-bar-glow {
  position: absolute; right: 0; top: 0; bottom: 0; width: 40px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3));
  border-radius: 0 12px 12px 0;
}

.progress-hint { margin-top: 10px; font-size: 13px; color: #888; }
.goal-reached { color: #10b981; font-weight: 600; }
</style>
