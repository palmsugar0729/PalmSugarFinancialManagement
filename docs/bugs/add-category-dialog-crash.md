---
date: 2026-06-08
tags: [pitfall, debug, flutter, dialog, state-management]
project: palmsugar
status: resolved
aliases: ["添加分类闪退", "dialog _dependents.isEmpty"]
---

# 添加分类 Dialog 关闭后闪退：`_dependents.isEmpty` 断言失败

**状态**：🟢 已解决
**发现日期**：2026-06-08
**关联**：[[2026-06-07_开发日志]] · [[category_page.dart]]

---

## 现象

在「分类管理」页面点击「添加分类」，弹出输入框后：
- 输入内容点击「添加」→ App 红屏闪退
- 不输入直接点击空白处关闭 → 闪退
- 点击「取消」→ 闪退

报错信息：
```
'package:flutter/src/widgets/framework.dart':
Failed assertion: line 6268 pos 12: '_dependents.isEmpty': is not true.
```

---

## 根因

`TextEditingController` 在 `showDialog` 的 **builder 外部**创建，在 dialog 关闭后手动调用 `controller.dispose()`。

但 `Navigator.pop()` 会立即 resolve future，dialog 的关闭动画还在进行。动画期间 widget tree 仍在引用 controller，此时外部代码执行到 `controller.dispose()`，导致 `EditableText` 的依赖关系（`_dependents`）未清理完毕就断开，触发断言失败。

因果链：
```
点击「添加」
  → Navigator.pop() 立即返回 result
    → 外部代码继续执行 _loadCategories() → setState()
      → 同时 dialog 关闭动画仍在运行
        → 代码执行到 controller.dispose()
          → widget tree 中还在引用的 dependants 未清空
            → _dependents.isEmpty 断言失败 → 红屏
```

---

## 解决方案

把 `TextEditingController` 的创建和销毁放到 dialog 的 **builder 内部**，让它随 dialog 自身的 dispose 自动清理，不再手动管理。

### 修改前（错误）

```dart
Future<void> _addCategory(String type) async {
  final controller = TextEditingController();  // ❌ 在 builder 外部
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      content: TextField(controller: controller),
      // ...
    ),
  );
  // ... 处理 result ...
  controller.dispose();  // ❌ dialog 动画还没完就 dispose
}
```

### 修改后（正确）

```dart
Future<void> _addCategory(String type) async {
  final result = await showDialog<String?>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();  // ✅ 在 builder 内部
      return AlertDialog(
        content: TextField(controller: controller),
        // ...
      );
    },
  );
  // ... 处理 result ...
  // ✅ 无需手动 dispose，dialog 关闭时自动清理
}
```

---

## 同时修复的另一个问题

**Hint 文本优化**：添加分类的输入框提示语原来固定为 `例如：健身、旅游`，现在根据当前 Tab 类型动态变化：

| 类型 | Hint 文本 |
|---|---|
| 支出 | `例如：健身、旅游` |
| 收入 | `例如：工资、奖金` |
| 转账 | `例如：支付宝转微信、银行卡转账` |

---

## 来源

- 项目代码：`codes/palmsugar/lib/pages/category_page.dart`
- 修复 commit：`_addCategory` / `_editCategory` 方法重构
