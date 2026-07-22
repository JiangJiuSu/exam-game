import { defineStore } from 'pinia'
import { ref } from 'vue'
import { v4 as uuidv4 } from 'uuid'
import { useCreditStore } from './creditStore'
import { useStreakStore } from './streakStore'

export const useTaskStore = defineStore('tasks', () => {
  const tasks = ref([])
  const activeTimer = ref(null)
  const justCompleted = ref(null)

  function updateTask(taskId, updater) {
    const idx = tasks.value.findIndex(t => t.id === taskId)
    if (idx === -1) return null
    const updated = { ...tasks.value[idx] }
    updater(updated)
    tasks.value = [
      ...tasks.value.slice(0, idx),
      updated,
      ...tasks.value.slice(idx + 1)
    ]
    return updated
  }

  // 创建任务
  function createTask({ name, subject, plannedMinutes, duration, deadline, note }) {
    const task = {
      id: uuidv4(),
      name,
      subject,
      plannedMinutes: plannedMinutes || duration || 30,
      deadline: deadline || null,
      note: note || '',
      status: 'pending',
      createdAt: new Date().toISOString(),
      startedAt: null,
      completedAt: null,
      realMinutes: 0,        // 真实有效时长（不含倍率）
      effectiveMinutes: 0,   // 有效时长（含倍率）
      overdue: false
    }
    tasks.value = [task, ...tasks.value]
    return task
  }

  // 开始任务
  function startTask(taskId) {
    return updateTask(taskId, (t) => {
      if (t.status !== 'pending') return
      t.status = 'running'
      t.startedAt = new Date().toISOString()
      activeTimer.value = taskId
    })
  }

  // 完成任务
  function completeTask(taskId) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task || (task.status !== 'pending' && task.status !== 'running')) return null

    const streakStore = useStreakStore()

    const now = new Date()
    let isOverdue = false
    let realMinutes = 0
    let effectiveMinutes = 0

    if (task.status === 'running' && task.startedAt) {
      const elapsedSeconds = (now.getTime() - new Date(task.startedAt).getTime()) / 1000
      const totalSeconds = task.plannedMinutes * 60
      isOverdue = elapsedSeconds > totalSeconds
      realMinutes = Math.round(elapsedSeconds / 60)
    } else if (task.deadline) {
      isOverdue = now > new Date(task.deadline)
      realMinutes = task.plannedMinutes
    } else {
      realMinutes = task.plannedMinutes
    }

    if (isOverdue) {
      effectiveMinutes = Math.round(task.plannedMinutes * 0.7)
      realMinutes = Math.round(task.plannedMinutes * 0.7)
    } else {
      if (task.startedAt) {
        const elapsedMinutes = (now.getTime() - new Date(task.startedAt).getTime()) / 60000
        effectiveMinutes = Math.round(elapsedMinutes * streakStore.currentMultiplier)
      } else {
        effectiveMinutes = Math.round(task.plannedMinutes * streakStore.currentMultiplier)
      }
      streakStore.checkIn()
    }

    realMinutes = Math.max(1, realMinutes)
    effectiveMinutes = Math.max(1, effectiveMinutes)

    // 先更新任务状态
    const updated = updateTask(taskId, (t) => {
      t.status = 'completed'
      t.completedAt = now.toISOString()
      t.overdue = isOverdue
      t.realMinutes = realMinutes
      t.effectiveMinutes = effectiveMinutes
    })

    // 再单独增加学习时长（确保触发响应式更新）
    const creditStore = useCreditStore()
    creditStore.addDuration(task.subject, effectiveMinutes, realMinutes)

    justCompleted.value = taskId
    setTimeout(() => { justCompleted.value = null }, 2000)

    return updated
  }

  // 撤销已完成的任务
  function undoTask(taskId) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task || task.status !== 'completed') return

    const updated = updateTask(taskId, (t) => {
      t.status = 'pending'
      t.completedAt = null
      t.startedAt = null
      t.realMinutes = 0
      t.effectiveMinutes = 0
      t.overdue = false
    })

    if (task.effectiveMinutes > 0) {
      const creditStore = useCreditStore()
      creditStore.deductDuration(task.subject, task.effectiveMinutes)
    }

    return updated
  }

  // 标记任务逾期
  function markOverdue(taskId) {
    return updateTask(taskId, (t) => {
      if (t.status !== 'running') return
      t.status = 'overdue'
      t.overdue = true
      if (activeTimer.value === taskId) {
        activeTimer.value = null
      }
    })
  }

  // 删除任务（已完成的任务会回退学习时长）
  function deleteTask(taskId) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task) return

    // 如果是已完成的任务，回退学习时长
    if (task.status === 'completed' && task.effectiveMinutes > 0) {
      const creditStore = useCreditStore()
      creditStore.deductDuration(task.subject, task.effectiveMinutes)
    }

    if (activeTimer.value === taskId) {
      activeTimer.value = null
    }
    tasks.value = tasks.value.filter(t => t.id !== taskId)
  }

  // 管理员编辑真实时长（自动重算有效时长）
  function editRealMinutes(taskId, newRealMinutes) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task || task.status !== 'completed') return

    const streakStore = useStreakStore()
    const creditStore = useCreditStore()

    const oldEffective = task.effectiveMinutes

    // 先回退旧的学习时长
    creditStore.deductDuration(task.subject, oldEffective)

    // 计算新的有效时长
    let newEffective = 0
    const isOverdue = newRealMinutes > task.plannedMinutes

    if (isOverdue) {
      // 超时：真实时长 × 70% × 倍率
      newEffective = Math.round(newRealMinutes * 0.7 * streakStore.currentMultiplier)
    } else {
      // 未超时：真实时长 × 倍率
      newEffective = Math.round(newRealMinutes * streakStore.currentMultiplier)
    }
    newEffective = Math.max(1, newEffective)

    // 更新任务
    updateTask(taskId, (t) => {
      t.realMinutes = newRealMinutes
      t.effectiveMinutes = newEffective
      t.overdue = isOverdue
    })

    // 再增加新的学习时长
    creditStore.addDuration(task.subject, newEffective, newRealMinutes)
  }

  // 完成逾期任务
  function completeOverdueTask(taskId) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task || task.status !== 'overdue') return

    const effectiveMinutes = Math.round(task.plannedMinutes * 0.7)
    const realMinutes = effectiveMinutes

    const updated = updateTask(taskId, (t) => {
      t.status = 'completed'
      t.completedAt = new Date().toISOString()
      t.overdue = true
      t.realMinutes = realMinutes
      t.effectiveMinutes = effectiveMinutes
    })

    const creditStore = useCreditStore()
    creditStore.addDuration(task.subject, effectiveMinutes, realMinutes)

    justCompleted.value = taskId
    setTimeout(() => { justCompleted.value = null }, 2000)

    return updated
  }

  // 检查截止日期任务是否超时
  function checkOverdueTasks() {
    const now = new Date()
    tasks.value.forEach(task => {
      if (task.status === 'pending' && task.deadline && new Date(task.deadline) < now) {
        updateTask(task.id, (t) => {
          t.status = 'overdue'
          t.overdue = true
        })
      }
    })
  }

  function getRemainingTime(taskId) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task || task.status !== 'running' || !task.startedAt) return 0
    const elapsed = (Date.now() - new Date(task.startedAt).getTime()) / 1000
    return Math.max(0, task.plannedMinutes * 60 - elapsed)
  }

  function serialize() {
    return tasks.value.map(t => ({ ...t }))
  }

  function deserialize(data) {
    if (!data) return
    tasks.value = data
    const running = tasks.value.find(t => t.status === 'running')
    activeTimer.value = running ? running.id : null
  }

  return {
    tasks, activeTimer, justCompleted,
    createTask, startTask, completeTask, undoTask,
    markOverdue, deleteTask, completeOverdueTask,
    editRealMinutes,
    checkOverdueTasks, getRemainingTime,
    serialize, deserialize
  }
})
