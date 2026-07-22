import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useStreakStore = defineStore('streak', () => {
  const currentDays = ref(0)
  const lastActiveDate = ref(null)
  const maxDays = ref(0)

  // 当前倍率: 第1天×1.1, 每天+0.1, 上限×1.5
  const currentMultiplier = computed(() => {
    if (currentDays.value === 0) return 1.0
    return Math.min(1.5, 1.0 + currentDays.value * 0.1)
  })

  // 签到：当天完成任意任务后调用
  function checkIn() {
    const today = new Date().toISOString().split('T')[0]

    if (lastActiveDate.value === today) {
      // 今天已经签到过了
      return
    }

    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    const yesterdayStr = yesterday.toISOString().split('T')[0]

    if (lastActiveDate.value === yesterdayStr) {
      // 连续签到
      currentDays.value += 1
    } else {
      // 断签，重新开始
      currentDays.value = 1
    }

    lastActiveDate.value = today

    if (currentDays.value > maxDays.value) {
      maxDays.value = currentDays.value
    }
  }

  // 检查是否断签（每日启动时调用）
  function checkStreakBreak() {
    if (!lastActiveDate.value) return

    const today = new Date().toISOString().split('T')[0]
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    const yesterdayStr = yesterday.toISOString().split('T')[0]

    if (lastActiveDate.value !== today && lastActiveDate.value !== yesterdayStr) {
      // 断签了
      currentDays.value = 0
    }
  }

  function serialize() {
    return {
      currentDays: currentDays.value,
      lastActiveDate: lastActiveDate.value,
      maxDays: maxDays.value
    }
  }

  function deserialize(data) {
    if (!data) return
    currentDays.value = data.currentDays || 0
    lastActiveDate.value = data.lastActiveDate || null
    maxDays.value = data.maxDays || 0
    // 启动时检查断签
    checkStreakBreak()
  }

  return {
    currentDays, lastActiveDate, maxDays, currentMultiplier,
    checkIn, checkStreakBreak, serialize, deserialize
  }
})
