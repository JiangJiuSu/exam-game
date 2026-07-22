# 考研游戏系统 — 技术实现计划

> 最后更新: 2026-07-22

---

## 技术栈

| 项目 | 选择 | 理由 |
|------|------|------|
| 框架 | Electron | 桌面应用，原生窗口 |
| 前端 | Vue 3 + Vite | 响应式，组件化，热更新 |
| 状态管理 | Pinia | Vue 3 生态标准方案 |
| 数据存储 | electron-store (JSON) | 单机应用，简单可靠 |
| 图表 | ECharts | 热力图、雷达图 |
| 打包 | electron-builder | 生成 Windows 安装包 |

---

## 项目结构

```
exam-game/
├── package.json
├── vite.config.js
├── index.html
├── electron/
│   ├── main.js                # Electron 主进程
│   └── preload.js             # 预加载脚本（IPC 桥接）
├── src/
│   ├── main.js                # Vue 入口
│   ├── App.vue                # 根组件（含成就弹窗）
│   ├── router.js              # 路由（4个页面）
│   ├── style.css              # 全局样式
│   ├── stores/
│   │   ├── creditStore.js     # 学习时长状态（真实/有效，四科）
│   │   ├── streakStore.js     # 连续签到状态（天数/倍率）
│   │   └── taskStore.js       # 任务状态（CRUD/倒计时/完成/撤销）
│   ├── utils/
│   │   ├── achievements.js    # 24个成就定义与检查逻辑
│   │   ├── dataPersistence.js # 数据持久化/备份/导入导出/版本迁移
│   │   └── initApp.js         # 应用初始化（加载数据/检查断签/启动自动保存）
│   ├── components/
│   │   ├── Sidebar.vue            # 侧边栏导航 + 签到徽章
│   │   ├── SchoolProgress.vue     # 学校进度条（真实→有效→目标）
│   │   ├── StreakDisplay.vue      # 连续签到展示 + 倍率
│   │   ├── HeatMap.vue            # 学习日历热力图（ECharts）
│   │   ├── SubjectChart.vue       # 四科雷达图（ECharts）
│   │   ├── TaskCard.vue           # 任务卡片（倒计时/完成/编辑）
│   │   ├── HistoryTaskCard.vue    # 历史任务卡片（日历视图用）
│   │   ├── TaskForm.vue           # 任务创建表单（倒计时/截止日期模式）
│   │   ├── TaskCalendar.vue       # 月历组件（按日期查看历史任务）
│   │   └── AchievementPopup.vue   # 成就解锁弹窗
│   └── views/
│       ├── Dashboard.vue          # 主面板（进度条+热力图+签到+雷达图）
│       ├── Tasks.vue              # 任务管理（今日视图+日历视图）
│       ├── Achievements.vue       # 成就展示页
│       └── Settings.vue           # 设置（目标学校+数据管理）
└── DESIGN.md                     # 游戏机制设计文档
```

---

## 核心模块说明

### creditStore.js — 学习时长

```js
// 四科有效时长（含倍率加成）
english, math, politics, major

// 四科真实时长（不含倍率）
realEnglish, realMath, realPolitics, realMajor

// 方法
addDuration(subject, effectiveMinutes, realMinutes)  // 增加
deductDuration(subject, effectiveMinutes)            // 扣除
```

### streakStore.js — 连续签到

```js
currentDays      // 连续签到天数
currentMultiplier // 当前倍率（×1.1~×1.5）
maxDays          // 历史最长连续天数

// 倍率公式: min(1.5, 1.0 + currentDays × 0.1)
// 断签: currentDays 归零
```

### taskStore.js — 任务管理

```js
// 任务状态流转
pending → running → completed
pending → overdue → completed

// 关键方法
startTask(id)           // 开始倒计时
completeTask(id)        // 完成（计算真实/有效时长）
completeOverdueTask(id) // 逾期补完
editRealMinutes(id, m)  // 管理员编辑真实时长
undoTask(id)            // 撤销（回退时长）
deleteTask(id)          // 删除（回退时长）
```

### dataPersistence.js — 数据安全

```js
migrateData(data)       // 版本迁移（v0→v1: 学分→时长）
startAutoBackup()       // 每5分钟自动备份（保留10份）
exportData()            // 导出为 JSON 文件
importData(file)        // 导入（先自动备份当前数据）
```

---

## 数据存储

### 存储位置

```
Windows: C:\Users\<用户名>\AppData\Roaming\exam-game\config.json
```

### 数据安全

| 机制 | 频率 | 说明 |
|------|------|------|
| 自动保存 | 每5秒 | 写入 AppData |
| 自动备份 | 每5分钟 | 保留最近10份 |
| 版本迁移 | 启动时 | 自动转换旧格式 |
| 手动备份 | 随时 | 设置页一键操作 |
| 导入导出 | 随时 | JSON 文件 |

---

## 运行方式

```bash
# 安装依赖
npm install

# 开发模式（网页版）
npm run dev

# 开发模式（Electron 桌面版）
npm run electron:dev

# 构建生产版本
npm run build
```

---

## 已完成功能

| 功能 | 状态 |
|------|------|
| 学习时长系统（真实/有效/预定） | ✅ |
| 目标学校进度条 | ✅ |
| 连续签到倍率（×1.1~×1.5） | ✅ |
| 倒计时任务 + 截止日期任务 | ✅ |
| 超时自动标记逾期 | ✅ |
| 学习日历热力图 | ✅ |
| 四科雷达图 | ✅ |
| 成就徽章系统（24个） | ✅ |
| 管理员模式（撤销/编辑真实时长） | ✅ |
| 删除任务回退时长 | ✅ |
| 数据导入/导出 | ✅ |
| 自动备份 + 版本迁移 | ✅ |
| 日历历史任务回看 | ✅ |
| 桌面启动器（.vbs） | ✅ |

---

*文档结束*
