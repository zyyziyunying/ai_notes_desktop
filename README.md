---
id: 9b8d4f26-8a68-4574-9056-a938202519b3
title: AI Notes Desktop
---
# AI Notes Desktop

AI Notes Desktop 是一个面向桌面端的本地优先 Markdown 笔记应用。它以“文件夹即笔记库（vault）”为核心思路，在保持纯文本可迁移性的同时，提供结构化前言（YAML frontmatter）、显式关系与知识图谱、全文检索，以及面向 AI 的索引导出能力。

## 项目背景

- 传统笔记往往在“自由书写”和“结构化管理”之间难以兼顾；Markdown 便于书写但关系不够显式。
- 知识管理逐渐从“线性文档”转向“网络化节点”，需要更直观的关联与可视化。
- AI 能力兴起后，笔记内容如何“可被机器理解”成为新的诉求，需要稳定、可复用的索引与关系数据。

## 项目意义

- **本地优先与可迁移性**：所有笔记以 Markdown 存储在本地文件夹，避免数据锁定。
- **显式关系与块级关联**：支持在正文中显式标注关系，并可指向具体块（段落级关联）。
- **可搜索、可视化、可集成**：内置全文检索与关系图谱，并导出 AI 索引文件，方便后续检索增强或数据处理。
- **跨平台一致体验**：基于 Flutter 桌面端能力，为多系统提供一致的使用体验。

## 设计概览

### 1 信息模型

- **NoteMeta**：id、title、path、tags、updatedAt 等基础元信息。
- **NoteDocument**：完整笔记对象（frontmatter + body）。
- **NoteLink**：统一描述“从-到”关系，包含 fromId/toId/type/source/rawTarget，支持可选的 fromBlock/toBlock（块级关联）。
- **FrontmatterLink**：可配置关系类型与备注，支持可选的 fromBlock/toBlock（块级关联）。

### 2 数据格式与约定

- **YAML Frontmatter**（写入/补全机制）  
  如果笔记缺少 id 或 title，解析时会自动补齐并回写到文件。

  示例：

  ```yaml
  ---
  id: 4f5d-xxxx
  title: 知识节点示例
  tags: [AI, Notes]
  links:
    - to: 目标笔记
      type: relates_to
      note: 关联原因
      from: a1
      to_block: b2
  ---
  ```

- **显式关系块（推荐）**  
  在正文中用 `links` / `relations` 块显式写关系，解析后会同步回 frontmatter 的 `links`：

  代码块形式：

  ````markdown
  ```links
  - from: a1
    to: Beta#b1
    type: depends_on
    note: Beta 的方法支撑这一段
  - from: a1
    to: Gamma
    to_block: g2
    type: relates_to
  ```
  ````

  隐藏注释形式（更隐蔽）：

  ````markdown
  <!-- links
  - from: a1
    to: Beta#b1
    type: depends_on
  -->
  ````

- **块级锚点（可选）**  
  可用 HTML 注释标记段落位置，例如：

  ```markdown
  这是一段需要被引用的文字。 <!-- block:a1 -->
  ```

  在关系中可用 `from: a1`、`to: Note#b1` 或 `to_block: b1` 指向该块。系统会将块 ID 统一规范为 `^a1` 形式，但你在写时可省略 `^`。

- **Wiki Link（兼容）**  
  正文中支持 `[[目标]]` 或 `[[目标|显示文本]]`，也支持 `[[id:xxxx]]` 直接指向特定 id。可选带锚点 `[[目标#b1]]`。显式关系块是推荐方案。

### 3 索引与搜索

- 使用 SQLite FTS5 构建全文检索索引。
- 索引数据库存放在应用支持目录（App Support）中，避免污染笔记库目录。
- 监听笔记库中的 .md 文件变化，自动重建索引并同步关系图。

### 4 关系与图谱

- 双向关系：同时展示出链与入链。
- 关系面板会展示块级信息（from/to block），便于理解“哪一段关联哪一段”。
- 图谱可视化：使用力导向布局呈现关系网络，为性能限制默认最多展示 200 个节点。
- 关系类型可配置，保存在 `.ai/relations.json` 中。

### 5 AI 索引导出

在笔记库的 `.ai/` 目录中导出以下文件：

- `vault_index.json`：笔记元数据索引（标题、路径、标签、更新时间等）。
- `link_graph.json`：节点与边的关系图，支持 `from_block` / `to_block` 字段，便于块级关联处理。
- `note_manifest.jsonl`：每行一条笔记基础信息，适合批处理与流式消费。

### 6 界面与交互

- **左侧**：笔记列表 + 搜索栏。
- **中间**：编辑区（标题与正文 Markdown）。
- **右侧**：预览 / 关联 / 图谱 三个 Tab。
- 支持新建笔记、编辑 frontmatter 关系、导出 AI 索引。

## 示例与 Demo

- `demo_vault/`：传统 Wiki Link + frontmatter 示例。
- `demo_vault_explicit/`：显式 links 代码块示例。
- `demo_vault_hidden/`：隐藏注释 `<!-- links -->` + 块锚点示例。

## 目录结构

- `lib/screens/`：主界面与页面组织。
- `lib/widgets/`：编辑器、预览、图谱、列表等 UI 组件。
- `lib/services/`：解析、索引、导出、关系类型管理等业务逻辑。
- `lib/models/`：数据模型定义。
- `lib/dialogs/`：关系编辑与类型管理弹窗。
- `lib/utils/`：YAML 编码等工具函数。
- `lib/theme/`：主题配置与控制器。

## 主题系统

应用内置完整的主题系统，支持深浅主题切换和多种配色方案。

### 主题模式

- **跟随系统**：自动适配系统的深浅色设置
- **浅色模式**：明亮清爽，适合白天使用
- **深色模式**：护眼，适合长时间编辑

### 配色方案

| 方案 | 说明 |
|------|------|
| 素雅中性 | 灰色调为主，低饱和度，专注内容 |
| 温暖柔和 | 米色/暖灰调，类似纸张质感 |
| 现代科技 | 蓝紫色调，有科技感 |

### 字体优化

针对不同平台优化了字体显示：

| 平台 | UI 字体 | 代码字体 |
|------|---------|----------|
| Windows | Microsoft YaHei UI | Cascadia Code, Consolas |
| macOS | PingFang SC | SF Mono, Menlo |

### 使用方式

在应用顶部工具栏：
- 点击 **调色板图标** 选择配色方案
- 点击 **亮度图标** 循环切换主题模式

## 状态管理

应用使用 [signals](https://pub.dev/packages/signals) 进行响应式状态管理：

- **VaultController**：管理笔记库核心状态（当前笔记、笔记列表、链接关系等），所有状态均为 Signal
- **HomeScreenStateManager**：管理 UI 状态（面板可见性、面板宽度等）
- **ThemeController**：管理主题状态（主题模式、配色方案）

这种架构确保了：
- 细粒度的 UI 更新，只有依赖的状态变化时才重建
- 状态变化自动触发 UI 更新，无需手动调用 setState
- 清晰的状态分离，业务逻辑与 UI 状态解耦
