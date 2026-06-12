---
date: 2026-06-12
tags: [bug, palmsugar, flutter, ui]
project: palmsugar
aliases: ["基金选择器文本溢出"]
---

# 基金下拉选择器文本溢出

## 现象

理财录入页的基金下拉框中，长基金名称（如"摩根纳斯达克100指数（QDII）A (019172)"）超出下拉框宽度，显示不完整。

## 修复

- 显示格式改为 "019172 摩根纳斯达克..."（代码在前，名称在后）
- 添加 `TextOverflow.ellipsis` 超出部分用省略号

**涉及文件**：`lib/pages/add_fund_transaction_page.dart`

## 关联

- [[开发日志]]
