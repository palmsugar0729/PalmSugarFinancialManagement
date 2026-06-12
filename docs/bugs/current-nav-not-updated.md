---
date: 2026-06-13
tags: [bug, palmsugar, flutter, investment, nav]
project: palmsugar
aliases: ["买入后 current_nav 未更新导致市值=0"]
---

# 买入/卖出后 current_nav 未更新

## 现象

导入或录入买入交易后，持仓卡片上"持仓金额"显示为 ¥0.00，盈亏显示为亏损（成本全损），实际净值已知但未写入持仓表。

## 根因

`insertFundTransaction` 中，买入和卖出只更新了 `holding_shares` 和 `cost_amount`，但没有更新 `current_nav`。`holding_amount = holding_shares * (holding.currentNav ?? 0)`，当 `current_nav` 为 null/0 时市值为 0。

## 修复

买入和卖出时同步更新 `current_nav = ft.nav`，使市值计算基于最新交易净值。

## 关联

- [[fund-code-parsed-as-number]]
- [[开发日志]]
