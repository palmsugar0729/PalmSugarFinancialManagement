---
date: 2026-06-09
tags: [pitfall, flutter, crash, reorderablelistview]
project: palmsugar
status: resolved
aliases: ["分类管理页面崩溃"]
---

# 分类管理页面点进去直接报错/崩溃

**状态**：🟢 已解决
**发现日期**：2026-06-09
**关联**：[[2026-06-09 开发日志]]

## 现象

点击「分类管理」后，三个 Tab（支出/收入/转账）都直接报错/崩溃。

## 根因

1. **使用了 `ReorderableDelayedDragStartListener`**：该 widget 包裹在 `Card` 外层作为 `ReorderableListView` 的 item，但其手势识别机制与 `Card` -> `ListTile` 的嵌套结构存在兼容性问题，导致运行时找不到 ancestor `SliverReorderableListState` 或手势冲突崩溃。
2. **key 位置错误**：`Card` 有 key 而外层 `ReorderableDelayedDragStartListener` 没有，`ReorderableListView` 需要 item 的最外层 widget 携带 key 来跟踪位置。

## 解决方案

将 `ReorderableDelayedDragStartListener`（长按拖动）替换为 `ReorderableDragStartListener`（点击拖动），并在 trailing 中显式放置拖动图标 `Icons.drag_handle`。

```dart
// 修复前（崩溃）
return ReorderableDelayedDragStartListener(
  index: index,
  child: Card(key: ValueKey('...'), child: ListTile(...)),
);

// 修复后（稳定）
return Card(
  key: ValueKey('category_${category.id}'),
  child: ListTile(
    ...
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton(...),
        ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
      ],
    ),
  ),
);
```

## 相关文件

- `lib/pages/category_page.dart`

## 预防

- [ ] `ReorderableListView` 的 item 最外层必须携带 key，且避免使用可能存在兼容性问题的 widget 包裹
- [ ] 自定义拖动行为时，优先使用官方推荐的 `ReorderableDragStartListener` + 显式 handle 方式，而非隐藏/透明 handle 的 hack 方案
- [ ] 模拟器测试通过后再提交，注意覆盖「分类管理」等二级页面
