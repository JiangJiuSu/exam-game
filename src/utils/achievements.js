// 成就定义（单位：分钟）
export const ACHIEVEMENTS = [
  // 学科里程碑 - 英语
  { id: 'eng_10', icon: '📘', name: '英语入门', description: '英语学习10小时', check: (c) => c.english >= 600 },
  { id: 'eng_50', icon: '📗', name: '英语进阶', description: '英语学习50小时', check: (c) => c.english >= 3000 },
  { id: 'eng_100', icon: '📙', name: '英语精通', description: '英语学习100小时', check: (c) => c.english >= 6000 },
  { id: 'eng_500', icon: '📕', name: '英语大师', description: '英语学习500小时', check: (c) => c.english >= 30000 },

  // 学科里程碑 - 数学
  { id: 'math_10', icon: '📐', name: '数学入门', description: '数学学习10小时', check: (c) => c.math >= 600 },
  { id: 'math_50', icon: '📏', name: '数学进阶', description: '数学学习50小时', check: (c) => c.math >= 3000 },
  { id: 'math_100', icon: '🧮', name: '数学精通', description: '数学学习100小时', check: (c) => c.math >= 6000 },
  { id: 'math_500', icon: '🔬', name: '数学大师', description: '数学学习500小时', check: (c) => c.math >= 30000 },

  // 学科里程碑 - 政治
  { id: 'pol_10', icon: '📰', name: '政治入门', description: '政治学习10小时', check: (c) => c.politics >= 600 },
  { id: 'pol_50', icon: '📋', name: '政治进阶', description: '政治学习50小时', check: (c) => c.politics >= 3000 },
  { id: 'pol_100', icon: '📊', name: '政治精通', description: '政治学习100小时', check: (c) => c.politics >= 6000 },
  { id: 'pol_500', icon: '🏛️', name: '政治大师', description: '政治学习500小时', check: (c) => c.politics >= 30000 },

  // 学科里程碑 - 专业课
  { id: 'maj_10', icon: '📖', name: '专业入门', description: '专业课学习10小时', check: (c) => c.major >= 600 },
  { id: 'maj_50', icon: '📚', name: '专业进阶', description: '专业课学习50小时', check: (c) => c.major >= 3000 },
  { id: 'maj_100', icon: '🎓', name: '专业精通', description: '专业课学习100小时', check: (c) => c.major >= 6000 },
  { id: 'maj_500', icon: '👨‍🎓', name: '专业大师', description: '专业课学习500小时', check: (c) => c.major >= 30000 },

  // 签到里程碑
  { id: 'streak_7', icon: '🔥', name: '初心者', description: '连续签到7天', check: (c, s) => s.currentDays >= 7 },
  { id: 'streak_30', icon: '🔥', name: '坚持者', description: '连续签到30天', check: (c, s) => s.currentDays >= 30 },
  { id: 'streak_100', icon: '🔥', name: '毅力者', description: '连续签到100天', check: (c, s) => s.currentDays >= 100 },

  // 总学习时长里程碑
  { id: 'total_100', icon: '⭐', name: '起步', description: '总学习100小时', check: (c) => (c.english + c.math + c.politics + c.major) >= 6000 },
  { id: 'total_500', icon: '🌟', name: '积累', description: '总学习500小时', check: (c) => (c.english + c.math + c.politics + c.major) >= 30000 },
  { id: 'total_1000', icon: '💫', name: '突破', description: '总学习1000小时', check: (c) => (c.english + c.math + c.politics + c.major) >= 60000 },
  { id: 'total_3000', icon: '🏆', name: '登顶', description: '总学习3000小时', check: (c) => (c.english + c.math + c.politics + c.major) >= 180000 }
]

// 检查并解锁新成就
export function checkAchievements(creditStore, streakStore) {
  const credits = {
    english: creditStore.english,
    math: creditStore.math,
    politics: creditStore.politics,
    major: creditStore.major
  }
  const streak = { currentDays: streakStore.currentDays }
  const newAchievements = []

  ACHIEVEMENTS.forEach(a => {
    if (!creditStore.achievements.includes(a.id) && a.check(credits, streak)) {
      creditStore.unlockAchievement(a.id)
      newAchievements.push(a)
    }
  })

  // 触发弹窗
  newAchievements.forEach(a => {
    if (typeof window !== 'undefined' && window.showAchievement) {
      window.showAchievement(a)
    }
  })

  return newAchievements
}
