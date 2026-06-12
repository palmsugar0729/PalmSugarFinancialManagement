# 棕榈糖账本

个人财务管理 Flutter App — 记录收支、导入导出账单、管理理财交易。

## 技术栈

- **Flutter** — 跨平台移动开发框架
- **SQLite** — 纯本地数据存储（sqflite）

## 功能规划（MVP 分期）

### 第一期 ✅
- 手动收支录入 + 分类选择
- 分类管理体系
- 月度收支汇总
- 答案之书（趣味占卜功能）
- 金额计算器（输入表达式自动计算）

### 第二期 ✅
- Excel (.xlsx) 导入导出
- CSV 导入导出
- 月份切换（选择器 + 左右滑动）
- 分类图标选择 + 批量管理
- Slidable 左滑删除
- 收支分析图表（月度趋势、分类占比）

### 第三期
- 支付宝 / 微信账单导入（搁置，等人手）
- 理财交易管理（基金买卖、持仓概览、盈亏计算）
- 自定义图标
- 高级付费功能

## 项目结构

| 文件夹 | 用途 |
|---|---|
| `docs/` | 产品文档、决策记录、开发日志、踩坑记录 |
| `codes/` | 所有代码 |
| `assets/` | 设计素材、参考图、Bug 截图 |
| `notes/` | 学习笔记 |

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
```

生成的 APK 位于 `codes/palmsugar/build/app/outputs/flutter-apk/app-release.apk`。
