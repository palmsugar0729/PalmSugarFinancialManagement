# 棕榈糖账本

个人财务管理 Flutter App — 记录收支、管理理财、导入导出、图表分析。

## 技术栈

- **Flutter** — 跨平台移动开发框架（Material 3）
- **SQLite** — 纯本地数据存储（sqflite）
- **fl_chart** — 图表
- **excel / csv** — 导入导出
- **flutter_slidable** — 左滑删除

## 功能概览

### 首页（记账）
- 手动收支录入（金额计算器、日期选择、分类选择、备注）
- 月度收支汇总卡片 → 点击进入图表分析
- 当月交易列表：左滑删除、长按多选批量删除
- 月份切换（选择器 + 左右滑动）
- 数据备份入口（导入导出）

### 分析
- 月度收支趋势柱状图
- 支出/收入分类饼图
- 点击分类查看当月交易明细

### 理财
- 基金持仓列表（市值居中大字 + 成本/收益/收益率）
- 点击持仓卡片 → 基金详情（净值更新 + 快捷买入/卖出/分红）
- 交易记录：左滑删除、长按多选批量删除
- 基金管理（新增/编辑/删除基金）
- 投资分析（总览 + 持仓占比饼图 + 基金市值对比柱状图）
- 买入/卖出/分红录入（手续费 + 净值 + 份额 → 自动算金额）
- 基金代码联网查名称（天天基金接口）
- 自动同步到首页：买入→transfer"投资"、卖出→transfer"赎回"、手续费→expense、分红→income"投资收益"
- 成本采用移动加权平均法

### 答案之书
- 趣味占卜，自定义词条（`answers_template.json`）

### 导入导出
- Excel：一个文件三个 Sheet（收支记录 + 理财记录 + 分类表）
- CSV：UTF-8 BOM 编码，包含收支和理财两段
- 导出选项：选择内容（全部/收支/理财）+ 时间范围（近1月/近3月/自定义）
- 导入自动识别格式，不存在的基金自动创建，重复分类自动跳过

## 项目结构

| 文件夹 | 用途 |
|---|---|
| `docs/` | PRD、数据库设计、开发日志、bug 记录 |
| `codes/palmsugar/` | Flutter 源码 |
| `assets/bug/` | Bug 截图 |
| `memory/` | AI 辅助记忆 |

## 快速开始

```bash
cd codes/palmsugar
flutter pub get
flutter run
```

## 构建 Release APK

```bash
cd codes/palmsugar
flutter build apk --release
# APK 输出到 build/app/outputs/flutter-apk/app-release.apk
# 根目录也有副本：棕榈糖账本_YYYYMMDD.apk
```

## 数据库版本

| 版本 | 内容 |
|------|------|
| v1 | categories、transactions、answers |
| v2 | 新增 fund_holdings、fund_transactions（理财模块） |
