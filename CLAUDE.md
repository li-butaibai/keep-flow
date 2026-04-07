# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KeepFlow (心流)** — A macOS thought capture tool that provides a "thought buffer" via `Shift + Space` to instantly capture ideas without interrupting workflow. Inspired by Raycast/macOS Spotlight.

## Tech Stack

- **UI**: SwiftUI (views) + AppKit (NSPanel for floating window)
- **Global Shortcuts**: Carbon API
- **Database**: SQLite with GRDB wrapper
- **Architecture**: MVVM with Repository pattern
- **Build**: XcodeGen + Swift Package Manager

## Build Commands

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build
xcodebuild -scheme KeepFlow -configuration Debug

# Build for release
xcodebuild -scheme KeepFlow -configuration Release

# Run tests
xcodebuild test -scheme KeepFlow
```

## Key Architecture Decisions

### Window Management
- `NSPanel` (floating, non-activating) for Spotlight-like behavior
- `LSUIElement = true` (no Dock icon)
- Window floats across all spaces: `.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`
- Panel closes on ESC, Shift+Enter, or losing focus (100ms delay)

### Data Model
```
Task: id (UUID), content (String), status (todo|done), createdAt (Timestamp), completedAt (Timestamp?), deletedAt (Timestamp?), taskType (String?)
```

### Core Modules
| Module | Responsibility |
|--------|----------------|
| `WindowManager` | Panel lifecycle, positioning, focus handling, animations |
| `ShortcutManager` | Global `Shift + Space` registration via Carbon API |
| `TaskManager` | Business logic (add, complete, delete, fetch), delegates to repository |
| `TaskRepository` | Protocol + in-memory placeholder (GRDB implementation pending Phase 2) |
| `DatabaseManager` | GRDB initialization placeholder (Phase 2) |

### Keyboard Navigation
Two interaction modes:
1. **input** (default): Focus on TextField, Enter submits new task
2. **selection**: Navigate task list with ↑/↓, Enter completes selected task

## Performance Targets

- Launch/panel appearance: < 100ms
- Input latency: < 16ms
- Operation path: ≤ 2 steps

## Project Structure

```
KeepFlow/
├── KeepFlow/
│   ├── App/
│   │   ├── main.swift           # Manual NSApplication entry point
│   │   └── AppDelegate.swift    # Lifecycle, shortcut/DB initialization
│   ├── System/
│   │   └── WindowManager.swift  # KeepFlowPanel (NSPanel subclass)
│   ├── Services/
│   │   ├── ShortcutManager.swift   # Carbon API global hotkey
│   │   └── TaskManager.swift       # Business logic
│   ├── Storage/
│   │   ├── DatabaseManager.swift   # GRDB initialization (Phase 2)
│   │   ├── TaskRepository.swift    # Repository protocol + in-memory impl
│   │   └── Models/
│   │       └── Task.swift          # Task entity
│   ├── ViewModels/
│   │   └── MainViewModel.swift    # @Published state, interaction modes
│   ├── UI/
│   │   ├── MainView.swift          # Root SwiftUI view
│   │   ├── InputView.swift         # TextField with submit
│   │   ├── TaskListView.swift      # ScrollView with task list
│   │   └── TaskRow.swift           # Individual task row
│   └── Utils/
│       └── Constants.swift          # Window dims, animations, layout
├── KeepFlow.xcodeproj/
└── project.yml                     # XcodeGen configuration
```

## Development Status

- **Phase 0**: ✅ Complete (project scaffolding)
- **Phase 1**: ✅ Complete (window management + global shortcuts)
- **Phase 2**: ✅ Complete (GRDB data persistence)
- **Phase 3**: ✅ Complete (UI + business logic)
- **Phase 4**: ✅ Complete (animations, edge cases, shortcut settings)
- **Phase 5**: ✅ Complete (packaging + verification) — **MVP Ready!**

See `docs/development_plan.md` for detailed progress tracking.
