# KeepFlow

中文 | [English](#english)

KeepFlow（心流）是一个 macOS 快速记录工具。它通过全局快捷键呼出一个类似 Raycast / Spotlight 的浮层，让你在不中断当前工作的前提下，快速捕捉任务、关注事项和灵感。

Slogan:
`Keep your flow, capture your thoughts`

## 中文

### 产品定位

KeepFlow 是一个”思维缓冲层”。

核心目标：
- 即时捕捉
- 尽量零打断
- 先记录，后整理

典型操作路径：
`Shift + Space -> 输入 -> Enter -> 关闭`

### 功能清单

| 功能 | 状态 |
| --- | --- |
| 全局快捷键唤起（Shift + Space） | ✅ |
| 菜单栏常驻，无 Dock 图标 | ✅ |
| 输入保存（Enter） | ✅ |
| 关闭面板（Esc / Shift + Enter） | ✅ |
| 任务列表展示 | ✅ |
| 方向键导航选择 | ✅ |
| Tab / Enter 完成任务 | ✅ |
| F2 编辑任务 | ✅ |
| 取消完成（Undo） | ✅ |
| 分页加载更多 | ✅ |
| SQLite 持久化 | ✅ |
| 多语言支持（8种） | ✅ |
| 设置界面 | ✅ |

### 操作说明

#### 快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Shift + Space` | 全局唤起 KeepFlow |
| `Shift + Enter` | 直接关闭面板 |
| `Enter`（输入模式） | 保存新任务 |
| `Enter`（选择模式） | 完成选中任务 |
| `Tab` | 完成选中任务 |
| `F2` | 编辑选中任务 |
| `↑` / `↓` | 导航选择任务 |
| `Esc` | 取消编辑 / 关闭面板 |
| 输入框右侧 `↩` 按钮 | 清空输入框 |

#### 交互模式

**输入模式（默认）**
- 浮层打开时，输入框自动获得焦点
- 输入内容后按 `Enter` 保存新任务并关闭
- 按 `Esc` 直接关闭面板

**选择模式**
- 按 `↓` 从输入模式切换到选择模式
- `↑` / `↓` 导航选择任务
- `Tab` 或 `Enter` 完成选中任务
- `F2` 将选中任务加载到输入框进行编辑
- 按 `Esc` 取消编辑或关闭面板
- 点击任务行直接选中

#### 编辑任务流程
1. 按 `↓` 进入选择模式
2. `↑` / `↓` 选择要编辑的任务
3. 按 `F2`，任务内容加载到输入框
4. 修改文本
5. 按 `Enter` 保存修改并关闭，或按 `Esc` 取消编辑

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

| Feature | Status |
| --- | --- |
| Global shortcut (Shift + Space) | ✅ |
| Menu bar app, no Dock icon | ✅ |
| Save input (Enter) | ✅ |
| Close panel (Esc / Shift + Enter) | ✅ |
| Task list display | ✅ |
| Arrow key navigation | ✅ |
| Tab / Enter to complete | ✅ |
| F2 to edit task | ✅ |
| Undo complete | ✅ |
| Paginated loading | ✅ |
| SQLite persistence | ✅ |
| Multi-language (8 languages) | ✅ |
| Settings interface | ✅ |

### Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Shift + Space` | Open KeepFlow globally |
| `Shift + Enter` | Close panel directly |
| `Enter` (input mode) | Save new task |
| `Enter` (selection mode) | Complete selected task |
| `Tab` | Complete selected task |
| `F2` | Edit selected task |
| `↑` / `↓` | Navigate task list |
| `Esc` | Cancel edit / Close panel |
| `↩` button in input field | Clear input |

### Interaction Modes

**Input Mode (default)**
- Input field auto-focuses when panel opens
- Type and press `Enter` to save new task and close
- Press `Esc` to close panel directly

**Selection Mode**
- Press `↓` to switch from input mode to selection mode
- `↑` / `↓` to navigate tasks
- `Tab` or `Enter` to complete selected task
- `F2` to load selected task into input field for editing
- Press `Esc` to cancel edit or close panel
- Click on a task row to select

### Edit Task Flow
1. Press `↓` to enter selection mode
2. Use `↑` / `↓` to select the task to edit
3. Press `F2`, task content loads into input field
4. Modify the text
5. Press `Enter` to save and close, or `Esc` to cancel edit

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
