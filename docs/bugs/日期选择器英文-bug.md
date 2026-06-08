---
date: 2026-06-08
tags: [pitfall, ui, localization, i18n]
project: palmsugar
status: resolved
aliases: ["日期选择器英文", "showDatePicker 中文"]
---

# 日期选择器显示英文

**状态**：🟢 已解决
**发现日期**：2026-06-08
**关联**：[[2026-06-08_开发日志]] · [[add_record_page.dart]]

---

## 现象

「记一笔」页面点击日期选择，弹出的 `showDatePicker` 显示英文：
- `Select date`
- `Mon, Jun 8`
- `Cancel` / `OK`

---

## 根因

`MaterialApp` 未配置中文 locale，`showDatePicker` 默认使用系统 locale（或英文 fallback）。

---

## 解决方案

1. `pubspec.yaml` 添加依赖：

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

2. `main.dart` 配置 locale：

```dart
MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('zh', 'CN')],
  locale: const Locale('zh', 'CN'),
)
```

3. `intl` 升级到 `^0.20.2` 以兼容 `flutter_localizations`。

---

## 来源

- 项目代码：`codes/palmsugar/lib/main.dart`
- 依赖配置：`codes/palmsugar/pubspec.yaml`
