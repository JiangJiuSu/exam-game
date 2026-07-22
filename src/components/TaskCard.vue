<template>
  <div class="task-card card" :class="[statusClass]">
    <div class="task-left">
      <span class="task-subject" :class="`subject-${task.subject}`">
        {{ subjectIcon }}
      </span>
      <div class="task-info">
        <span class="task-name" :class="{ 'line-through': task.status === 'completed' }">
          {{ task.name }}
        </span>
        <div class="task-meta">
          <span class="task-subject-label">{{ subjectLabel }}</span>
          <span v-if="task.plannedMinutes && task.status !== 'completed'" class="task-duration">
            ⏱️ 预定{{ task.plannedMinutes }}分钟
          </span>
          <span v-if="task.deadline && task.status === 'pending'" class="task-deadline">
            📅 {{ formatDeadline }}
          </span>
          <span v-if="task.status === 'overdue'" class="task-overdue-badge">已逾期</span>
          <span v-if="task.status === 'completed' && task.overdue" class="task-overdue-badge">超时完成</span>
        </div>
      </div>
    </div>

    <!-- 倒计时显示 -->
    <div v-if="task.status === 'running'" class="countdown-section">
      <span class="countdown-time" :class="{ urgent: remainingSeconds < 60 }">
        {{ formatCountdown }}
      </span>
      <div class="countdown-bar">
        <div
          class="countdown-bar-fill"
          :style="{ width: countdownPercent + '%' }"
          :class="{ urgent: remainingSeconds < 60 }"
        ></div>
      </div>
      <span class="countdown-label">
        剩余 / 预定{{ task.plannedMinutes }}分钟
      </span>
    </div>

    <!-- 管理员编辑真实时长 -->
    <div v-if="adminMode && task.status === 'completed' && isEditing" class="edit-section">
      <div class="edit-row">
        <label class="edit-label">真实时长(分钟)</label>
        <input
          v-model.number="editValue"
          type="number"
          class="edit-input"
          :class="{ 'edit-warning': editValue > task.plannedMinutes }"
          min="1"
        />
      </div>
      <div class="edit-hint" v-if="editValue > task.plannedMinutes">
        ⚠️ 超过预定时长{{ task.plannedMinutes }}分钟，将按超时处理（×70%）
      </div>
      <div class="edit-preview">
        预计有效时长: <strong>{{ previewEffective }}</strong> 分钟
      </div>
      <div class="edit-actions">
        <button class="btn btn-primary btn-xs" @click="saveEdit">保存</button>
        <button class="btn btn-ghost btn-xs" @click="cancelEdit">取消</button>
      </div>
    </div>

    <div class="task-right" v-else>
      <div class="task-reward">
        <template v-if="task.status === 'completed'">
          <span class="reward-effective">+{{ task.effectiveMinutes }}分钟</span>
          <span class="reward-unit">有效时长</span>
          <span class="reward-real">(真实{{ task.realMinutes }}分钟)</span>
        </template>
        <template v-else-if="task.status === 'overdue'">
          <span class="reward-deducted">逾期</span>
        </template>
        <template v-else>
          <span class="reward-potential">≈{{ task.plannedMinutes }}分钟</span>
          <span class="reward-unit">预定时长</span>
        </template>
      </div>

      <div class="task-actions">
        <button v-if="task.status === 'pending'" class="btn btn-primary btn-sm" @click="handleStart">
          开始任务
        </button>
        <button v-if="task.status === 'running'" class="btn btn-success btn-sm" @click="handleComplete">
          ✅ 完成
        </button>
        <button v-if="task.status === 'overdue'" class="btn btn-primary btn-sm" @click="handleCompleteOverdue">
          补完
        </button>
        <button v-if="adminMode && task.status === 'completed'" class="btn btn-warning btn-sm" @click="startEdit">
          ✏️ 编辑
        </button>
        <button v-if="adminMode && task.status === 'completed'" class="btn btn-ghost btn-sm" @click="handleUndo">
          ↩️ 撤销
        </button>
        <button class="btn btn-ghost btn-sm" @click="handleDelete">删除</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted, watch } from 'vue'
import { useTaskStore } from '../stores/taskStore'
import { useStreakStore } from '../stores/streakStore'
import { useCreditStore } from '../stores/creditStore'
import { checkAchievements } from '../utils/achievements'

const props = defineProps({
  task: Object,
  adminMode: { type: Boolean, default: false }
})

const taskStore = useTaskStore()
const streakStore = useStreakStore()
const creditStore = useCreditStore()

const remainingSeconds = ref(0)
let timerInterval = null

// 编辑模式
const isEditing = ref(false)
const editValue = ref(0)

const subjectMap = {
  english: { icon: '📘', label: '英语' },
  math: { icon: '📐', label: '数学' },
  politics: { icon: '📰', label: '政治' },
  major: { icon: '📖', label: '专业课' }
}

const subjectIcon = computed(() => subjectMap[props.task.subject]?.icon || '📋')
const subjectLabel = computed(() => subjectMap[props.task.subject]?.label || '')
const statusClass = computed(() => `status-${props.task.status}`)

const formatDeadline = computed(() => {
  if (!props.task.deadline) return ''
  const d = new Date(props.task.deadline)
  return `${d.getMonth() + 1}/${d.getDate()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
})

const countdownPercent = computed(() => {
  if (!props.task.plannedMinutes || !props.task.startedAt) return 0
  return Math.max(0, Math.min(100, (remainingSeconds.value / (props.task.plannedMinutes * 60)) * 100))
})

const formatCountdown = computed(() => {
  const mins = Math.floor(remainingSeconds.value / 60)
  const secs = Math.floor(remainingSeconds.value % 60)
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
})

// 预览编辑后的有效时长
const previewEffective = computed(() => {
  if (!editValue.value || editValue.value <= 0) return 0
  const isOverdue = editValue.value > props.task.plannedMinutes
  if (isOverdue) {
    return Math.max(1, Math.round(editValue.value * 0.7 * streakStore.currentMultiplier))
  } else {
    return Math.max(1, Math.round(editValue.value * streakStore.currentMultiplier))
  }
})

function updateCountdown() {
  if (props.task.status !== 'running' || !props.task.startedAt) {
    remainingSeconds.value = 0
    return
  }
  const elapsed = (Date.now() - new Date(props.task.startedAt).getTime()) / 1000
  remainingSeconds.value = Math.max(0, props.task.plannedMinutes * 60 - elapsed)
  if (remainingSeconds.value <= 0) {
    taskStore.markOverdue(props.task.id)
  }
}

function handleStart() {
  taskStore.startTask(props.task.id)
  startTimer()
}

function handleComplete() {
  taskStore.completeTask(props.task.id)
  checkAchievements(creditStore, streakStore)
  stopTimer()
}

function handleCompleteOverdue() {
  taskStore.completeOverdueTask(props.task.id)
  checkAchievements(creditStore, streakStore)
}

function handleUndo() {
  taskStore.undoTask(props.task.id)
}

function handleDelete() {
  taskStore.deleteTask(props.task.id)
  stopTimer()
}

function startEdit() {
  editValue.value = props.task.realMinutes
  isEditing.value = true
}

function cancelEdit() {
  isEditing.value = false
}

function saveEdit() {
  if (editValue.value <= 0) return
  taskStore.editRealMinutes(props.task.id, editValue.value)
  isEditing.value = false
}

function startTimer() {
  stopTimer()
  updateCountdown()
  timerInterval = setInterval(updateCountdown, 1000)
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

onMounted(() => { if (props.task.status === 'running') startTimer() })
onUnmounted(() => stopTimer())
watch(() => props.task.status, (s) => { if (s === 'running') startTimer(); else stopTimer() })
</script>

<style scoped>
.task-card { display: flex; justify-content: space-between; align-items: center; transition: all 0.2s; }
.task-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.task-card.status-overdue { border-left: 4px solid #ef4444; background: #fef2f2; }
.task-card.status-completed { opacity: 0.85; }
.task-card.status-running { border-left: 4px solid #10b981; background: #f0fdf4; }

.task-left { display: flex; align-items: center; gap: 14px; flex: 1; }
.task-subject { font-size: 28px; }
.task-name { font-size: 15px; font-weight: 600; display: block; }
.task-name.line-through { text-decoration: line-through; color: #999; }
.task-meta { display: flex; gap: 8px; margin-top: 4px; font-size: 12px; flex-wrap: wrap; }
.task-subject-label { color: #888; }
.task-duration { color: #4f46e5; font-weight: 500; }
.task-deadline { color: #888; }
.task-overdue-badge { color: #ef4444; font-weight: 600; background: #fee2e2; padding: 1px 6px; border-radius: 4px; font-size: 11px; }

/* 倒计时 */
.countdown-section { display: flex; flex-direction: column; align-items: center; gap: 4px; min-width: 140px; margin: 0 20px; }
.countdown-time { font-size: 28px; font-weight: 800; color: #10b981; font-variant-numeric: tabular-nums; }
.countdown-time.urgent { color: #ef4444; animation: pulse 0.5s infinite alternate; }
@keyframes pulse { from { opacity: 1; } to { opacity: 0.5; } }
.countdown-bar { width: 100%; height: 6px; background: #e5e7eb; border-radius: 3px; overflow: hidden; }
.countdown-bar-fill { height: 100%; background: #10b981; border-radius: 3px; transition: width 1s linear; }
.countdown-bar-fill.urgent { background: #ef4444; }
.countdown-label { font-size: 11px; color: #999; }

/* 编辑区域 */
.edit-section {
  display: flex; flex-direction: column; gap: 8px;
  min-width: 200px; margin: 0 16px; padding: 12px;
  background: #fffbeb; border-radius: 8px; border: 1px solid #fde68a;
}
.edit-row { display: flex; align-items: center; gap: 8px; }
.edit-label { font-size: 12px; color: #666; white-space: nowrap; }
.edit-input {
  width: 80px; padding: 4px 8px; border: 1px solid #ddd; border-radius: 6px;
  font-size: 14px; text-align: center;
}
.edit-input.edit-warning { border-color: #ef4444; background: #fef2f2; }
.edit-hint { font-size: 11px; color: #ef4444; }
.edit-preview { font-size: 12px; color: #666; }
.edit-actions { display: flex; gap: 6px; }

/* 右侧 */
.task-right { display: flex; align-items: center; gap: 16px; }
.task-reward { text-align: right; }
.reward-effective { font-size: 16px; font-weight: 700; color: #10b981; }
.reward-deducted { font-size: 14px; font-weight: 600; color: #ef4444; }
.reward-potential { font-size: 16px; font-weight: 700; color: #4f46e5; }
.reward-unit { font-size: 11px; color: #999; margin-left: 2px; display: block; }
.reward-real { font-size: 11px; color: #999; display: block; }

.task-actions { display: flex; gap: 6px; }
.btn-sm { padding: 6px 12px; font-size: 13px; }
.btn-xs { padding: 4px 10px; font-size: 12px; }
.btn-success { background: #10b981; color: #fff; }
.btn-success:hover { background: #059669; }
.btn-warning { background: #f59e0b; color: #fff; }
.btn-warning:hover { background: #d97706; }
</style>
