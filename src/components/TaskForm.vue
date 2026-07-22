<template>
  <div class="task-form-overlay" @click.self="$emit('close')">
    <div class="task-form card pop-in">
      <h3 class="form-title">新建任务</h3>

      <div class="form-group">
        <label>任务名称 *</label>
        <input v-model="form.name" type="text" placeholder="例：背50个单词" />
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>所属学科 *</label>
          <select v-model="form.subject">
            <option value="">请选择</option>
            <option value="english">📘 英语</option>
            <option value="math">📐 数学</option>
            <option value="politics">📰 政治</option>
            <option value="major">📖 专业课</option>
          </select>
        </div>

        <div class="form-group">
          <label>预定时长（分钟）*</label>
          <input v-model.number="form.plannedMinutes" type="number" placeholder="30" min="1" />
        </div>
      </div>

      <!-- 任务模式 -->
      <div class="form-mode-toggle">
        <button
          class="mode-btn"
          :class="{ active: formMode === 'timer' }"
          @click="formMode = 'timer'"
        >⏱️ 倒计时模式</button>
        <button
          class="mode-btn"
          :class="{ active: formMode === 'deadline' }"
          @click="formMode = 'deadline'"
        >📅 截止日期模式</button>
      </div>

      <div v-if="formMode === 'timer'" class="form-group">
        <span class="form-hint-inline">
          开始任务后倒计时 {{ form.plannedMinutes || 30 }} 分钟，超时完成扣除30%有效时长
        </span>
      </div>

      <div v-else class="form-group">
        <label>截止时间</label>
        <input v-model="form.deadline" type="datetime-local" />
      </div>

      <div class="form-group">
        <label>备注（可选）</label>
        <textarea v-model="form.note" placeholder="补充说明..." rows="2"></textarea>
      </div>

      <div class="form-hint" v-if="form.plannedMinutes > 0">
        <span>按时完成可获得 </span>
        <strong>≈{{ form.plannedMinutes }}分钟</strong>
        <span> 有效时长（含倍率加成）</span>
      </div>

      <div class="form-actions">
        <button class="btn btn-ghost" @click="$emit('close')">取消</button>
        <button class="btn btn-primary" @click="submit" :disabled="!isValid">创建任务</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, computed, ref } from 'vue'
import { useTaskStore } from '../stores/taskStore'

const emit = defineEmits(['close'])
const taskStore = useTaskStore()

const formMode = ref('timer')

const form = reactive({
  name: '',
  subject: '',
  plannedMinutes: 30,
  deadline: '',
  note: ''
})

const isValid = computed(() => {
  if (!form.name.trim() || !form.subject) return false
  if (!form.plannedMinutes || form.plannedMinutes <= 0) return false
  if (formMode.value === 'deadline' && !form.deadline) return false
  return true
})

function submit() {
  if (!isValid.value) return

  taskStore.createTask({
    name: form.name.trim(),
    subject: form.subject,
    plannedMinutes: form.plannedMinutes,
    deadline: formMode.value === 'deadline' ? new Date(form.deadline).toISOString() : null,
    note: form.note.trim()
  })

  emit('close')
}
</script>

<style scoped>
.task-form-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.task-form {
  width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.form-title {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #555;
  margin-bottom: 6px;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
  font-family: inherit;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  border-color: #4f46e5;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-mode-toggle {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
}

.mode-btn {
  flex: 1;
  padding: 10px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  font-size: 13px;
  transition: all 0.2s;
}

.mode-btn.active {
  border-color: #4f46e5;
  background: #eef2ff;
  color: #4f46e5;
  font-weight: 600;
}

.form-hint-inline {
  display: block;
  font-size: 12px;
  color: #888;
  margin-top: 4px;
}

.form-hint {
  padding: 10px 14px;
  background: #eef2ff;
  border-radius: 8px;
  font-size: 13px;
  color: #4f46e5;
  margin-bottom: 20px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>
