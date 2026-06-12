---
date: 2026-06-12
tags: [pitfall, flutter, ui, bugfix]
project: palmsugar
status: resolved
aliases: ["日期选择后焦点回跳键盘弹出"]
---

# 日期选择后焦点回跳、键盘自动弹出

**状态**：🟢 已解决
**发现日期**：2026-06-12
**关联**：[[开发日志]] · [[对话记录_2026-06-12]]

## 现象

在「记一笔」页面：
1. 先点击金额输入框或备注输入框输入内容
2. 再点击日期选择器选择日期
3. 点击日期选择器的「确定」
4. 日期选择器关闭后，**键盘自动弹出，焦点回到之前的输入框**（如金额框）

## 根因

Flutter 的 `showDatePicker` 是一个 `Route`，关闭时会从导航栈中弹出。弹出后，之前拥有焦点的 `TextField` 的 `FocusNode` 会重新获得焦点，导致软键盘弹出。

## 解决方案

在弹出日期选择器之前，主动取消当前焦点：

```dart
// lib/pages/add_record_page.dart
Future<void> _selectDate() async {
  FocusScope.of(context).unfocus();  // ← 新增
  final picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 1)),
  );
  if (picked != null) {
    setState(() {
      _selectedDate = picked;
    });
  }
}
```

## 预防

- [ ] 项目中所有调用 `showDatePicker`、`showTimePicker`、`showModalBottomSheet` 等弹窗的地方，若前面可能有输入框焦点，统一在弹出前调用 `FocusScope.of(context).unfocus()`
