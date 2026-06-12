---
date: 2026-06-13
tags: [bug, palmsugar, flutter, import, xlsx]
project: palmsugar
aliases: ["基金代码前导0丢失"]
---

# Excel 导入时基金代码前导 0 丢失

## 现象

Excel 中基金代码为 "019172"，导入后显示为 "19172" 或 "19172.0"（前导 0 丢失）。

## 根因

Excel 可能把纯数字基金代码存为 numeric 类型，读取时得到 `19172.0`（double），`.toString()` 后变成 "19172.0"。

## 修复

导入时检测基金代码长度，不足 6 位自动 `padLeft(6, '0')` 补齐。显示时也做同样处理。

## 关联

- [[fund-code-parsed-as-number]]
- [[开发日志]]
