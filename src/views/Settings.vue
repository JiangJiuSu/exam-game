<template>
  <div class="settings-page fade-in">
    <h1 class="page-title">设置</h1>

    <div class="card settings-section">
      <h3 class="section-title">🎯 目标学校</h3>
      <p class="section-desc">选择你的目标院校，系统将显示学习进度</p>
      <div class="school-options">
        <div
          v-for="school in schools"
          :key="school.name"
          class="school-option"
          :class="{ active: selectedSchool === school.name }"
          @click="selectSchool(school)"
        >
          <span class="school-name">{{ school.name }}</span>
          <span class="school-hours">{{ (school.requiredMinutes / 60).toFixed(0) }}小时</span>
        </div>
      </div>
    </div>

    <div class="card settings-section">
      <h3 class="section-title">✏️ 自定义目标</h3>
      <div class="custom-form">
        <div class="form-group">
          <label>学校名称</label>
          <input v-model="customName" type="text" placeholder="例：复旦大学" />
        </div>
        <div class="form-group">
          <label>所需学习时长（小时）</label>
          <input v-model.number="customHours" type="number" placeholder="1500" />
        </div>
        <button class="btn btn-primary" @click="saveCustom">保存自定义</button>
      </div>
    </div>

    <div class="card settings-section">
      <h3 class="section-title">📊 当前学习数据</h3>
      <div class="stats-grid">
        <div class="stat-item">
          <span class="stat-value">{{ creditStore.totalHours }}h</span>
          <span class="stat-label">总学习时长</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">{{ creditStore.totalMinutes }}</span>
          <span class="stat-label">总学习分钟</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">{{ creditStore.progressPercent }}%</span>
          <span class="stat-label">目标进度</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">{{ taskCount }}</span>
          <span class="stat-label">总任务数</span>
        </div>
      </div>
    </div>

    <div class="card settings-section">
      <h3 class="section-title">💾 数据管理</h3>
      <p class="section-desc">数据存储在本地，建议定期导出备份</p>

      <div class="data-actions">
        <div class="data-action">
          <div class="action-info">
            <span class="action-icon">📤</span>
            <div>
              <span class="action-title">导出数据</span>
              <span class="action-desc">将所有学习数据导出为 JSON 文件</span>
            </div>
          </div>
          <button class="btn btn-primary" @click="handleExport">导出</button>
        </div>

        <div class="data-action">
          <div class="action-info">
            <span class="action-icon">📥</span>
            <div>
              <span class="action-title">导入数据</span>
              <span class="action-desc">从 JSON 文件恢复学习数据（会先自动备份当前数据）</span>
            </div>
          </div>
          <button class="btn btn-ghost" @click="triggerImport">导入</button>
          <input
            ref="fileInput"
            type="file"
            accept=".json"
            style="display: none"
            @change="handleImport"
          />
        </div>

        <div class="data-action">
          <div class="action-info">
            <span class="action-icon">💾</span>
            <div>
              <span class="action-title">手动备份</span>
              <span class="action-desc">立即创建一份数据备份</span>
            </div>
          </div>
          <button class="btn btn-ghost" @click="handleBackup">备份</button>
        </div>
      </div>

      <div v-if="statusMessage" class="status-message" :class="statusType">
        {{ statusMessage }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useCreditStore } from '../stores/creditStore'
import { useTaskStore } from '../stores/taskStore'
import { exportData, importData, createBackup } from '../utils/dataPersistence'
import { saveAllData } from '../utils/initApp'

const creditStore = useCreditStore()
const taskStore = useTaskStore()

const schools = [
  { name: '普通院校', requiredMinutes: 0 },
  { name: '211', requiredMinutes: 300000 },
  { name: '985', requiredMinutes: 900000 },
  { name: '顶尖985', requiredMinutes: 1800000 }
]

const selectedSchool = ref(creditStore.targetSchool.name)
const customName = ref('')
const customHours = ref(null)
const fileInput = ref(null)
const statusMessage = ref('')
const statusType = ref('success')

const taskCount = computed(() => taskStore.tasks.length)

function selectSchool(school) {
  selectedSchool.value = school.name
  creditStore.setTargetSchool(school)
}

function saveCustom() {
  if (customName.value && customHours.value > 0) {
    const minutes = customHours.value * 60
    creditStore.setTargetSchool({ name: customName.value, requiredMinutes: minutes })
    selectedSchool.value = customName.value
    customName.value = ''
    customHours.value = null
  }
}

function showStatus(msg, type = 'success') {
  statusMessage.value = msg
  statusType.value = type
  setTimeout(() => { statusMessage.value = '' }, 3000)
}

async function handleExport() {
  try {
    await saveAllData()
    await exportData()
    showStatus('✅ 数据已导出', 'success')
  } catch (e) {
    showStatus('❌ 导出失败: ' + e.message, 'error')
  }
}

function triggerImport() {
  fileInput.value.click()
}

async function handleImport(e) {
  const file = e.target.files[0]
  if (!file) return
  try {
    await importData(file)
    showStatus('✅ 数据已导入，请刷新页面', 'success')
  } catch (err) {
    showStatus('❌ 导入失败: ' + err.message, 'error')
  }
  // 清除 input 值，允许重复选择同一文件
  e.target.value = ''
}

async function handleBackup() {
  try {
    await saveAllData()
    await createBackup()
    showStatus('✅ 备份已创建', 'success')
  } catch (e) {
    showStatus('❌ 备份失败: ' + e.message, 'error')
  }
}
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 700; margin-bottom: 20px; color: #1e1e2e; }
.settings-section { margin-bottom: 20px; }
.section-title { font-size: 16px; font-weight: 600; margin-bottom: 8px; color: #555; }
.section-desc { font-size: 13px; color: #999; margin-bottom: 16px; }

.school-options { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.school-option {
  padding: 16px; border: 2px solid #e5e7eb; border-radius: 10px;
  text-align: center; cursor: pointer; transition: all 0.2s;
}
.school-option:hover { border-color: #a5b4fc; }
.school-option.active { border-color: #4f46e5; background: #eef2ff; }
.school-name { display: block; font-weight: 600; margin-bottom: 4px; }
.school-hours { font-size: 13px; color: #999; }

.custom-form { display: flex; gap: 16px; align-items: flex-end; }
.form-group { flex: 1; }
.form-group label { display: block; font-size: 13px; color: #666; margin-bottom: 6px; }
.form-group input {
  width: 100%; padding: 10px 12px; border: 1px solid #ddd; border-radius: 8px;
  font-size: 14px; outline: none; transition: border-color 0.2s;
}
.form-group input:focus { border-color: #4f46e5; }

.stats-grid { display: flex; gap: 24px; }
.stat-item { text-align: center; }
.stat-value { font-size: 28px; font-weight: 700; color: #4f46e5; display: block; }
.stat-label { font-size: 13px; color: #999; }

/* 数据管理 */
.data-actions { display: flex; flex-direction: column; gap: 12px; }

.data-action {
  display: flex; justify-content: space-between; align-items: center;
  padding: 14px 16px; background: #f9fafb; border-radius: 10px;
}

.action-info { display: flex; align-items: center; gap: 12px; }
.action-icon { font-size: 24px; }
.action-title { font-size: 14px; font-weight: 600; display: block; }
.action-desc { font-size: 12px; color: #999; }

.status-message {
  margin-top: 12px; padding: 10px 14px; border-radius: 8px;
  font-size: 13px; text-align: center;
}
.status-message.success { background: #ecfdf5; color: #059669; }
.status-message.error { background: #fef2f2; color: #dc2626; }
</style>
