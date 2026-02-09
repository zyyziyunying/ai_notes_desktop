import 'package:flutter/material.dart';

/// Obsidian 风格的 AppBar 图标按钮
/// hover 时显示背景高亮 + tooltip 文字描述
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.activeIcon,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hoverColor = brightness == Brightness.light
        ? const Color(0xFFEBEBEB)
        : const Color(0xFF383838);
    final iconColor = Theme.of(context).colorScheme.onSurface;

    final effectiveIcon = (isActive && activeIcon != null) ? activeIcon! : icon;

    return Tooltip(
      message: tooltip,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 500),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(effectiveIcon),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          hoverColor: hoverColor,
          highlightColor: hoverColor,
          foregroundColor: iconColor,
          disabledForegroundColor: iconColor.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
