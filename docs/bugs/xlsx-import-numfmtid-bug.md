---
date: 2026-06-12
tags: [pitfall, flutter, excel, bugfix]
project: palmsugar
status: resolved
aliases: ["xlsx 导入 numFmtId 崩溃"]
---

# xlsx 导入崩溃：custom numFmtId starts at 164 but found a value of 7

**状态**：🟢 已解决（workaround + 替代方案）
**发现日期**：2026-06-12
**关联**：[[开发日志]] · [[对话记录_2026-06-12]]

## 现象

用户在「数据备份」页面导入 `.xlsx` 文件时，App 直接崩溃并提示：

```
导入失败: Exception: custom numFmtId starts at 164 but found a value of 7
```

## 根因

Dart 包 [`excel`](https://pub.dev/packages/excel)（justkawal/excel）在解析 `.xlsx` 时，严格断言「自定义数字格式 ID（numFmtId）必须 ≥ 164」。

然而，**WPS Office**、**Mac Numbers** 以及某些旧版 Microsoft Excel 在生成 `.xlsx` 时，会将自定义格式 ID 写入小于 164 的值（如 7、41、42 等）。这导致 `excel` 包的 `parse.dart` 在第 164 行检查处抛出异常。

相关上游 Issue：
- [justkawal/excel#296](https://github.com/justkawal/excel/issues/296)
- [justkawal/excel#399](https://github.com/justkawal/excel/issues/399)

## 解决方案

### 根本修复（上游未发布）

上游仓库中已有 PR 尝试放宽此断言，但截至 `excel: 4.0.6`（2025-04）仍未合并到 Pub.dev 版本。

### 本项目 workaround

1. **捕获特定异常并给出友好提示**
   在 `data_backup_page.dart` 的导入逻辑中，捕获包含 `numFmtId` 的异常，提示用户：
   > "该 Excel 文件格式不兼容，可能是由 WPS 或 Numbers 生成的。建议将文件另存为 CSV 格式后再导入，或直接使用本 App 导出的 .xlsx 文件。"

2. **同步增加 CSV 导入导出支持**
   引入 `csv: ^6.0.0` 依赖，让 CSV 成为可靠的替代方案。CSV 是纯文本格式，不受 WPS/Excel 内部格式差异影响。

## 关键代码

```dart
// lib/pages/data_backup_page.dart
try {
  final excel = Excel.decodeBytes(bytes);
  // ...
} catch (e) {
  final msg = e.toString();
  if (msg.contains('numFmtId')) {
    throw Exception(
      '该 Excel 文件格式不兼容，可能是由 WPS 或 Numbers 生成的。'
      '建议将文件另存为 CSV 格式后再导入，或直接使用本 App 导出的 .xlsx 文件。',
    );
  }
  rethrow;
}
```

## 预防

- [ ] 关注上游 `excel` 包版本更新，若后续版本修复此问题，可移除 workaround
- [ ] 在 App 使用说明中提示：推荐使用本 App 导出的 `.xlsx` 或 `.csv` 文件进行导入
