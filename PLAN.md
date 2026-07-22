# 考研游戏系统 — 技术实现计划

## 技术栈

| 项目 | 选择 | 理由 |
|------|------|------|
| 框架 | Electron | UI表现力强，适合图表动画 |
| 前端 | Vue 3 + Vite | 响应式，组件化开发 |
| 数据存储 | JSON 文件 (electron-store) | 单机应用，简单可靠 |
| 图表 | ECharts | 热力图、雷达图、进度图 |
| 打包 | electron-builder | 生成 Windows 安装包 |

---

## 项目结构

```
exam-game/
├── package.json
├── electron/
│   ├── main.js              # Electron 主进程
│   ├── preload.js            # 预加载脚本
│   └── store.js              # 数据存储层
├── src/
│   ├── main.js               # Vue 入口
│   ├── App.vue               # 根组件
│   ├── router.js             # 路由
│   ├── stores/               # Pinia 状态管理
│   │   ├── taskStore.js      # 任务状态
│   │   ├── creditStore.js    # 学分状态
│   │   └── streakStore.js    # 签到状态
│   ├── utils/
│   │   ├── calculator.js     # 学分计算、倍率计算
│   │   └── achievements.js   # 成就判定
│   ├── components/
│   │   ├── SchoolProgress.vue    # 学校进度条
│   │   ├── HeatMap.vue           # 学分日历热力图
│   │   ├── SubjectChart.vue      # 四科分布图
│   │   ├── StreakDisplay.vue     # 连续签到展示
│   │   ├── TaskCard.vue          # 任务卡片
│   │   ├── TaskForm.vue          # 任务创建表单
│   │   ├── AchievementPopup.vue  # 成就弹窗
│   │   └── Sidebar.vue           # 侧边栏导航
│   └── views/
│       ├── Dashboard.vue     # 主面板（进度条+热力图+签到）
│       ├── Tasks.vue         # 任务管理页
│       ├── Achievements.vue  # 成就展示页
│       └── Settings.vue      # 设置页（学校门槛自定义）
├── data/
│   └── game-data.json        # 本地数据文件
└── DESIGN.md                 # 游戏设计文档
```

---

## 数据结构

```json
{
  "meta": {
    "version": "1.0.0",
    "createdAt": "2026-07-22",
    "targetSchool": {
      "name": "985",
      "requiredCredits": 15000
    }
  },
  "credits": {
    "english": 0,
    "math": 0,
    "politics": 0,
    "major": 0
  },
  "streak": {
    "currentDays": 0,
    "lastActiveDate": null,
    "maxDays": 0
  },
  "tasks": [
    {
      "id": "uuid",
      "name": "背50个单词",
      "subject": "english",
      "reward": 50,
      "deadline": "2026-07-23T18:00:00",
      "note": "",
      "status": "pending",
      "createdAt": "2026-07-22T10:00:00",
      "completedAt": null,
      "actualReward": 0
    }
  ],
  "achievements": [],
  "dailyLog": {
    "2026-07-22": {
      "totalCredits": 0,
      "tasksCompleted": 0,
      "streakDay": 1
    }
  }
}
```

---

## 实现步骤

### Phase 1: 项目搭建
1. 初始化 Electron + Vue 3 + Vite 项目
2. 配置 electron-store 数据层
3. 搭建基础窗口和路由框架
4. **验证**: 应用能启动，显示空白主页

### Phase 2: 核心数据层
5. 实现任务 CRUD（创建/读取/更新/删除）
6. 实现学分计算逻辑（按时/超时/未完成）
7. 实现连续签到倍率计算
8. 实现每日签到判定
9. **验证**: 控制台可操作任务数据，学分计算正确

### Phase 3: 主面板 UI
10. 实现学校进度条组件
11. 实现连续签到天数展示
12. 实现学分日历热力图（ECharts）
13. 实现四科学分雷达图
14. **验证**: 主面板完整显示所有可视化组件

### Phase 4: 任务管理 UI
15. 实现任务创建表单
16. 实现任务列表（待完成/已完成/逾期）
17. 实现任务完成/超时处理流程
18. 逾期任务红色标记
19. **验证**: 可创建任务、完成任务、学分正确变化

### Phase 5: 成就系统 + 设置
20. 实现成就判定逻辑
21. 实现成就弹窗动画
22. 实现成就展示页
23. 实现设置页（目标学校切换、门槛自定义）
24. **验证**: 达成条件弹出成就，设置可保存

### Phase 6: 打磨与打包
25. UI 细节打磨（动画、过渡、音效可选）
26. 首次使用引导
27. electron-builder 打包配置
28. **验证**: 生成可运行的 Windows 安装包

---

## 关键设计决策

- **数据存储**: JSON 文件而非 SQLite，因为数据结构简单，JSON 可读可手动修复
- **状态管理**: Pinia，Vue 3 生态标准方案
- **图表**: ECharts，原生支持热力图和雷达图
- **签到判定**: 基于日期比较，不依赖网络时间
- **倍率计算**: 每次计算实时从 streak 状态读取，不缓存
