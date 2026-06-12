---
date: 2026-06-12
tags: [bug, palmsugar, flutter, investment, ui]
project: palmsugar
aliases: ["基金管理缺少新增按钮-bug"]
---

# 基金管理缺少新增按钮

## 现象

基金管理页面（理财 Tab 右上角 → 设置图标）只能编辑和删除已有基金，没有新增基金的入口。

## 根因

页面设计遗漏，未添加新增按钮。

## 修复

在基金管理页添加 FAB（+ 按钮），点击弹出对话框填写基金名称、代码、类型，保存到 `fund_holdings` 表。

## 关联

- [[PRD]]
- [[开发日志]]
