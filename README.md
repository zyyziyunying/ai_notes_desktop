---
id: 9b8d4f26-8a68-4574-9056-a938202519b3
title: AI Notes Desktop
---

# AI Notes Desktop

AI Notes Desktop 是一个面向桌面端的本地优先 Markdown 笔记应用。它以"文件夹即笔记库（vault）"为核心思路，在保持纯文本可迁移性的同时，提供结构化前言（YAML frontmatter）、显式关系与知识图谱、全文检索、AI 终端集成，以及面向 AI 的索引导出能力。

## 功能特性

- **本地优先**：所有笔记以 Markdown 存储在本地文件夹，避免数据锁定，随时可迁移
- **显式关系与块级关联**：支持箭头语法在正文中标注关系，可指向具体段落（块级锚点）
- **知识图谱**：自研力导向布局算法（Fruchterman-Reingold），可视化呈现笔记关系网络
- **全文检索**：基于 SQLite FTS5，索引存放在应用目录中，不污染笔记库
- **AI 终端集成**：一键在笔记库目录启动 Claude Code 或 Codex
- **AI 索引导出**：导出机器可读的索引文件（`.ai/` 目录），方便 AI 消费与检索增强
- **跨平台**：基于 Flutter，支持 Windows / macOS / Linux

## 界面与交互

- **左侧**：笔记列表 + 搜索栏，支持右键菜单（重命名、删除）
- **中间**：编辑区（标题与正文 Markdown），600ms 防抖自动保存
- **右侧**：预览 / 关联 / 图谱 三个 Tab
- **面板管理**：各面板可独立显示/隐藏、拖拽调整宽度，隐藏面板后其余面板自动填充
- **状态栏**：底部显示索引状态等实时信息
- **记忆上次笔记库**：启动时自动打开上次使用的笔记库

## 设计概览

### 1 信息模型

- **NoteMeta**：id、title、path、tags、updatedAt 等基础元信息
- **NoteDocument**：完整笔记对象（frontmatter + body + embedded links）
- **NoteLink**：统一描述"从-到"关系，包含 fromId/toId/type/source/rawTarget，支持可选的 fromBlock/toBlock（块级关联）
- **EmbeddedLink**：嵌入在正文中的箭头语法链接，包含 anchor、summary 等字段

### 2 数据格式与约定

- **YAML Frontmatter**（写入/补全机制）
  如果笔记缺少 id 或 title，解析时会自动补齐并回写到文件。

  示例：

  ```yaml
  ---
  id: 4f5d-xxxx
  title: 知识节点示例
  tags: [AI, Notes]
  ---
  ```

- **箭头语法关系块（推荐）**
  在正文中用隐藏注释块书写关系，使用箭头语法：

  ```markdown
  <!-- links
  §a1 -> Target §b1 : relates_to
  | 可选的摘要说明文字
  §a2 -> AnotherNote : references
  -->
  ```

  预览面板会自动隐藏 links 注释块，不影响阅读。

- **块级锚点（可选）**
  可用 HTML 注释标记段落位置，例如：

  ```markdown
  这是一段需要被引用的文字。 <!-- §a1 -->
  ```

  预览面板会将锚点渲染为带颜色的 `§a1` 徽章，方便识别。在关系中可用箭头语法指向该块。

- **Wiki Link（兼容）**
  正文中支持 `[[目标]]` 或 `[[目标|显示文本]]`，也支持 `[[id:xxxx]]` 直接指向特定 id。可选带锚点 `[[目标#b1]]`。

### 3 索引与搜索

- 使用 SQLite FTS5 构建全文检索索引
- 索引数据库存放在应用支持目录（App Support）中，避免污染笔记库目录
- 监听笔记库中的 .md 文件变化，自动重建索引并同步关系图

### 4 关系与图谱

- 双向关系：同时展示出链与入链
- 关系面板会展示块级信息（from/to block），便于理解"哪一段关联哪一段"
- 图谱可视化：自研 Fruchterman-Reingold 力导向布局，默认最多展示 200 个节点
- 关系类型可配置，保存在 `.ai/relations.json` 中

### 5 AI 终端集成

在应用顶部工具栏点击 AI 终端按钮，可选择启动：

- **Claude Code**：在笔记库目录打开系统终端并运行 Claude
- **Codex**：在笔记库目录打开系统终端并运行 Codex

支持 Windows（cmd.exe）、macOS（Terminal.app）、Linux（gnome-terminal / xterm）。

### 6 AI 索引导出

> 说明：以下 `.ai/` 索引文件为程序自动生成（machine-generated），用于检索 / 图谱 / AI 消费。请勿手动编辑；可删除后重新导出。

机器可读标记（供 AI 快速识别）：

```json
{
  "ai_export": {
    "directory": ".ai/",
    "files": [
      "ai_export_manifest.json",
      "vault_index.json",
      "link_graph.json",
      "note_manifest.jsonl"
    ],
    "machine_generated": true,
    "editable": false,
    "regenerable": true
  }
}
```

在笔记库的 `.ai/` 目录中导出以下文件：

- `ai_export_manifest.json`：导出清单与版本信息（声明为 machine-generated，便于 AI 快速识别）
- `vault_index.json`：笔记元数据索引（标题、路径、标签、更新时间等），带 `meta` 说明
- `link_graph.json`：节点与边的关系图，支持 `from_block` / `to_block` 字段，带 `meta` 说明
- `note_manifest.jsonl`：每行一条笔记基础信息，适合批处理与流式消费

## 示例与 Demo

- `demo_vault/`：传统 Wiki Link + frontmatter 示例
- `demo_vault_explicit/`：显式 links 代码块示例
- `demo_vault_hidden/`：隐藏注释 `<!-- links -->` + 块锚点 + 箭头语法示例

## 目录结构

```
lib/
├── main.dart                        # 应用入口
├── models/                          # 数据模型（NoteMeta, NoteDocument, NoteLink, EmbeddedLink）
├── screens/home/                    # 主界面
│   ├── home_screen.dart             # 主屏幕
│   ├── home_screen_state.dart       # UI 状态管理（Signals）
│   ├── home_screen_logic.dart       # 业务逻辑 mixin
│   ├── home_screen_dialogs.dart     # 弹窗处理 mixin
│   └── widgets/                     # AppBar、面板布局、状态栏等
├── widgets/                         # UI 组件
│   ├── editor_panel.dart            # Markdown 编辑器
│   ├── notes_panel.dart             # 笔记列表（搜索 + 右键菜单）
│   ├── preview_panel.dart           # Markdown 预览（含锚点徽章渲染）
│   ├── links_panel.dart             # 关系面板（出链 / 入链）
│   └── graph_panel/                 # 力导向图谱（自研布局算法）
├── services/
│   ├── vault/                       # Vault 控制器（mixin 架构）
│   │   ├── vault_controller.dart    # 主协调器
│   │   ├── vault_state.dart         # 共享状态基类（Signals）
│   │   ├── vault_file_watcher_mixin.dart
│   │   ├── vault_search_mixin.dart
│   │   ├── vault_link_mixin.dart
│   │   ├── vault_note_crud_mixin.dart
│   │   └── link_graph_builder.dart
│   ├── note_parser.dart             # Markdown 解析（frontmatter + body + links）
│   ├── index_service.dart           # SQLite FTS5 索引
│   ├── ai_export_service.dart       # AI 索引导出
│   ├── relation_type_service.dart   # 关系类型管理
│   ├── link_resolver.dart           # Wiki Link 解析
│   ├── terminal_service.dart        # AI 终端启动
│   └── app_settings.dart            # 应用设置（记忆上次笔记库等）
├── dialogs/                         # 关系编辑与类型管理弹窗
├── theme/                           # 主题配置与控制器
└── utils/                           # YAML 编码等工具函数
```

## 主题系统

应用内置完整的主题系统，支持深浅主题切换和多种配色方案。UI 风格参考 Obsidian，采用纯图标按钮设计。

### 主题模式

- **跟随系统**：自动适配系统的深浅色设置
- **浅色模式**：明亮清爽，适合白天使用
- **深色模式**：护眼，适合长时间编辑

### 配色方案

| 方案     | 说明                           |
| -------- | ------------------------------ |
| 素雅中性 | 灰色调为主，低饱和度，专注内容 |
| 温暖柔和 | 米色/暖灰调，类似纸张质感      |
| 现代科技 | 蓝紫色调，有科技感             |

### 字体优化

| 平台    | UI 字体            | 代码字体                |
| ------- | ------------------ | ----------------------- |
| Windows | Microsoft YaHei UI | Cascadia Code, Consolas |
| macOS   | PingFang SC        | SF Mono, Menlo          |

## 状态管理

应用使用 [signals](https://pub.dev/packages/signals) 进行响应式状态管理，VaultController 采用 mixin 架构拆分职责：

- **VaultState**：共享状态基类，所有状态均为 Signal
- **VaultFileWatcherMixin**：文件系统监听与防抖重建索引
- **VaultSearchMixin**：全文检索
- **VaultLinkMixin**：链接关系管理
- **VaultNoteCrudMixin**：笔记增删改查
- **HomeScreenStateManager**：UI 状态（面板可见性、面板宽度等）
- **ThemeController**：主题状态（主题模式、配色方案）

## 技术栈

| 类别     | 技术                                 |
| -------- | ------------------------------------ |
| 框架     | Flutter (Desktop)                    |
| 状态管理 | signals ^6.3.0                       |
| 全文检索 | sqlite3 + FTS5                       |
| Markdown | flutter_markdown + markdown          |
| 文件监听 | watcher                              |
| 图谱布局 | 自研 Fruchterman-Reingold 力导向算法 |
