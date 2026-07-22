import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useCreditStore = defineStore('credits', () => {
  // 四科累计学习时长（分钟）- 含倍率加成
  const english = ref(0)
  const math = ref(0)
  const politics = ref(0)
  const major = ref(0)

  // 四科真实学习时长（分钟）- 不含倍率
  const realEnglish = ref(0)
  const realMath = ref(0)
  const realPolitics = ref(0)
  const realMajor = ref(0)

  // 目标学校
  const targetSchool = ref({
    name: '985',
    requiredMinutes: 90000
  })

  const achievements = ref([])
  const dailyLog = ref({})

  // 总学习时长（含倍率）
  const totalMinutes = computed(() => english.value + math.value + politics.value + major.value)
  const totalHours = computed(() => (totalMinutes.value / 60).toFixed(1))

  // 总真实学习时长（不含倍率）
  const totalRealMinutes = computed(() => realEnglish.value + realMath.value + realPolitics.value + realMajor.value)
  const totalRealHours = computed(() => (totalRealMinutes.value / 60).toFixed(1))

  // 进度百分比（基于含倍率的总时长）
  const progressPercent = computed(() => {
    if (targetSchool.value.requiredMinutes === 0) return 100
    return Math.min(100, Math.round((totalMinutes.value / targetSchool.value.requiredMinutes) * 100))
  })

  // 增加学习时长
  function addDuration(subject, effectiveMinutes, realMinutes) {
    const effRounded = Math.round(effectiveMinutes)
    const realRounded = Math.round(realMinutes || effectiveMinutes)
    if (effRounded <= 0) return

    // 含倍率的时长
    switch (subject) {
      case 'english': english.value += effRounded; break
      case 'math': math.value += effRounded; break
      case 'politics': politics.value += effRounded; break
      case 'major': major.value += effRounded; break
    }

    // 真实时长
    switch (subject) {
      case 'english': realEnglish.value += realRounded; break
      case 'math': realMath.value += realRounded; break
      case 'politics': realPolitics.value += realRounded; break
      case 'major': realMajor.value += realRounded; break
    }

    // 每日日志
    const today = new Date().toISOString().split('T')[0]
    if (!dailyLog.value[today]) {
      dailyLog.value[today] = { totalMinutes: 0, realMinutes: 0, tasksCompleted: 0 }
    }
    dailyLog.value[today].totalMinutes += effRounded
    dailyLog.value[today].realMinutes += realRounded
    dailyLog.value[today].tasksCompleted += 1
  }

  // 扣除学习时长
  function deductDuration(subject, effectiveMinutes) {
    const rounded = Math.round(effectiveMinutes)
    if (rounded <= 0) return
    switch (subject) {
      case 'english': english.value = Math.max(0, english.value - rounded); break
      case 'math': math.value = Math.max(0, math.value - rounded); break
      case 'politics': politics.value = Math.max(0, politics.value - rounded); break
      case 'major': major.value = Math.max(0, major.value - rounded); break
    }
    // 真实时长也扣除
    switch (subject) {
      case 'english': realEnglish.value = Math.max(0, realEnglish.value - rounded); break
      case 'math': realMath.value = Math.max(0, realMath.value - rounded); break
      case 'politics': realPolitics.value = Math.max(0, realPolitics.value - rounded); break
      case 'major': realMajor.value = Math.max(0, realMajor.value - rounded); break
    }
  }

  function setTargetSchool(school) {
    targetSchool.value = { ...school }
  }

  function unlockAchievement(id) {
    if (!achievements.value.includes(id)) {
      achievements.value.push(id)
    }
  }

  function serialize() {
    return {
      english: english.value,
      math: math.value,
      politics: politics.value,
      major: major.value,
      realEnglish: realEnglish.value,
      realMath: realMath.value,
      realPolitics: realPolitics.value,
      realMajor: realMajor.value,
      targetSchool: targetSchool.value,
      achievements: achievements.value,
      dailyLog: dailyLog.value
    }
  }

  function deserialize(data) {
    if (!data) return
    english.value = data.english || 0
    math.value = data.math || 0
    politics.value = data.politics || 0
    major.value = data.major || 0
    realEnglish.value = data.realEnglish || 0
    realMath.value = data.realMath || 0
    realPolitics.value = data.realPolitics || 0
    realMajor.value = data.realMajor || 0
    if (data.targetSchool) targetSchool.value = data.targetSchool
    if (data.achievements) achievements.value = data.achievements
    if (data.dailyLog) dailyLog.value = data.dailyLog
  }

  return {
    english, math, politics, major,
    realEnglish, realMath, realPolitics, realMajor,
    targetSchool, achievements, dailyLog,
    totalMinutes, totalHours,
    totalRealMinutes, totalRealHours,
    progressPercent,
    addDuration, deductDuration, setTargetSchool,
    unlockAchievement, serialize, deserialize
  }
})
