<template>
  <div class="heatmap-container" ref="chartRef"></div>
</template>

<script setup>
import { ref, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { useCreditStore } from '../stores/creditStore'

const creditStore = useCreditStore()
const chartRef = ref(null)
let chart = null

function getHeatmapData() {
  const data = []
  const log = creditStore.dailyLog
  for (const [date, info] of Object.entries(log)) {
    data.push([date, info.totalMinutes || 0])
  }
  return data
}

function getLast52Weeks() {
  const dates = []
  const today = new Date()
  const dayOfWeek = today.getDay()
  const endDate = new Date(today)
  endDate.setDate(today.getDate() - dayOfWeek)

  for (let i = 51; i >= 0; i--) {
    for (let j = 0; j < 7; j++) {
      const d = new Date(endDate)
      d.setDate(endDate.getDate() - (i * 7 + j))
      if (d <= today) {
        dates.push(d.toISOString().split('T')[0])
      }
    }
  }
  return dates
}

function initChart() {
  if (!chartRef.value) return
  chart = echarts.init(chartRef.value)
  updateChart()
}

function updateChart() {
  if (!chart) return

  const data = getHeatmapData()
  const dataMap = {}
  data.forEach(([date, value]) => { dataMap[date] = value })

  const weeks = getLast52Weeks()
  const heatmapData = weeks.map((date, index) => {
    const weekIndex = Math.floor(index / 7)
    const dayIndex = index % 7
    return [weekIndex, dayIndex, dataMap[date] || 0]
  })

  const option = {
    tooltip: {
      formatter: function (params) {
        const weekIndex = params.data[0]
        const dayIndex = params.data[1]
        const idx = weekIndex * 7 + dayIndex
        const date = weeks[idx] || ''
        const minutes = params.data[2]
        const hours = (minutes / 60).toFixed(1)
        return `${date}<br/>学习时长: ${hours}小时 (${minutes}分钟)`
      }
    },
    visualMap: {
      min: 0,
      max: 300,
      show: false,
      inRange: {
        color: ['#ebedf0', '#c6e48b', '#7bc96f', '#239a3b', '#196127']
      }
    },
    calendar: {
      top: 20, left: 40, right: 10, bottom: 10,
      cellSize: [14, 14],
      range: [weeks[0], weeks[weeks.length - 1]],
      itemStyle: { borderWidth: 3, borderColor: '#fff' },
      yearLabel: { show: false },
      monthLabel: { fontSize: 11, color: '#999' },
      dayLabel: {
        firstDay: 0, fontSize: 10, color: '#999',
        nameMap: ['日', '一', '二', '三', '四', '五', '六']
      }
    },
    series: [{
      type: 'heatmap',
      coordinateSystem: 'calendar',
      data: heatmapData
    }]
  }

  chart.setOption(option)
}

onMounted(() => {
  initChart()
  window.addEventListener('resize', () => chart?.resize())
})

onUnmounted(() => chart?.dispose())

watch(() => creditStore.dailyLog, () => updateChart(), { deep: true })
</script>

<style scoped>
.heatmap-container { width: 100%; height: 160px; }
</style>
