// 数据持久化层
// 支持：版本迁移、自动备份、导入导出

const isElectron = typeof window !== 'undefined' && window.electronAPI

// 当前数据版本号，每次数据结构变化时递增
const DATA_VERSION = 1

// ============ 基础读写 ============

export async function loadData() {
  if (isElectron) {
    const raw = await window.electronAPI.store.getAll()
    return raw || {}
  } else {
    const data = localStorage.getItem('exam-game-data')
    return data ? JSON.parse(data) : {}
  }
}

export async function saveData(data) {
  // 写入时带上版本号
  data._version = DATA_VERSION

  if (isElectron) {
    for (const [key, value] of Object.entries(data)) {
      await window.electronAPI.store.set(key, value)
    }
  } else {
    localStorage.setItem('exam-game-data', JSON.stringify(data))
  }
}

// ============ 版本迁移 ============

export async function migrateData(data) {
  const currentVersion = data._version || 0

  if (currentVersion < DATA_VERSION) {
    console.log(`[数据迁移] 从 v${currentVersion} 迁移到 v${DATA_VERSION}`)

    // v0 → v1: 学分系统改为学习时长系统
    if (currentVersion < 1) {
      data = migrateV0toV1(data)
    }

    // 保存迁移后的数据
    await saveData(data)
    console.log('[数据迁移] 完成')
  }

  return data
}

function migrateV0toV1(data) {
  // 旧的 "credits" 数据中有 reward/actualReward 字段
  // 新的使用 plannedMinutes/effectiveMinutes
  if (data.tasks) {
    data.tasks = data.tasks.map(task => ({
      ...task,
      // 字段映射
      plannedMinutes: task.reward || task.plannedMinutes || 30,
      effectiveMinutes: task.actualReward || task.effectiveMinutes || 0,
    }))
  }

  // 目标学校：旧的 requiredCredits → 新的 requiredMinutes
  if (data.credits?.targetSchool?.requiredCredits) {
    const oldCredits = data.credits.targetSchool.requiredCredits
    data.credits.targetSchool.requiredMinutes = oldCredits * 60 // 假设旧1学分=1分钟
    delete data.credits.targetSchool.requiredCredits
  }

  // 每日日志：totalCredits → totalMinutes
  if (data.credits?.dailyLog) {
    for (const date of Object.keys(data.credits.dailyLog)) {
      const log = data.credits.dailyLog[date]
      if (log.totalCredits !== undefined) {
        log.totalMinutes = log.totalCredits
        delete log.totalCredits
      }
    }
  }

  return data
}

// ============ 自动备份 ============

let backupTimer = null

export function startAutoBackup(intervalMs = 300000) { // 默认5分钟
  if (backupTimer) clearInterval(backupTimer)
  backupTimer = setInterval(async () => {
    await createBackup()
  }, intervalMs)
}

export async function createBackup() {
  const data = await loadData()
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
  const backupKey = `backup_${timestamp}`

  if (isElectron) {
    await window.electronAPI.store.set(backupKey, {
      ...data,
      _backupTime: new Date().toISOString()
    })

    // 清理旧备份，只保留最近10个
    const allData = await window.electronAPI.store.getAll()
    const backups = Object.keys(allData)
      .filter(k => k.startsWith('backup_'))
      .sort()
      .reverse()

    for (const oldBackup of backups.slice(10)) {
      await window.electronAPI.store.delete(oldBackup)
    }
  } else {
    const backups = JSON.parse(localStorage.getItem('exam-game-backups') || '[]')
    backups.unshift({
      key: backupKey,
      time: new Date().toISOString(),
      data: data
    })
    // 只保留最近5个备份
    localStorage.setItem('exam-game-backups', JSON.stringify(backups.slice(0, 5)))
  }
}

export async function getBackups() {
  if (isElectron) {
    const allData = await window.electronAPI.store.getAll()
    return Object.entries(allData)
      .filter(([k]) => k.startsWith('backup_'))
      .map(([k, v]) => ({ key: k, ...v }))
      .sort((a, b) => (b._backupTime || '').localeCompare(a._backupTime || ''))
  } else {
    return JSON.parse(localStorage.getItem('exam-game-backups') || '[]')
  }
}

export async function restoreBackup(backupKey) {
  let backupData

  if (isElectron) {
    backupData = await window.electronAPI.store.get(backupKey)
  } else {
    const backups = JSON.parse(localStorage.getItem('exam-game-backups') || '[]')
    backupData = backups.find(b => b.key === backupKey)
  }

  if (backupData) {
    await saveData(backupData)
    return true
  }
  return false
}

// ============ 导入/导出 ============

export async function exportData() {
  const data = await loadData()
  // 不导出备份和内部字段
  const exportObj = {}
  for (const [key, value] of Object.entries(data)) {
    if (!key.startsWith('backup_') && key !== '_version') {
      exportObj[key] = value
    }
  }
  exportObj._version = DATA_VERSION
  exportObj._exportTime = new Date().toISOString()

  const json = JSON.stringify(exportObj, null, 2)
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)

  // 触发下载
  const a = document.createElement('a')
  a.href = url
  a.download = `考研游戏数据_${new Date().toLocaleDateString('zh-CN').replace(/\//g, '-')}.json`
  a.click()
  URL.revokeObjectURL(url)
}

export async function importData(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = async (e) => {
      try {
        const data = JSON.parse(e.target.result)

        // 验证数据结构
        if (!data.credits && !data.tasks && !data.streak) {
          reject(new Error('无效的数据文件'))
          return
        }

        // 先备份当前数据
        await createBackup()

        // 写入导入的数据
        await saveData(data)
        resolve(data)
      } catch (err) {
        reject(err)
      }
    }
    reader.readAsText(file)
  })
}
