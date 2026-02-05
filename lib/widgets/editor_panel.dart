import 'dart:io';

import 'package:flutter/material.dart';

class EditorPanel extends StatelessWidget {
  const EditorPanel({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final VoidCallback onChanged;

  /// 获取编辑器等宽字体
  String get _monoFont {
    if (Platform.isWindows) {
      return 'Cascadia Code, Consolas';
    }
    return 'SF Mono, Menlo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: '标题（Frontmatter）',
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: bodyController,
              style: TextStyle(
                fontFamily: _monoFont,
                fontSize: 14,
                height: 1.6,
                letterSpacing: 0.3,
              ),
              decoration: const InputDecoration(
                labelText: 'Markdown 内容',
                alignLabelWithHint: true,
              ),
              maxLines: null,
              expands: true,
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
