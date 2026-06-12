---
name: slidable-delete-pattern
description: 左滑删除 UI 模式 — flutter_slidable
metadata:
  type: project
---

# 左滑删除模式

使用 `flutter_slidable` 包实现列表项左滑露出删除按钮。

```dart
Slidable(
  key: ValueKey('unique_prefix_${item.id}'),
  endActionPane: ActionPane(
    motion: const ScrollMotion(),
    extentRatio: 0.2,
    children: [
      CustomSlidableAction(
        onPressed: (_) => _deleteItem(item.id!),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.zero,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, size: 20),
            SizedBox(height: 2),
            Text('删除', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ],
  ),
  child: Card(...),  // or ListTile
);
```

已应用的位置：
- [[home_page.dart]] — 收支记录
- [[investment_page.dart]] — 理财交易记录
- [[fund_detail_page.dart]] — 基金交易记录

**Why:** 用户偏好无确认弹窗的快速删除，左滑直接触发
**How to apply:** 新增列表项删除时照此模板，不需要确认对话框
