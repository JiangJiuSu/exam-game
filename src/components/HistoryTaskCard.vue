<template>
  <div class="history-task-card" :class="[statusClass]">
    <div class="task-left">
      <span class="task-subject" :class="`subject-${task.subject}`">
        {{ subjectIcon }}
      </span>
      <div class="task-info">
        <span class="task-name">{{ task.name }}</span>
        <div class="task-meta">
          <span class="task-subject-label">{{ subjectLabel }}</span>
          <span class="task-time">{{ formatTime }}</span>
          <span v-if="task.status === 'completed'" class="task-effective">
            有效{{ task.effectiveMinutes }}分钟 (真实{{ task.realMinutes }}分钟)
          </span>
          <span v-if="task.overdue" class="task-overdue-badge">逾期</span>
        </div>
      </div>
    </div>

    <!-- 编辑模式 -->
    <div v-if="adminMode && isEditing" class="edit-section">
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
        ⚠️ 超过预定{{ task.plannedMinutes }}分钟，按超时处理(×70%)
      </div>
      <div class="edit-preview">有效时长: <strong>{{ previewEffective }}</strong>分钟</div>
      <div class="edit-actions">
        <button class="btn btn-primary btn-xs" @click="saveEdit">保存</button>
        <button class="btn btn-ghost btn-xs" @click="isEditing = false">取消</button>
      </div>
    </div>

    <div class="task-right" v-else>
      <div class="task-duration">
        <span v-if="task.status === 'completed'" class="duration-earned">
          +{{ task.effectiveMinutes }}分钟
        </span>
        <span v-else-if="task.status === 'overdue'" class="duration-overdue">逾期</span>
        <span v-else class="duration-pending">{{ task.plannedMinutes }}分钟</span>
      </div>

      <div class="task-actions">
        <button v-if="adminMode && task.status === 'completed'" class="btn btn-warning btn-xs" @click="startEdit">
          ✏️
        </button>
        <button v-if="adminMode && task.status === 'completed'" class="btn btn-ghost btn-xs" @click="handleUndo">
          ↩️
        </button>
        <button class="btn btn-ghost btn-xs" @click="handleDelete">🗑️</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useTaskStore } from '../stores/taskStore'
import { useCreditStore } from '../stores/creditStore'
import { useStreakStore } from '../stores/streakStore'

const props = defineProps({
  task: Object,
  adminMode: { type: Boolean, default: false }
})

const taskStore = useTaskStore()
const creditStore = useCreditStore()
const streakStore = useStreakStore()

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
const statusClass = computed(() => props.task.overdue ? 'status-overdue' : `status-${props.task.status}`)

const formatTime = computed(() => {
  const date = props.task.status === 'completed'
    ? new Date(props.task.completedAt)
    : new Date(props.task.createdAt)
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
})

const previewEffective = computed(() => {
  if (!editValue.value || editValue.value <= 0) return 0
  const isOverdue = editValue.value > props.task.plannedMinutes
  if (isOverdue) {
    return Math.max(1, Math.round(editValue.value * 0.7 * streakStore.currentMultiplier))
  }
  return Math.max(1, Math.round(editValue.value * streakStore.currentMultiplier))
})

function startEdit() {
  editValue.value = props.task.realMinutes
  isEditing.value = true
}

function saveEdit() {
  if (editValue.value <= 0) return
  taskStore.editRealMinutes(props.task.id, editValue.value)
  isEditing.value = false
}

function handleUndo() {
  taskStore.undoTask(props.task.id)
}

function handleDelete() {
  taskStore.deleteTask(props.task.id)
}
</script>

<style scoped>
.history-task-card {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 14px; border-radius: 8px; background: #f9fafb; transition: all 0.2s;
}
.history-task-card:hover { background: #f3f4f6; }
.history-task-card.status-overdue { background: #fef2f2; border-left: 3px solid #ef4444; }
.history-task-card.status-completed { background: #f0fdf4; border-left: 3px solid #10b981; }

.task-left { display: flex; align-items: center; gap: 10px; flex: 1; }
.task-subject { font-size: 22px; }
.task-name { font-size: 14px; font-weight: 500; display: block; }
.task-meta { display: flex; gap: 8px; margin-top: 2px; font-size: 11px; flex-wrap: wrap; }
.task-subject-label { color: #888; }
.task-time { color: #aaa; }
.task-effective { color: #10b981; font-weight: 500; }
.task-overdue-badge { color: #ef4444; font-weight: 600; background: #fee2e2; padding: 0 5px; border-radius: 3px; }

.task-right { display: flex; align-items: center; gap: 10px; }
.duration-earned { font-size: 14px; font-weight: 700; color: #10b981; }
.duration-overdue { font-size: 13px; font-weight: 600; color: #ef4444; }
.duration-pending { font-size: 13px; color: #888; }
.task-actions { display: flex; gap: 4px; }
.btn-xs { padding: 4px 8px; font-size: 12px; }
.btn-warning { background: #f59e0b; color: #fff; }
.btn-warning:hover { background: #d97706; }

.edit-section {
  display: flex; flex-direction: column; gap: 6px;
  min-width: 180px; padding: 10px; background: #fffbeb;
  border-radius: 8px; border: 1px solid #fde68a;
}
.edit-row { display: flex; align-items: center; gap: 6px; }
.edit-label { font-size: 11px; color: #666; white-space: nowrap; }
.edit-input { width: 70px; padding: 3px 6px; border: 1px solid #ddd; border-radius: 5px; font-size: 13px; text-align: center; }
.edit-input.edit-warning { border-color: #ef4444; background: #fef2f2; }
.edit-hint { font-size: 10px; color: #ef4444; }
.edit-preview { font-size: 11px; color: #666; }
.edit-actions { display: flex; gap: 4px; }
</style>
