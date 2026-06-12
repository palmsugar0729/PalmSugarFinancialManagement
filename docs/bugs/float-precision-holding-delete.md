---
date: 2026-06-12
tags: [bug, palmsugar, flutter, float]
project: palmsugar
aliases: ["浮点精度导致删除基金提示仍有持仓"]
---

# 浮点精度导致删除基金失败

## 现象

基金管理中删除基金时，明明已删干净所有交易记录，仍然提示"该基金还有持仓"。

## 根因

`fund_holdings.holding_shares` 经过多次买入/卖出交易（加减份额）后，因浮点运算可能残留极小值（如 0.0000000001）。`> 0` 的严格判断将此视为"有持仓"。

## 修复

将判断条件从 `> 0` 改为 `> 0.001`（容差 0.001 份），并显示具体持仓份额数。

**涉及文件**：`lib/pages/fund_management_page.dart`

## 关联

- [[开发日志]]
