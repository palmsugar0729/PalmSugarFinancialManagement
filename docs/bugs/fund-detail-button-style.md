---
date: 2026-06-12
tags: [bug, palmsugar, flutter, ui, fund-detail]
project: palmsugar
aliases: ["基金详情快捷按钮底色难看"]
---

# 基金详情页快捷按钮底色难看

## 现象

基金详情页的买入/卖出/分红快捷按钮使用 `color.withAlpha(30)` 做背景色，视觉上显得脏、不干净。

## 根因

`ElevatedButton` + `backgroundColor: color.withAlpha(30)` 在某些 Material 主题下效果差。

## 修复

改为 `OutlinedButton` + `BorderSide(color: color.withAlpha(100))`，轮廓线风格，干净清晰。

**涉及文件**：`lib/pages/fund_detail_page.dart` — `_quickActionButton` 方法

## 关联

- [[invest-form-spacing-bug]]
- [[开发日志]]
