import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.renderedMarkdown,
    required this.onTapLink,
    required this.linksPanel,
    required this.graphPanel,
  });

  final String renderedMarkdown;
  final void Function(String text, String? href, String title) onTapLink;
  final Widget linksPanel;
  final Widget graphPanel;

  /// 获取 Markdown 样式
  MarkdownStyleSheet _buildMarkdownStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 根据平台选择等宽字体
    final monoFont = Platform.isWindows
        ? 'Cascadia Code, Consolas, monospace'
        : 'SF Mono, Menlo, monospace';

    return MarkdownStyleSheet(
      // 段落样式
      p: textTheme.bodyLarge?.copyWith(height: 1.7),

      // 标题样式
      h1: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h2: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h3: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h4: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h5: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h6: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),

      // 链接样式
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.none,
      ),

      // 代码样式
      code: TextStyle(
        fontFamily: monoFont,
        fontSize: 13,
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: colorScheme.onSurface,
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),

      // 引用样式
      blockquote: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),

      // 列表样式
      listBullet: textTheme.bodyLarge,

      // 表格样式
      tableHead: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      tableBody: textTheme.bodyMedium,
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant,
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      // 分割线
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: '预览'),
            Tab(text: '关联'),
            Tab(text: '图谱'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              Markdown(
                data: renderedMarkdown,
                onTapLink: onTapLink,
                styleSheet: _buildMarkdownStyle(context),
                padding: const EdgeInsets.all(16),
              ),
              linksPanel,
              graphPanel,
            ],
          ),
        ),
      ],
    );
  }
}
