<template>
  <div class="subject-chart-container" ref="chartRef"></div>
</template>

<script setup>
import { ref, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { useCreditStore } from '../stores/creditStore'

const creditStore = useCreditStore()
const chartRef = ref(null)
let chart = null

function initChart() {
  if (!chartRef.value) return
  chart = echarts.init(chartRef.value)
  updateChart()
}

function updateChart() {
  if (!chart) return

  const option = {
    radar: {
      indicator: [
        { name: '英语', max: getMaxValue() },
        { name: '数学', max: getMaxValue() },
        { name: '政治', max: getMaxValue() },
        { name: '专业课', max: getMaxValue() }
      ],
      shape: 'polygon',
      splitNumber: 4,
      axisName: { color: '#666', fontSize: 13 },
      splitArea: {
        areaStyle: { color: ['#f8f9fa', '#f1f3f5', '#e9ecef', '#dee2e6'] }
      }
    },
    series: [{
      type: 'radar',
      data: [{
        value: [
          creditStore.english,
          creditStore.math,
          creditStore.politics,
          creditStore.major
        ],
        name: '学习时长分布',
        areaStyle: { color: 'rgba(79, 70, 229, 0.2)' },
        lineStyle: { color: '#4f46e5', width: 2 },
        itemStyle: { color: '#4f46e5' }
      }]
    }],
    tooltip: {
      trigger: 'item',
      formatter: function(params) {
        const v = params.value
        return `英语: ${(v[0]/60).toFixed(1)}h<br/>数学: ${(v[1]/60).toFixed(1)}h<br/>政治: ${(v[2]/60).toFixed(1)}h<br/>专业课: ${(v[3]/60).toFixed(1)}h`
      }
    }
  }

  chart.setOption(option)
}

function getMaxValue() {
  const values = [creditStore.english, creditStore.math, creditStore.politics, creditStore.major]
  const max = Math.max(...values, 600)
  return Math.ceil(max / 600) * 600
}

onMounted(() => {
  initChart()
  window.addEventListener('resize', () => chart?.resize())
})

onUnmounted(() => chart?.dispose())

watch(() => [creditStore.english, creditStore.math, creditStore.politics, creditStore.major], () => updateChart())
</script>

<style scoped>
.subject-chart-container { width: 100%; height: 260px; }
</style>
