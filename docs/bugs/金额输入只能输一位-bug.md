---
date: 2026-06-08
tags: [pitfall, debug, flutter, textfield, regex, input-formatter]
project: palmsugar
status: resolved
aliases: ["金额输入只能输一位", "InputFormatter 正则错误"]
---

# 金额输入框只能输入单个数字

**状态**：🟢 已解决
**发现日期**：2026-06-08
**关联**：[[2026-06-08_开发日志]] · [[add_record_page.dart]]

---

## 现象

在「记一笔」页面点击金额输入框，输入第一个数字正常，输入第二个数字时键盘无反应，无法继续输入。

---

## 根因

修改 `inputFormatters` 时，正则表达式只匹配**单个字符**：

```dart
// ❌ 错误：只匹配一个字符
FilteringTextInputFormatter.allow(RegExp(r'^[\d\+\-\*\/\.]' ))
```

`FilteringTextInputFormatter.allow` 的工作原理：每次输入新字符后，检查**整个字符串**是否匹配正则。当输入第二个数字时，字符串变为 `"12"`，正则只要求匹配一个字符， `"12"` 不匹配，于是第二个字符被过滤。

---

## 解决方案

将正则改为匹配**任意长度**的有效字符序列：

```dart
// ✅ 正确：匹配任意长度的数字/运算符/小数点
FilteringTextInputFormatter.allow(RegExp(r'^[\d+\-*/.]*$'))
```

- `^...$`：从头到尾完整匹配整个字符串
- `[\d+\-*/.]*`：0 个或多个数字 / `+` / `-` / `*` / `/` / `.`

---

## 来源

- 项目代码：`codes/palmsugar/lib/pages/add_record_page.dart`
- 引入 commit：添加金额计算器功能时修改 `inputFormatters`
