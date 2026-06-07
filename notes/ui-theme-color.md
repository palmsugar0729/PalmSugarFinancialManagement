---
name: ui-theme-color
description: App 主色调偏好为 #A3C1AD
metadata:
  type: project
---

用户指定 App 主色调为 `#A3C1AD`（柔和薄荷绿/鼠尾草绿）。

当前 `main.dart` 中使用的是 `Colors.teal`（蓝绿色），需要在实机测试修 bug 阶段统一替换为 `#A3C1AD`。

**涉及修改的文件**：
- `lib/main.dart` — `ColorScheme.fromSeed(seedColor: ...)`
- `lib/pages/home_page.dart` — 分类图标背景色、类型颜色（可能需要微调搭配色）
- `lib/pages/add_record_page.dart` — 类型选择器颜色、分类 chip 颜色
- `lib/pages/category_page.dart` — 分类图标颜色

**建议搭配色**：
- 主色：`#A3C1AD`（柔和绿）
- 支出：保持 `Colors.red` 或微调为 `#E57373`
- 收入：保持 `Colors.green` 或 `#66BB6A`
- 转账：`Colors.blue` 或 `#64B5F6`
- 背景/表面：根据 Material 3 自动生成
