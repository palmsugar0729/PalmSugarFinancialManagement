---
date: 2026-06-12
tags: [bug, palmsugar, flutter, csv, export]
project: palmsugar
aliases: ["CSV导出乱码-bug"]
---

# CSV 导出乱码

## 现象

MuMu 模拟器测试，导出 CSV 文件后打开显示为乱码。

## 根因

Dart `csv` 包的 `ListToCsvConverter` 默认输出 UTF-8 without BOM（Byte Order Mark）。Windows 版 Excel/WPS 默认按系统编码（GBK）打开 CSV，导致中文乱码。

## 修复

导出 CSV 时在文件头部添加 UTF-8 BOM（`﻿`），让 Excel/WPS 自动识别为 UTF-8 编码。

**涉及文件**：`lib/pages/data_backup_page.dart`

## 关联

- [[PRD]]
- [[开发日志]]
