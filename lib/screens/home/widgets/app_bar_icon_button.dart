import 'package:flutter/material.dart';

/// Obsidian 风格的 AppBar 图标按钮
/// hover 时显示背景高亮 + tooltip 文字描述
class AppBarIconButton extends StatefulWidget {
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
  State<AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<AppBarIconButton> {
  bool _hovering = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hoverColor = brightness == Brightness.light
        ? const Color(0xFFEBEBEB)
        : const Color(0xFF383838);
    final iconColor = Theme.of(context).colorScheme.onSurface;

    final effectiveIcon =
        (widget.isActive && widget.activeIcon != null)
            ? widget.activeIcon!
            : widget.icon;

    return MouseRegion(
      onEnter: _enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: _enabled ? (_) => setState(() => _hovering = false) : null,
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip,
          preferBelow: true,
          waitDuration: const Duration(milliseconds: 500),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovering && _enabled ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              effectiveIcon,
              size: 20,
              color: _enabled
                  ? iconColor
                  : iconColor.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
