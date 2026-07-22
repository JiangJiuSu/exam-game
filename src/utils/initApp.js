// 应用初始化：加载数据、版本迁移、自动备份、检查断签
import { useCreditStore } from '../stores/creditStore'
import { useStreakStore } from '../stores/streakStore'
import { useTaskStore } from '../stores/taskStore'
import { loadData, saveData, migrateData, startAutoBackup } from './dataPersistence'
import { checkAchievements } from './achievements'

let saveTimer = null

export async function initApp() {
  const creditStore = useCreditStore()
  const streakStore = useStreakStore()
  const taskStore = useTaskStore()

  // 1. 加载原始数据
  let data = await loadData()

  // 2. 版本迁移（如果需要）
  data = await migrateData(data)

  // 3. 注入到各 store
  if (data.credits) creditStore.deserialize(data.credits)
  if (data.streak) streakStore.deserialize(data.streak)
  if (data.tasks) taskStore.deserialize(data.tasks)

  // 4. 运行时检查
  streakStore.checkStreakBreak()
  taskStore.checkOverdueTasks()
  checkAchievements(creditStore, streakStore)

  // 5. 启动自动保存（每5秒）
  startAutoSave()

  // 6. 启动自动备份（每5分钟）
  startAutoBackup(300000)
}

function startAutoSave() {
  if (saveTimer) clearInterval(saveTimer)
  saveTimer = setInterval(async () => {
    await saveAllData()
  }, 5000)
}

export async function saveAllData() {
  const creditStore = useCreditStore()
  const streakStore = useStreakStore()
  const taskStore = useTaskStore()

  await saveData({
    credits: creditStore.serialize(),
    streak: streakStore.serialize(),
    tasks: taskStore.serialize()
  })
}
