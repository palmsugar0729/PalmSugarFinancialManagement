---
date: 2026-06-09
tags: [pitfall, flutter, excel, import, date-format]
project: palmsugar
status: resolved
aliases: ["Excel 导入失败：未解析到有效记录"]
---

# Excel 导入失败：未解析到有效记录

**状态**：🟢 已解决
**发现日期**：2026-06-09
**关联**：[[2026-06-09 开发日志]] · [[excel-export-format-bugs]]

## 现象

用户上传的 Excel 文件（`docs/棕榈糖账本上传用.xlsx`）导入时提示：「未解析到有效记录」。

## 根因分析

1. **日期格式不匹配**：用户 Excel 中的日期格式为 `2026-06-09T00:00:00.000Z`（ISO 8601），而导入代码只支持 `yyyy-MM-dd HH:mm:ss`
2. **列结构不一致**：导出时包含「二级分类」「ID」「图标」等列，但用户认为这些不必要
3. **excel.delete() 不生效**：`excel` 包中 `delete('Sheet1')` 方法在 v4.0.6 中无效，导致导出文件仍包含空白 Sheet1

## 解决方案

### 1. 日期解析兼容多种格式

```dart
DateTime? _parseDate(String str) {
  str = str.trim();
  // 先尝试 yyyy-MM-dd
  try {
    return DateFormat('yyyy-MM-dd').parseLoose(str);
  } catch (_) {}
  // 再尝试 ISO 8601
  try {
    return DateTime.parse(str);
  } catch (_) {}
  return null;
}
```

### 2. 简化 Excel 列结构

**收支记录 Sheet**：日期、类型、分类、金额、备注（去掉二级分类）
**分类表 Sheet**：名称、类型、排序（去掉 ID、图标）

### 3. 正确删除默认 Sheet1

```dart
// excel.delete('Sheet1') 不生效，改用 rename
excel.rename('Sheet1', '收支记录');
```

### 4. 分类管理增强

- 预设分类开放编辑/删除
- 添加/编辑分类时可选择预设图标
- 支持拖动排序

## 相关文件

- `lib/pages/data_backup_page.dart`
- `lib/pages/category_page.dart`
- `lib/database/db_helper.dart`

## 预防

- [ ] 日期解析应兼容常见格式（yyyy-MM-dd、ISO 8601、yyyy/MM/dd 等）
- [ ] 导入前打印/显示解析到的样本数据，方便排查格式问题
- [ ] 使用第三方库 API 时，先验证方法是否真正生效
