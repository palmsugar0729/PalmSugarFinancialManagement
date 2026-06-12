---
date: 2026-06-12
tags: [bug, palmsugar, flutter, ui, form]
project: palmsugar
aliases: ["理财录入表单金额备注间距缺失"]
---

# 理财录入表单金额与备注间距缺失

## 现象

理财录入页（买入/卖出），金额输入框和备注输入框之间没有间距，视觉上连在一起。

## 根因

表单布局中，`_buildAmountInput()` 和 `_buildNoteInput()` 之间缺少 `SizedBox` 分隔。

## 修复

在金额字段后、备注字段前补上 `const SizedBox(height: 24)`。

**涉及文件**：`lib/pages/add_fund_transaction_page.dart`

## 关联

- [[fund-detail-button-style]]
- [[开发日志]]
