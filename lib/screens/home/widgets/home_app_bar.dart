import 'dart:io';

import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/terminal_service.dart';
import '../../../theme/app_theme.dart';
import 'app_bar_icon_button.dart';

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
    final hasVault = vaultDir != null;
    final brightness = Theme.of(context).brightness;
    final hoverColor = brightness == Brightness.light
        ? const Color(0xFFEBEBEB)
        : const Color(0xFF383838);

    return AppBar(
      title: Text(vaultDir?.path ?? '请选择笔记库'),
      actions: [
        // ── 配色方案 ──
        _HoverPopupMenuButton<ColorPalette>(
          icon: Icons.palette_outlined,
          tooltip: '配色方案',
          hoverColor: hoverColor,
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
        // ── 主题模式 ──
        AppBarIconButton(
          icon: themeController.themeModeIcon,
          tooltip: themeController.themeModeLabel,
          onPressed: themeController.toggleThemeMode,
        ),
        const SizedBox(width: 4),
        const VerticalDivider(),
        const SizedBox(width: 4),
        // ── 打开笔记库 ──
        AppBarIconButton(
          icon: Icons.folder_open,
          tooltip: '打开笔记库',
          onPressed: onSelectVault,
        ),
        // ── 关系类型 ──
        AppBarIconButton(
          icon: Icons.schema_outlined,
          tooltip: '关系类型',
          onPressed: hasVault ? onOpenTypesDialog : null,
        ),
        // ── 新建笔记 ──
        AppBarIconButton(
          icon: Icons.note_add_outlined,
          tooltip: '新建笔记',
          onPressed: hasVault ? onCreateNote : null,
        ),
        // ── 导出 AI 索引 ──
        AppBarIconButton(
          icon: Icons.auto_awesome_outlined,
          tooltip: '导出 AI 索引',
          onPressed: hasVault ? onExportAI : null,
        ),
        // ── AI 终端 ──
        _HoverPopupMenuButton<AITool>(
          icon: Icons.terminal,
          tooltip: 'AI 终端',
          enabled: hasVault,
          hoverColor: hoverColor,
          onSelected: (tool) {
            if (vaultDir != null) {
              TerminalService.launchInTerminal(tool, vaultDir!);
            }
          },
          itemBuilder: (context) => AITool.values
              .map(
                (t) => PopupMenuItem(
                  value: t,
                  child: Text(t.label),
                ),
              )
              .toList(),
        ),
        const SizedBox(width: 4),
        const VerticalDivider(),
        const SizedBox(width: 4),
        // ── 面板 toggle ──
        AppBarIconButton(
          icon: Icons.view_sidebar_outlined,
          activeIcon: Icons.view_sidebar,
          tooltip: showNotesPanel ? '隐藏笔记列表' : '显示笔记列表',
          isActive: showNotesPanel,
          onPressed: () => onToggleNotesPanel(!showNotesPanel),
        ),
        AppBarIconButton(
          icon: Icons.edit_note_outlined,
          activeIcon: Icons.edit_note,
          tooltip: showEditorPanel ? '隐藏编辑器' : '显示编辑器',
          isActive: showEditorPanel,
          onPressed: () => onToggleEditorPanel(!showEditorPanel),
        ),
        AppBarIconButton(
          icon: Icons.preview_outlined,
          activeIcon: Icons.preview,
          tooltip: showPreviewPanel ? '隐藏预览面板' : '显示预览面板',
          isActive: showPreviewPanel,
          onPressed: () => onTogglePreviewPanel(!showPreviewPanel),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// PopupMenuButton 包装，实现与 AppBarIconButton 一致的 hover 效果
class _HoverPopupMenuButton<T> extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Color hoverColor;
  final PopupMenuItemSelected<T>? onSelected;
  final PopupMenuItemBuilder<T> itemBuilder;

  const _HoverPopupMenuButton({
    required this.icon,
    required this.tooltip,
    required this.hoverColor,
    required this.onSelected,
    required this.itemBuilder,
    this.enabled = true,
  });

  @override
  State<_HoverPopupMenuButton<T>> createState() =>
      _HoverPopupMenuButtonState<T>();
}

class _HoverPopupMenuButtonState<T> extends State<_HoverPopupMenuButton<T>> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovering = false) : null,
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 500),
        child: PopupMenuButton<T>(
          enabled: widget.enabled,
          onSelected: widget.onSelected,
          itemBuilder: widget.itemBuilder,
          tooltip: '',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovering && widget.enabled
                  ? widget.hoverColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.enabled
                  ? iconColor
                  : iconColor.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
