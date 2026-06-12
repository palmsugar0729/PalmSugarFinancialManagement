---
date: 2026-06-12
tags: [bug, palmsugar, flutter, investment, fee]
project: palmsugar
aliases: ["手续费未拆分为支出-bug"]
---

# 手续费未拆分为支出

## 现象

理财交易（买入/卖出）录入时，手续费包含在 transfer 金额中，未单独记录为支出。

用户在收支总览中看不到手续费支出明细，且月度支出统计不准确。

## 根因

`insertFundTransaction` 中，同步到首页只生成了 1 条 transfer 记录，金额包含手续费。手续费应单独记为 expense。

## 修复

- **买入**：同步 2 条 → `transfer`（投资金额 = 份额 × 净值）+ `expense`（手续费，分类=「手续费」）
- **卖出**：同步 2 条 → `transfer`（卖出所得 = 份额 × 净值）+ `expense`（手续费）
- 删除交易时同时清理对应的 expense 记录
- 自动创建「手续费」支出分类（如不存在）

## 关联

- [[PRD]]
- [[开发日志]]
