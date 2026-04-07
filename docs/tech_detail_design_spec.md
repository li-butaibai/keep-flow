下面是一份**面向开发落地的技术方案详细设计说明书（TDD）**，基于 **SwiftUI + AppKit** 的混合架构，专门为 **KeepFlow（心流）** 这种“系统级、低打断、极快唤起”的工具设计。



---



&nbsp;

# **📄 KeepFlow 技术方案详细设计说明书（TDD）**



&nbsp;

---



&nbsp;

## **一、总体设计目标**



&nbsp;

&nbsp;

### **1.1 核心技术目标**




| **目标** | **指标**       |
| ------ | ------------ |
| 唤起速度   | &lt; 100ms   |
| 输入延迟   | 无感（&lt;16ms） |
| 操作路径   | ≤ 2步         |
| 稳定性    | 崩溃不丢数据       |




---



&nbsp;

### **1.2 技术设计原则**



&nbsp;

- **原生优先**：最大化 macOS 体验
- **低侵入**：不打断用户当前应用
- **轻量架构**：避免过度设计
- **可演进**：为 AI / 多端预留接口



&nbsp;

---



&nbsp;

## **二、总体架构设计**



&nbsp;

&nbsp;

### **2.1 架构分层**



```
KeepFlow
├── Presentation Layer（UI层）
│   ├── SwiftUI Views
│   └── ViewModels
│
├── Application Layer（应用层）
│   ├── TaskManager
│   ├── ShortcutManager
│   └── WindowManager
│
├── Infrastructure Layer（基础设施层）
│   ├── Storage（SQLite）
│   ├── EventBus（可选）
│   └── Logger
│
└── System Layer（系统层）
    ├── AppKit（NSPanel / Window）
    └── Carbon（快捷键）
```



---



&nbsp;

### **2.2 核心模块职责**




| **模块**          | **职责**    |
| --------------- | --------- |
| UI层             | 输入 + 列表展示 |
| WindowManager   | 控制窗口生命周期  |
| ShortcutManager | 注册全局快捷键   |
| TaskManager     | 任务管理逻辑    |
| Storage         | 数据持久化     |




---



&nbsp;

## **三、核心模块详细设计**



&nbsp;

---



&nbsp;

## **3.1 WindowManager（窗口管理）**



&nbsp;

&nbsp;

### **技术选型**



&nbsp;

- AppKit：**NSPanel（关键）**



&nbsp;

---



&nbsp;

### **设计目标**



&nbsp;

- 类似 Spotlight / Raycast
- 不进入 Dock
- 不影响当前应用焦点流



&nbsp;

---



&nbsp;

### **核心实现**



&nbsp;

&nbsp;

**Window 类型**



```
class KeepFlowPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
```



---



&nbsp;

**初始化配置**



```
panel = KeepFlowPanel(
    contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
    styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
    backing: .buffered,
    defer: false
)

panel.isFloatingPanel = true
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.isMovableByWindowBackground = false
panel.hidesOnDeactivate = false
panel.backgroundColor = .clear
panel.isOpaque = false
panel.hasShadow = true

// 内容视图使用 NSVisualEffectView 实现毛玻璃背景
let visualEffect = NSVisualEffectView(frame: panel.contentView!.bounds)
visualEffect.material = .hudWindow
visualEffect.state = .active
visualEffect.blendingMode = .behindWindow
visualEffect.wantsLayer = true
visualEffect.layer?.cornerRadius = 14
visualEffect.layer?.masksToBounds = true
panel.contentView = visualEffect
```



---



&nbsp;

**关键行为**




| **行为** | **实现**                 |
| ------ | ---------------------- |
| 居中显示   | setFrameOrigin(center) |
| 自动聚焦   | makeKeyAndOrderFront   |
| 失焦关闭   | windowDidResignKeyNotification → 延迟 100ms 关闭 |
| ESC关闭  | 监听 keyDown → 立即关闭  |
| Shift+Enter 关闭 | 监听 keyDown → 立即关闭  |




---

---



&nbsp;

## **3.2 ShortcutManager（快捷键管理）**



&nbsp;

---



&nbsp;

### **技术选型**



&nbsp;

- Carbon API（底层）
- 或 HotKey（封装）



&nbsp;

---



&nbsp;

### **功能**



&nbsp;

- 注册全局快捷键：Shift + Space → 唤起/关闭窗口
- ESC → 关闭窗口（输入完成后退出）
- Shift + Enter → 关闭窗口（输入内容后关闭，不与 Enter 提交冲突）
- 快捷键在 NSPanel 内通过 `keyDown` 事件监听，无需系统级注册（Panel 激活时才有焦点）



&nbsp;

---



&nbsp;

### **示例**



```
hotKey = HotKey(key: .space, modifiers: [.shift])

hotKey.keyDownHandler = {
    WindowManager.shared.toggle()
}
```



---

---



&nbsp;

## **3.3 UI层（SwiftUI）**



&nbsp;

---



&nbsp;

### **交互模式**



| **模式** | **触发条件** | **Enter 行为** | **↓ 键行为** |
| ------ | ---------- | ------------ | ----------- |
| inputMode（默认） | 窗口打开 / 输入框聚焦 | 提交任务 + 关闭窗口 | 切换到 selectionMode |
| selectionMode | 按 ↓ 选中列表项 | 标记选中任务完成 + 关闭窗口 | 选中下一项 |
| Shift+Enter / ESC | 任意模式 | 关闭窗口（不保存） | — |

**说明**：
- inputMode 下 Enter = 提交新任务并关闭
- selectionMode 下 Enter = 标记选中任务完成并关闭
- Shift+Enter 和 ESC 在任何模式下都只是关闭窗口，不保存
- 输入框始终在顶部，焦点默认在输入框（inputMode）



### **结构设计**



```
MainView
├── InputView（输入框）
└── TaskListView（任务列表）
```



---



&nbsp;

### **核心组件**



&nbsp;

&nbsp;

**输入框**



```
TextField("输入你的想法...", text: $viewModel.inputText)
    .onSubmit {
        viewModel.submit()
    }
```



---



&nbsp;

**列表**



```
List(viewModel.tasks) { task in
    TaskRow(task: task)
}
```



---

---



&nbsp;

## **3.4 TaskManager（核心业务）**



&nbsp;

---



&nbsp;

### **职责**



&nbsp;

- 新增任务
- 标记完成
- 删除任务
- 查询任务



&nbsp;

---



&nbsp;

### **接口设计**



```
protocol TaskService {
    func addTask(content: String) -> Result<Task, TaskCreationError>
    func completeTask(id: UUID) throws
    func undoComplete(id: UUID) throws  // 撤销完成，done → todo
    func deleteTask(id: UUID) throws   // 软删除（deletedAt）
    func fetchTasks(limit: Int) -> [Task]  // 仅返回未删除的 todo 任务
}
```

**TaskService 实现依赖 TaskRepository**，业务层不直接操作数据库。



---

---



&nbsp;

## **3.5 数据存储（Storage）**



&nbsp;

---



&nbsp;

### **技术选型**



&nbsp;

- SQLite（推荐）
- 封装层：GRDB（建议）
- 数据库路径：`~/Library/Application Support/KeepFlow/keepflow.sqlite`
- 使用 Swift Package Manager 管理 GRDB（不要用 CocoaPods）
- GRDB MigrationStrategy 自动创建表（无需手动执行 SQL）



&nbsp;

---



&nbsp;

### **表结构**



```
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    status TEXT NOT NULL,
    createdAt DATETIME NOT NULL,
    completedAt DATETIME,          -- 显式存储完成时间
    deletedAt DATETIME,             -- 软删除标记，非 nil 即已删除
    taskType TEXT                   -- 预留扩展（Task/Follow-up/Idea）
);
```

**查询约定**：所有列表查询必须 `WHERE deletedAt IS NULL`，已删除记录物理保留但逻辑过滤。



---



&nbsp;

### **数据访问层**



```
protocol TaskRepository {
    func save(_ task: Task) throws
    func findById(_ id: UUID) throws -> Task?
    func findAll(limit: Int) throws -> [Task]  // 未删除，按创建时间倒序
    func findTodoTasks(limit: Int) throws -> [Task]
    func delete(_ id: UUID) throws              // 硬删除
    func softDelete(_ id: UUID) throws          // 软删除
    func countByStatus(_ status: TaskStatus) throws -> Int
}

final class TaskRepositoryImpl: TaskRepository {
    private let dbQueue: DatabaseQueue
    // GRDB MigrationStrategy 自动建表
}
```



---

---



&nbsp;

## **四、关键流程设计**



&nbsp;

---



&nbsp;

### **4.1 快捷捕捉流程（核心）**



```
用户按 Shift + Space
        ↓
ShortcutManager 捕获
        ↓
WindowManager 显示窗口（懒加载 NSPanel）
        ↓
自动聚焦输入框（inputMode）
        ↓
用户输入
        ↓
Enter → TaskManager.addTask() → Storage.persist() → 窗口关闭
   或
Shift+Enter → 窗口关闭（不保存，仅关闭）
   或
ESC → 窗口关闭（不保存，仅关闭）
   或
失焦 → 延迟 100ms 关闭
```



---

---



&nbsp;

### **4.2 任务展示流程**



```
窗口打开
    ↓
TaskManager.fetchTasks()
    ↓
ViewModel 更新
    ↓
SwiftUI 渲染
```



---

---



&nbsp;

## **五、状态管理设计**



&nbsp;

---



&nbsp;

### **ViewModel**



```
class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var tasks: [Task] = []

    func submit() {
        TaskManager.shared.addTask(content: inputText)
        inputText = ""
        WindowManager.shared.close()
    }
}
```



---

---



&nbsp;

## **六、性能优化设计**



&nbsp;

---



&nbsp;

### **6.1 启动优化**



&nbsp;

- App 启动即后台运行
- 不创建窗口（懒加载）



&nbsp;

---



&nbsp;

### **6.2 渲染优化**



&nbsp;

- 限制列表数量（默认5条）
- 避免复杂动画



### **6.3 动画规范**


&nbsp;

| **动画类型** | **时长** | **缓动曲线** | **触发时机** |
| ------ | ------ | --------- | ---------- |
| 窗口淡入   | 150ms  | easeOut   | Shift+Space 唤起 |
| 窗口淡出   | 100ms  | easeIn    | ESC / Shift+Enter / 失焦 / 提交后 |
| 列表项展开  | 100ms  | easeInOut | 窗口打开时列表渲染 |



&nbsp;

---



&nbsp;

### **6.4 IO优化**



&nbsp;

- 批量写入（可选）
- 异步存储



&nbsp;

---

---



&nbsp;

## **七、系统行为设计**



&nbsp;

---



&nbsp;

### **7.1 App运行模式**



&nbsp;

- 无 Dock 图标（LSUIElement = true）
- Menu Bar（可选）



### **App 生命周期与初始化路径**



```
App 启动（main.swift / @main）
    ↓
AppDelegate.applicationDidFinishLaunching
    ↓
ShortcutManager.register()  // 注册 Shift+Space 全局快捷键
    ↓
WindowManager.shared.panel  // 懒加载：首次访问才创建 NSPanel
    ↓
DatabaseManager.initialize()  // 初始化 GRDB + SQLite
    ↓
进入后台等待
    ↓
用户按 Shift+Space
    ↓
WindowManager.show()  // 懒加载 panel → 显示 → 自动聚焦输入框
```

**懒加载策略**：
- NSPanel 在首次 `Shift+Space` 时才创建（`WindowManager.shared.panel` 懒加载）
- GRDB 在 App 启动时初始化，数据库路径：`~/Library/Application Support/KeepFlow/keepflow.sqlite`
- 如果目录不存在，启动时自动创建



&nbsp;

---



&nbsp;

### **7.2 多桌面支持**



```
panel.collectionBehavior = [.canJoinAllSpaces]
```



---

---



&nbsp;

## **八、异常与边界处理**



---




| **场景** | **处理**      |
| ------ | ----------- |
| 输入为空   | 忽略          |
| 重复输入   | 允许          |
| 数据库失败  | 任务写入内存队列，下次 App 启动时重试写入；用户无感知 |
| 快捷键冲突  | 提供设置（后续）    |




---

---



## **九、扩展设计（为未来预留）**



---



### **9.1 AI扩展接口**



```
protocol TaskProcessor {
    func classify(task: Task)
    func split(task: Task)
}
```



### **9.2 同步接口**



```
protocol SyncService {
    func push()
    func pull()
}
```

### **9.3 插件系统（未来）**

- Command扩展
- AI扩展

## **十、项目结构建议**



```
KeepFlow/
├── App/
├── UI/
├── ViewModels/
├── Services/
├── Storage/
├── System/
└── Utils/
```

# **🔚 总结**



---

## **技术核心一句话**



> **用 SwiftUI 做界面，用 AppKit 控制“出现与消失”**
>
>

---



## **成败关键（技术角度）**

不是数据库，不是AI，而是：

> **窗口是否“像不存在一样存在”**

---



&nbsp;