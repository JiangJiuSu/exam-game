<template>
  <div class="tasks-page fade-in">
    <!-- 完成提示 -->
    <Transition name="toast">
      <div v-if="showToast" class="toast toast-success">
        ✅ 任务已完成！获得 <strong>{{ toastMinutes }}</strong> 分钟有效时长
      </div>
    </Transition>

    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">任务管理</h1>
        <button class="btn btn-ghost btn-sm" @click="showForm = true">+ 新建任务</button>
      </div>
      <div class="header-right">
        <div class="view-toggle">
          <button
            class="toggle-btn"
            :class="{ active: viewMode === 'today' }"
            @click="viewMode = 'today'"
          >📋 今日</button>
          <button
            class="toggle-btn"
            :class="{ active: viewMode === 'calendar' }"
            @click="viewMode = 'calendar'"
          >📅 日历</button>
        </div>
        <label class="admin-toggle">
          <input type="checkbox" v-model="adminMode" />
          <span class="admin-label">🔧 管理员</span>
        </label>
      </div>
    </div>

    <TaskForm v-if="showForm" @close="showForm = false" />

    <!-- 今日视图 -->
    <template v-if="viewMode === 'today'">
      <div class="task-tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="tab-btn"
          :class="{ active: activeTab === tab.key }"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
          <span class="tab-count">{{ getTabCount(tab.key) }}</span>
        </button>
      </div>

      <div class="task-list">
        <TaskCard
          v-for="task in filteredTasks"
          :key="task.id"
          :task="task"
          :adminMode="adminMode"
        />
        <div v-if="filteredTasks.length === 0" class="empty-state">
          <span class="empty-icon">📋</span>
          <p>{{ emptyText }}</p>
        </div>
      </div>
    </template>

    <!-- 日历视图 -->
    <template v-else>
      <TaskCalendar :adminMode="adminMode" />
    </template>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useTaskStore } from '../stores/taskStore'
import TaskForm from '../components/TaskForm.vue'
import TaskCard from '../components/TaskCard.vue'
import TaskCalendar from '../components/TaskCalendar.vue'

const taskStore = useTaskStore()
const showForm = ref(false)
const activeTab = ref('pending')
const adminMode = ref(false)
const viewMode = ref('today')

const showToast = ref(false)
const toastMinutes = ref(0)

const tabs = [
  { key: 'running', label: '进行中' },
  { key: 'pending', label: '待开始' },
  { key: 'overdue', label: '已逾期' },
  { key: 'completed', label: '已完成' }
]

const todayStr = new Date().toISOString().split('T')[0]

const todayTasks = computed(() => {
  return taskStore.tasks.filter(t => {
    const created = t.createdAt ? t.createdAt.split('T')[0] : null
    return created === todayStr
  })
})

const filteredTasks = computed(() => {
  return todayTasks.value.filter(t => t.status === activeTab.value)
})

function getTabCount(tab) {
  return todayTasks.value.filter(t => t.status === tab).length
}

const emptyText = computed(() => {
  const map = {
    running: '今天暂无进行中的任务',
    pending: '今天暂无待开始任务，点击右上角创建',
    overdue: '今天暂无逾期任务',
    completed: '今天暂无已完成任务'
  }
  return map[activeTab.value] || '暂无任务'
})

// 监听任务完成，自动切到已完成标签
watch(() => taskStore.justCompleted, (newId) => {
  if (newId) {
    const task = taskStore.tasks.find(t => t.id === newId)
    if (task) {
      // 显示提示
      toastMinutes.value = task.effectiveMinutes
      showToast.value = true
      setTimeout(() => { showToast.value = false }, 2000)

      // 切到已完成标签
      activeTab.value = 'completed'
    }
  }
})
</script>

<style scoped>
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.page-title {
  font-size: 24px;
  font-weight: 700;
  color: #1e1e2e;
}

/* Toast 提示 */
.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  padding: 12px 24px;
  border-radius: 10px;
  font-size: 14px;
  z-index: 200;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.toast-success {
  background: #ecfdf5;
  color: #059669;
  border: 1px solid #a7f3d0;
}

.toast-enter-active { transition: all 0.3s ease; }
.toast-leave-active { transition: all 0.3s ease; }
.toast-enter-from { opacity: 0; transform: translateX(-50%) translateY(-20px); }
.toast-leave-to { opacity: 0; transform: translateX(-50%) translateY(-20px); }

/* 视图切换 */
.view-toggle {
  display: flex;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
}

.toggle-btn {
  padding: 6px 14px;
  border: none;
  background: #fff;
  cursor: pointer;
  font-size: 13px;
  transition: all 0.2s;
}

.toggle-btn.active {
  background: #4f46e5;
  color: #fff;
}

.admin-toggle {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  transition: all 0.2s;
}
.admin-toggle:hover { border-color: #f59e0b; }
.admin-toggle input { accent-color: #f59e0b; }
.admin-label { font-size: 12px; color: #666; }

.task-tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
}

.tab-btn {
  padding: 8px 20px;
  border: none;
  border-radius: 20px;
  background: #e5e7eb;
  color: #666;
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.tab-btn.active {
  background: #4f46e5;
  color: #fff;
}

.tab-count {
  background: rgba(255, 255, 255, 0.3);
  padding: 1px 8px;
  border-radius: 10px;
  font-size: 12px;
}

.task-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.empty-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 12px;
}

.btn-sm {
  padding: 6px 14px;
  font-size: 13px;
}
</style>
