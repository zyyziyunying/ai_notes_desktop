import 'dart:io';

import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../theme/app_theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Directory? vaultDir;
  final VoidCallback onSelectVault;
  final VoidCallback onOpenTypesDialog;
  final VoidCallback onCreateNote;
  final VoidCallback onExportAI;
  final bool showNotesPanel;
  final bool showEditorPanel;
  final bool showPreviewPanel;
  final ValueChanged<bool> onToggleNotesPanel;
  final ValueChanged<bool> onToggleEditorPanel;
  final ValueChanged<bool> onTogglePreviewPanel;

  const HomeAppBar({
    super.key,
    required this.vaultDir,
    required this.onSelectVault,
    required this.onOpenTypesDialog,
    required this.onCreateNote,
    required this.onExportAI,
    required this.showNotesPanel,
    required this.showEditorPanel,
    required this.showPreviewPanel,
    required this.onToggleNotesPanel,
    required this.onToggleEditorPanel,
    required this.onTogglePreviewPanel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(vaultDir?.path ?? '请选择笔记库'),
      actions: [
        // 主题切换按钮
        PopupMenuButton<ColorPalette>(
          icon: const Icon(Icons.palette_outlined),
          tooltip: '配色方案',
          onSelected: themeController.setPalette,
          itemBuilder: (context) => ColorPalette.values
              .map(
                (p) => PopupMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      if (themeController.palette == p)
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(p.label),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        IconButton(
          icon: Icon(themeController.themeModeIcon),
          tooltip: themeController.themeModeLabel,
          onPressed: themeController.toggleThemeMode,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onSelectVault,
          icon: const Icon(Icons.folder_open),
          label: const Text('打开'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: vaultDir == null ? null : onOpenTypesDialog,
          icon: const Icon(Icons.schema_outlined),
          label: const Text('关系类型'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: vaultDir == null ? null : onCreateNote,
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('新建'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: vaultDir == null ? null : onExportAI,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('导出 AI 索引'),
        ),
        const SizedBox(width: 16),
        // Panel toggle buttons
        const VerticalDivider(),
        IconButton(
          icon: Icon(showNotesPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined),
          tooltip: showNotesPanel ? '隐藏笔记列表' : '显示笔记列表',
          onPressed: () => onToggleNotesPanel(!showNotesPanel),
        ),
        IconButton(
          icon: Icon(showEditorPanel ? Icons.edit_note : Icons.edit_note_outlined),
          tooltip: showEditorPanel ? '隐藏编辑器' : '显示编辑器',
          onPressed: () => onToggleEditorPanel(!showEditorPanel),
        ),
        IconButton(
          icon: Icon(showPreviewPanel ? Icons.preview : Icons.preview_outlined),
          tooltip: showPreviewPanel ? '隐藏预览面板' : '显示预览面板',
          onPressed: () => onTogglePreviewPanel(!showPreviewPanel),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
