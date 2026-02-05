import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 主题控制器，管理主题模式和配色方案
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ColorPalette _palette = ColorPalette.neutral;

  ThemeMode get themeMode => _themeMode;
  ColorPalette get palette => _palette;

  /// 获取当前浅色主题
  ThemeData get lightTheme => AppTheme.lightTheme(_palette);

  /// 获取当前深色主题
  ThemeData get darkTheme => AppTheme.darkTheme(_palette);

  /// 切换主题模式
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// 切换配色方案
  void setPalette(ColorPalette palette) {
    if (_palette != palette) {
      _palette = palette;
      notifyListeners();
    }
  }

  /// 循环切换主题模式
  void toggleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// 获取主题模式图标
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  /// 获取主题模式标签
  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }
}
