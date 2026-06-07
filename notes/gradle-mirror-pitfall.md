---
date: 2026-06-07
tags: [pitfall, debug, gradle, flutter, android, maven, network, setup]
project: palmsugar
status: resolved
aliases: ["Gradle 下载超时", "Flutter 编译卡慢"]
---

# Flutter 首次编译 APK 时 Gradle 依赖下载超时

**状态**：🟢 已解决
**发现日期**：2026-06-07
**关联**：[[2026-06-07_开发日志]] · [[2026-06-07_Gradle 国内镜像配置]]

---

## 现象

运行 `flutter build apk --debug` 时长时间无响应，终端卡在 Gradle 初始化阶段。`flutter doctor -v` 同时报网络超时：

```
X A network error occurred while checking "https://maven.google.com/": 信号灯超时时间已到
X An HTTP error occurred while checking "https://github.com/": 信号灯超时时间已到
```

Gradle 首次编译需要从以下地址下载大量依赖：
- Android Gradle Plugin（`maven.google.com`）
- Gradle Wrapper 本体（`services.gradle.org`）
- Kotlin Gradle Plugin（`gradlePluginPortal()`）
- 第三方库（`mavenCentral()`）

国内直接访问这些地址几乎无法完成。

---

## 根因

1. **Flutter 模板默认使用国外 Maven 仓库**：`google()`、`mavenCentral()`、`gradlePluginPortal()` 均指向海外服务器。
2. **Gradle Wrapper 默认从 `services.gradle.org` 下载**：即使本地已安装 Gradle，Wrapper 仍会校验/下载指定版本。
3. **首次编译无本地缓存**：`~/.gradle/caches/` 为空时，所有依赖必须实时拉取，网络问题被放大。

因果链：

```
首次编译 APK
  → Gradle Wrapper 启动
    → 下载 gradle-9.1.0-all.zip（services.gradle.org）→ 超时
      → 或：下载 Android Gradle Plugin 9.0.1（maven.google.com）→ 超时
        → 编译卡住，无进度条更新
```

---

## 解决方案

### 走过的弯路

| 尝试 | 结果 | 原因 |
|---|---|---|
| 清华镜像 `mirrors.tuna.tsinghua.edu.cn/gradle/gradle-9.1.0-all.zip` | ❌ 404 | 路径错误 |
| 清华镜像 `.../gradle/distributions/v9.1.0/gradle-9.1.0-all.zip` | ❌ 404 | 镜像站未同步该版本 |
| 清华镜像 Maven 仓库 + AGP 9.0.1 | ❌ 找不到插件 | 镜像站未同步 AGP 9.0.1 |
| 清华镜像 Maven 仓库 + AGP 8.8.0 | ❌ 找不到插件 | 镜像站未同步 AGP 8.8.0 marker artifact |
| **腾讯云 Gradle + 阿里云 Maven + AGP 8.8.0** | ✅ **通过** | 腾讯云有 Gradle 9.1.0，阿里云 public 聚合仓库覆盖 Google Maven / Central / Gradle Plugin |

### 最终修复

#### 1. Gradle Wrapper — 腾讯云镜像

`android/gradle/wrapper/gradle-wrapper.properties`：

```properties
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-9.1.0-all.zip
```

> 原配置：`https\://services.gradle.org/distributions/gradle-9.1.0-all.zip`

#### 2. 插件管理仓库 — 阿里云聚合仓库

`android/settings.gradle.kts`：

```kotlin
pluginManagement {
    // ... flutterSdkPath 逻辑保持不变 ...

    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        mavenLocal()
    }
}
```

同时降级 AGP 版本：

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.8.0" apply false  // 原 9.0.1
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}
```

#### 3. 项目级仓库 — 阿里云聚合仓库

`android/build.gradle.kts`：

```kotlin
allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        mavenLocal()
    }
}
```

---

## 验证

```bash
cd codes/palmsugar
flutter clean
flutter build apk --debug
```

预期结果：
- Gradle Wrapper 从腾讯云快速下载（数秒到数十秒）
- AGP / Kotlin 插件 / 第三方库 从阿里云正常拉取
- 首次编译会自动安装 NDK、Build-Tools、SDK Platform（耗时较长，属正常）
- 最终生成 `build/app/outputs/flutter-apk/app-debug.apk`

---

## 预防

- [x] 新 Flutter 项目初始化后，第一时间检查 `android/build.gradle.kts` 和 `settings.gradle.kts` 中的仓库配置
- [x] 若清华镜像未同步目标版本，优先尝试阿里云 `public` 聚合仓库
- [ ] 建立项目脚手架时，将镜像配置纳入模板
- [ ] 关注 Flutter 对 AGP 的最低版本要求（当前 warning 建议 ≥8.11.1）

---

## 备选镜像对照

| 镜像源 | Gradle Distribution | Google Maven | Maven Central | Gradle Plugin |
|---|---|---|---|---|
| **腾讯云** | ✅ `mirrors.cloud.tencent.com/gradle/` | ❌ | ❌ | ❌ |
| **阿里云** | ❌ | ✅ `maven.aliyun.com/repository/google` | ✅ `maven.aliyun.com/repository/central` | ✅ `maven.aliyun.com/repository/gradle-plugin` |
| **清华** | ❌（未同步 9.1.0） | ✅ `repository/maven-google/` | ✅ `repository/maven/` | ⚠️ 可能缺失 marker artifact |
| **华为云** | ✅ `mirrors.huaweicloud.com/gradle/` | ✅ `repo.huaweicloud.com/repository/maven` | 同上 | ❌ |

> **实战经验**：Gradle Wrapper 和 Maven 仓库需要分别找不同的镜像源，不要指望一家镜像能全覆盖。

---

## 来源

- 项目代码：`codes/palmsugar/android/build.gradle.kts`
- 项目代码：`codes/palmsugar/android/settings.gradle.kts`
- 项目代码：`codes/palmsugar/android/gradle/wrapper/gradle-wrapper.properties`
