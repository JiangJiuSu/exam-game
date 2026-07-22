<template>
  <div class="streak-display">
    <div class="streak-main">
      <span class="streak-icon">🔥</span>
      <div class="streak-info">
        <span class="streak-days">{{ streakStore.currentDays }}</span>
        <span class="streak-label">连续签到天数</span>
      </div>
    </div>

    <div class="streak-multiplier">
      <span class="multi-label">当前倍率</span>
      <span class="multi-value">×{{ streakStore.currentMultiplier.toFixed(1) }}</span>
    </div>

    <div class="streak-max">
      <span class="max-label">最长连续</span>
      <span class="max-value">{{ streakStore.maxDays }} 天</span>
    </div>

    <div class="streak-bar">
      <div
        class="streak-bar-fill"
        :style="{ width: Math.min(100, (streakStore.currentDays / 5) * 100) + '%' }"
      ></div>
      <span class="streak-bar-label">
        {{ streakStore.currentDays >= 5 ? '已满×1.5' : `还差${5 - streakStore.currentDays}天满倍率` }}
      </span>
    </div>
  </div>
</template>

<script setup>
import { useStreakStore } from '../stores/streakStore'

const streakStore = useStreakStore()
</script>

<style scoped>
.streak-display {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.streak-main {
  display: flex;
  align-items: center;
  gap: 16px;
}

.streak-icon {
  font-size: 48px;
}

.streak-info {
  display: flex;
  flex-direction: column;
}

.streak-days {
  font-size: 42px;
  font-weight: 800;
  color: #f97316;
  line-height: 1;
}

.streak-label {
  font-size: 14px;
  color: #888;
  margin-top: 4px;
}

.streak-multiplier {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 14px;
  background: #fef3c7;
  border-radius: 8px;
}

.multi-label {
  font-size: 13px;
  color: #92400e;
}

.multi-value {
  font-size: 20px;
  font-weight: 700;
  color: #f59e0b;
}

.streak-max {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.max-label {
  font-size: 13px;
  color: #999;
}

.max-value {
  font-size: 14px;
  font-weight: 600;
  color: #666;
}

.streak-bar {
  height: 8px;
  background: #e5e7eb;
  border-radius: 4px;
  position: relative;
  overflow: hidden;
}

.streak-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #f97316, #ef4444);
  border-radius: 4px;
  transition: width 0.5s ease;
}

.streak-bar-label {
  position: absolute;
  top: -18px;
  right: 0;
  font-size: 11px;
  color: #999;
}
</style>
