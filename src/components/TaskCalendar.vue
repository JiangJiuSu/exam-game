<template>
  <div class="task-calendar">
    <!-- 月份导航 -->
    <div class="calendar-header">
      <button class="nav-btn" @click="prevMonth">◀</button>
      <span class="month-title">{{ currentYear }}年{{ currentMonth }}月</span>
      <button class="nav-btn" @click="nextMonth">▶</button>
    </div>

    <!-- 星期标题 -->
    <div class="calendar-weekdays">
      <span v-for="day in weekdays" :key="day">{{ day }}</span>
    </div>

    <!-- 日历网格 -->
    <div class="calendar-grid">
      <div
        v-for="(cell, index) in calendarCells"
        :key="index"
        class="calendar-cell"
        :class="{
          'empty': !cell.day,
          'today': cell.isToday,
          'selected': cell.isSelected,
          'has-tasks': cell.hasTasks,
          'has-completed': cell.hasCompleted,
          'has-overdue': cell.hasOverdue
        }"
        @click="cell.day && selectDate(cell.date)"
      >
        <span v-if="cell.day" class="cell-day">{{ cell.day }}</span>
        <div v-if="cell.hasTasks" class="cell-dots">
          <span v-if="cell.hasCompleted" class="dot dot-completed"></span>
          <span v-if="cell.hasOverdue" class="dot dot-overdue"></span>
          <span v-if="cell.hasPending" dot-pending class="dot"></span>
        </div>
      </div>
    </div>

    <!-- 选中日期的任务列表 -->
    <div v-if="selectedDate" class="selected-tasks">
      <div class="selected-header">
        <span class="selected-date">{{ formatSelectedDate }}</span>
        <span class="selected-count">{{ selectedTasks.length }}个任务</span>
      </div>

      <div v-if="selectedTasks.length === 0" class="no-tasks">
        当天没有任务记录
      </div>

      <div v-else class="task-list">
        <HistoryTaskCard
          v-for="task in selectedTasks"
          :key="task.id"
          :task="task"
          :adminMode="adminMode"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useTaskStore } from '../stores/taskStore'
import HistoryTaskCard from './HistoryTaskCard.vue'

const props = defineProps({
  adminMode: { type: Boolean, default: false }
})

const taskStore = useTaskStore()

const today = new Date()
const currentYear = ref(today.getFullYear())
const currentMonth = ref(today.getMonth() + 1)
const selectedDate = ref(null)

const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 获取某月的天数
function getDaysInMonth(year, month) {
  return new Date(year, month, 0).getDate()
}

// 获取某月第一天是星期几
function getFirstDayOfMonth(year, month) {
  return new Date(year, month - 1, 1).getDay()
}

// 日期转字符串 YYYY-MM-DD
function toDateStr(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

// 获取某天的任务统计
function getDayTaskInfo(dateStr) {
  const tasks = taskStore.tasks
  const dayTasks = tasks.filter(t => {
    const created = t.createdAt ? toDateStr(new Date(t.createdAt)) : null
    const completed = t.completedAt ? toDateStr(new Date(t.completedAt)) : null
    return created === dateStr || completed === dateStr
  })

  return {
    hasTasks: dayTasks.length > 0,
    hasCompleted: dayTasks.some(t => t.status === 'completed'),
    hasOverdue: dayTasks.some(t => t.status === 'overdue' || t.overdue),
    hasPending: dayTasks.some(t => t.status === 'pending' || t.status === 'running'),
    count: dayTasks.length
  }
}

// 日历单元格数据
const calendarCells = computed(() => {
  const cells = []
  const daysInMonth = getDaysInMonth(currentYear.value, currentMonth.value)
  const firstDay = getFirstDayOfMonth(currentYear.value, currentMonth.value)

  // 填充前置空白
  for (let i = 0; i < firstDay; i++) {
    cells.push({ day: null })
  }

  // 填充日期
  const todayStr = toDateStr(today)
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${currentYear.value}-${String(currentMonth.value).padStart(2, '0')}-${String(d).padStart(2, '0')}`
    const info = getDayTaskInfo(dateStr)

    cells.push({
      day: d,
      date: dateStr,
      isToday: dateStr === todayStr,
      isSelected: dateStr === selectedDate.value,
      ...info
    })
  }

  return cells
})

// 选中日期的任务
const selectedTasks = computed(() => {
  if (!selectedDate.value) return []

  return taskStore.tasks.filter(t => {
    const created = t.createdAt ? toDateStr(new Date(t.createdAt)) : null
    const completed = t.completedAt ? toDateStr(new Date(t.completedAt)) : null
    return created === selectedDate.value || completed === selectedDate.value
  }).sort((a, b) => {
    // 已完成的排前面
    if (a.status === 'completed' && b.status !== 'completed') return -1
    if (b.status === 'completed' && a.status !== 'completed') return 1
    // 逾期的排后面
    if (a.status === 'overdue' && b.status !== 'overdue') return 1
    if (b.status === 'overdue' && a.status !== 'overdue') return -1
    return 0
  })
})

const formatSelectedDate = computed(() => {
  if (!selectedDate.value) return ''
  const [y, m, d] = selectedDate.value.split('-')
  return `${y}年${parseInt(m)}月${parseInt(d)}日`
})

function prevMonth() {
  if (currentMonth.value === 1) {
    currentMonth.value = 12
    currentYear.value--
  } else {
    currentMonth.value--
  }
}

function nextMonth() {
  if (currentMonth.value === 12) {
    currentMonth.value = 1
    currentYear.value++
  } else {
    currentMonth.value++
  }
}

function selectDate(dateStr) {
  selectedDate.value = selectedDate.value === dateStr ? null : dateStr
}
</script>

<style scoped>
.task-calendar {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.nav-btn {
  background: none;
  border: none;
  font-size: 18px;
  cursor: pointer;
  padding: 4px 12px;
  border-radius: 6px;
  transition: background 0.2s;
}
.nav-btn:hover { background: #f3f4f6; }

.month-title {
  font-size: 16px;
  font-weight: 600;
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  text-align: center;
  margin-bottom: 8px;
}

.calendar-weekdays span {
  font-size: 12px;
  color: #999;
  padding: 4px 0;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
}

.calendar-cell {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
  position: relative;
}

.calendar-cell:not(.empty):hover {
  background: #f3f4f6;
}

.calendar-cell.today {
  background: #eef2ff;
  font-weight: 700;
}

.calendar-cell.selected {
  background: #4f46e5;
  color: #fff;
}

.calendar-cell.selected .cell-dots .dot {
  background: #fff;
}

.cell-day {
  font-size: 13px;
}

.cell-dots {
  display: flex;
  gap: 3px;
  margin-top: 2px;
}

.dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #d1d5db;
}

.dot-completed { background: #10b981; }
.dot-overdue { background: #ef4444; }

/* 选中日期的任务列表 */
.selected-tasks {
  margin-top: 20px;
  border-top: 1px solid #e5e7eb;
  padding-top: 16px;
}

.selected-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.selected-date {
  font-size: 15px;
  font-weight: 600;
}

.selected-count {
  font-size: 13px;
  color: #999;
}

.no-tasks {
  text-align: center;
  padding: 24px;
  color: #ccc;
  font-size: 13px;
}

.task-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>
