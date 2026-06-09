---
date: 2026-06-09
tags: [pitfall, flutter, excel, export, bugfix]
project: palmsugar
status: resolved
aliases: ["Excel 导出格式问题汇总"]
---

# Excel 导出格式问题汇总

**状态**：🟢 已解决
**发现日期**：2026-06-09
**关联**：[[share-plus-no-handler-bug]] · [[2026-06-09 开发日志]]

## 现象

导出 Excel 后检查发现以下问题：

1. **多一个空白 Sheet**：文件里除了「收支记录」「分类表」外，还多了一个叫 `Sheet1` 的空白 Sheet
2. **日期列带时分秒**：例如 `2026-06-08 00:00:00`，用户期望只显示 `yyyy-MM-dd`
3. **分类表 ID 看起来混乱**：导出的分类表包含了已删除（软删除）的分类，且未按 ID 排序
4. **share_plus 仍会弹窗**：修复后虽然文件能保存到 Downloads，但 `share_plus` 自动调用仍会触发系统「没有应用可执行此操作」提示

## 根因

| # | 问题 | 根因 |
|---|---|---|
| 1 | 空白 Sheet1 | `Excel.createExcel()` 默认会自动创建一个名为 `Sheet1` 的 sheet |
| 2 | 日期带时分秒 | 导出时使用了 `DateFormat('yyyy-MM-dd HH:mm:ss')` |
| 3 | 分类表 ID 混乱 | 使用了 `getAllCategoriesWithDeleted()`，包含 `is_deleted=1` 的记录；排序按 `type+sort_order` 而非 ID |
| 4 | share_plus 弹窗 | `try-catch` 无法捕获 Android 系统级「无可用应用」对话框，它不是异常抛出 |

## 解决方案

### 修复代码（`lib/pages/data_backup_page.dart`）

```dart
// 1. 删除默认 Sheet1
if (excel.sheets.containsKey('Sheet1')) {
  excel.delete('Sheet1');
}

// 2. 日期只保留 yyyy-MM-dd
final dateStr = DateFormat('yyyy-MM-dd')
    .format(DateTime.fromMillisecondsSinceEpoch(t.date));

// 3. 分类表过滤已删除 + 按 ID 排序
final activeCategories = categories
    .where((c) => c.isDeleted == 0)
    .toList()
  ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

// 4. share_plus 改为用户主动触发
// 保存成功后只显示 SnackBar，其中带一个「分享」Action 按钮
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('导出成功，文件已保存到：下载/$fileName'),
    duration: const Duration(seconds: 4),
    action: SnackBarAction(
      label: '分享',
      onPressed: () => _shareFile(savedPath!, fileName),
    ),
  ),
);
```

## 相关文件

- `lib/pages/data_backup_page.dart`
- `lib/pages/category_page.dart`（预设分类开放编辑删除）

## 预防

- [ ] 使用 `excel` 包时，注意 `createExcel()` 会自带一个 Sheet1，需要显式删除
- [ ] 分享类插件在调用前，最好检测是否有可用应用，或改为用户主动触发
- [ ] 导出数据时，软删除字段 `is_deleted` 必须过滤，避免导出已删除数据
