# KeepFlow

中文 | [English](#english)

KeepFlow（心流）是一个 macOS 快速记录工具。它通过全局快捷键呼出一个类似 Raycast / Spotlight 的浮层，让你在不中断当前工作的前提下，快速捕捉任务、关注事项和灵感。

Slogan:
`Keep your flow, capture your thoughts`

## 中文

### 产品定位

KeepFlow 是一个“思维缓冲层”。

核心目标：
- 即时捕捉
- 尽量零打断
- 先记录，后整理

典型操作路径：
`Shift + Space -> 输入 -> Enter -> 关闭`

### 当前功能

- 全局快捷键唤起浮层窗口
- 菜单栏常驻运行，无 Dock 图标
- 输入内容后按 `Enter` 保存
- `Esc` 或 `Shift + Enter` 关闭窗口
- 支持任务列表展示、选择和完成
- 支持分页加载更多任务
- 支持 SQLite 持久化
- 支持多语言
  - 简体中文
  - English
  - 日本語
  - 한국어
  - Français
  - Deutsch
  - Italiano
  - 繁體中文
- 设置中可选择语言，默认跟随系统

### 技术栈

- SwiftUI + AppKit
- Carbon API 全局快捷键
- SQLite + GRDB
- MVVM + Repository
- XcodeGen + Swift Package Manager

### 项目结构

```text
KeepFlow/
├── KeepFlow/
│   ├── App/           # 启动、状态栏、设置
│   ├── System/        # 窗口与事件管理
│   ├── Services/      # 快捷键、任务逻辑
│   ├── Storage/       # GRDB / SQLite 持久化
│   ├── ViewModels/    # 视图状态
│   ├── UI/            # SwiftUI 界面
│   ├── Utils/         # 常量、本地化、图标工具
│   └── Assets.xcassets
├── docs/
├── project.yml
└── KeepFlow.xcodeproj
```

### 本地开发

要求：
- macOS 13+
- Xcode 15+
- `xcodegen`

首次或修改 `project.yml` / 新增文件后：

```bash
xcodegen generate
```

Debug 构建：

```bash
xcodebuild -project KeepFlow.xcodeproj -scheme KeepFlow -configuration Debug build
```

Release 构建：

```bash
xcodebuild -project KeepFlow.xcodeproj -scheme KeepFlow -configuration Release build
```

如果本机 `xcode-select` 指向的是 Command Line Tools，可以显式指定完整 Xcode：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project KeepFlow.xcodeproj \
  -scheme KeepFlow \
  -configuration Release \
  build
```

### 打包

Release 构建完成后，可生成安装包：

```bash
productbuild \
  --component build/Build/Products/Release/KeepFlow.app \
  /Applications \
  KeepFlow-1.0.0.pkg
```

仓库中当前已有示例安装包：
[KeepFlow-1.0.0.pkg](/Users/zwli/myai_projects/KeepFlow/KeepFlow-1.0.0.pkg)

### 相关文档

- [PRD](/Users/zwli/myai_projects/KeepFlow/docs/prd.md)
- [开发计划](/Users/zwli/myai_projects/KeepFlow/docs/development_plan.md)
- [领域模型](/Users/zwli/myai_projects/KeepFlow/docs/domain_model.md)
- [技术设计](/Users/zwli/myai_projects/KeepFlow/docs/tech_detail_design_spec.md)

## English

### What It Is

KeepFlow is a macOS thought capture tool built for fast, low-interruption note and task capture.

It opens a lightweight launcher-style panel with a global shortcut so you can record an idea and return to your flow immediately.

Typical flow:
`Shift + Space -> type -> Enter -> close`

### Features

- Global shortcut to open a launcher-style floating panel
- Menu bar app with no Dock icon
- Save input with `Enter`
- Close with `Esc` or `Shift + Enter`
- Task list display, selection, and completion
- Paginated loading for more tasks
- SQLite persistence with GRDB
- Built-in localization
  - Simplified Chinese
  - English
  - Japanese
  - Korean
  - French
  - German
  - Italian
  - Traditional Chinese
- Language can be selected in Settings, default is Follow System

### Stack

- SwiftUI + AppKit
- Carbon API for global shortcuts
- SQLite + GRDB
- MVVM + Repository pattern
- XcodeGen + Swift Package Manager

### Development

Requirements:
- macOS 13+
- Xcode 15+
- `xcodegen`

Regenerate the project after changing `project.yml` or adding new files:

```bash
xcodegen generate
```

Build Debug:

```bash
xcodebuild -project KeepFlow.xcodeproj -scheme KeepFlow -configuration Debug build
```

Build Release:

```bash
xcodebuild -project KeepFlow.xcodeproj -scheme KeepFlow -configuration Release build
```

If `xcode-select` points to Command Line Tools, use full Xcode explicitly:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project KeepFlow.xcodeproj \
  -scheme KeepFlow \
  -configuration Release \
  build
```

### Packaging

After a successful Release build:

```bash
productbuild \
  --component build/Build/Products/Release/KeepFlow.app \
  /Applications \
  KeepFlow-1.0.0.pkg
```

### Docs

- [PRD](/Users/zwli/myai_projects/KeepFlow/docs/prd.md)
- [Development Plan](/Users/zwli/myai_projects/KeepFlow/docs/development_plan.md)
- [Domain Model](/Users/zwli/myai_projects/KeepFlow/docs/domain_model.md)
- [Technical Design](/Users/zwli/myai_projects/KeepFlow/docs/tech_detail_design_spec.md)
