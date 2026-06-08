---
date: 2026-06-08
tags: [pitfall, ui, color, finance]
project: palmsugar
status: resolved
aliases: ["收入支出颜色反了", "红涨绿跌"]
---

# 收入/支出颜色与理财习惯相反

**状态**：🟢 已解决
**发现日期**：2026-06-08
**关联**：[[2026-06-08_开发日志]]

---

## 现象

收入显示为绿色，支出显示为红色，与中国股市/理财习惯「红涨绿跌」相反，后续接入理财功能后容易混淆。

---

## 根因

默认配色逻辑：
- 支出 = `Colors.red`（消费警示）
- 收入 = `Colors.green`（正向反馈）

未考虑理财场景的统一性。

---

## 解决方案

统一改为「红涨绿跌」：
- 收入 → `Colors.red`（涨）
- 支出 → `Colors.green`（跌）
- 转账 → `Colors.blue`（不变）

涉及文件：
- `lib/pages/home_page.dart`
- `lib/pages/add_record_page.dart`
- `lib/pages/category_page.dart`

---

## 来源

- 项目代码：`codes/palmsugar/lib/pages/*.dart`
