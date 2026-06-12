---
date: 2026-06-12
tags: [bug, palmsugar, flutter, import, csv]
project: palmsugar
aliases: ["导入基金代码被当数字解析"]
---

# 导入理财记录时基金代码被误判为金额

## 现象

导入理财 CSV/Excel 文件，基金代码（如 "019172"）被 `double.tryParse` 成功解析为 19172.0，导致格式检测逻辑误判为旧格式（无基金代码列），金额和净值列错位。

## 根因

`_importFundTransactionRows` 中通过检查 `row[3]` 能否被解析为数字来区分新旧格式。但 6 位纯数字基金代码可以通过 `double.tryParse` 检查，导致误判。

## 修复

改为从表头检测格式：检查表头行是否包含 "基金代码" 列名，而不是从数据行猜测。

**涉及文件**：`lib/pages/data_backup_page.dart` — `_importFundTransactionRows` 方法

## 关联

- [[csv-export-garbled-bug]]
- [[开发日志]]
