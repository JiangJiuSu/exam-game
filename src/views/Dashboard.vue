<template>
  <div class="dashboard fade-in">
    <h1 class="page-title">主面板</h1>

    <div class="dashboard-grid">
      <!-- 学校进度条 -->
      <div class="card progress-section">
        <SchoolProgress />
      </div>

      <!-- 连续签到 -->
      <div class="card streak-section">
        <StreakDisplay />
      </div>

      <!-- 热力图 -->
      <div class="card heatmap-section">
        <h3 class="section-title">学习日历</h3>
        <HeatMap />
      </div>

      <!-- 四科分布 -->
      <div class="card subject-section">
        <h3 class="section-title">学科分布</h3>
        <SubjectChart />
      </div>
    </div>
  </div>
</template>

<script setup>
import SchoolProgress from '../components/SchoolProgress.vue'
import StreakDisplay from '../components/StreakDisplay.vue'
import HeatMap from '../components/HeatMap.vue'
import SubjectChart from '../components/SubjectChart.vue'
</script>

<style scoped>
.page-title {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 20px;
  color: #1e1e2e;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: auto auto;
  gap: 20px;
}

.progress-section {
  grid-column: 1 / -1;
}

.heatmap-section {
  grid-column: 1 / -1;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 16px;
  color: #555;
}
</style>
