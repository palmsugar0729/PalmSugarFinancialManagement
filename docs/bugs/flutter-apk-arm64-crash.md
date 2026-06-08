---
date: 2026-06-08
tags: [pitfall, debug, flutter, android, apk, architecture, arm64]
project: palmsugar
status: resolved
aliases: ["真机闪退", "libflutter.so 缺失", "APK 架构不匹配"]
---

# 真机安装 Debug APK 闪退：找不到 `libflutter.so` (arm64-v8a)

**状态**：🟢 已解决
**发现日期**：2026-06-08
**关联**：[[2026-06-07_开发日志]] · [[flutter-apk-build]]

---

## 现象

将 `flutter build apk --debug` 生成的 APK 安装到真机（Android arm64）后，点击 App 图标直接闪退。

Logcat 关键报错：
```
java.lang.RuntimeException: Unable to start activity ...
Caused by: java.util.concurrent.ExecutionException:
  com.getkeepsafe.relinker.MissingLibraryException:
    Could not find 'libflutter.so'.
    Looked for: [arm64-v8a], but only found: [x86_64].
```

---

## 根因

APK 中只打包了 `x86_64` 架构的 `.so` 库（模拟器架构），而真机 CPU 是 `arm64-v8a`，启动时找不到对应架构的 `libflutter.so`，直接崩溃。

触发原因：之前编译时连接的 MuMu 模拟器是 x86_64 架构，Flutter 在某些情况下默认只编译当前连接设备的架构。

---

## 解决方案

显式指定 target platform 为 `android-arm64` 重新编译：

```bash
flutter build apk --debug --target-platform=android-arm64
```

验证 APK 包含 arm64 库：

```bash
unzip -l app-debug.apk | grep libflutter.so
# 输出：lib/arm64-v8a/libflutter.so
```

---

## 通用建议

| 场景 | 命令 |
|---|---|
| 只给真机（arm64） | `flutter build apk --debug --target-platform=android-arm64` |
| 兼容所有 Android 设备 | `flutter build apk --debug`（默认包含 arm64 + armeabi-v7a + x86_64）|
| 分包减小体积 | `flutter build apk --debug --split-per-abi`（生成多个 APK）|

---

## 来源

- 项目构建：`codes/palmsugar/build/app/outputs/flutter-apk/`
- 验证命令：`unzip -l app-debug.apk | grep libflutter.so`
