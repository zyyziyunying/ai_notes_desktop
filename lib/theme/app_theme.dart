import 'dart:io';

import 'package:flutter/material.dart';

/// 配色方案枚举
enum ColorPalette {
  neutral('素雅中性'),
  warm('温暖柔和'),
  tech('现代科技');

  final String label;
  const ColorPalette(this.label);
}

/// 应用主题配置
class AppTheme {
  AppTheme._();

  /// Windows 平台优化字体
  static const _windowsFontFamily = 'Microsoft YaHei UI';
  static const _defaultFontFamily = 'PingFang SC';

  /// 获取平台适配的字体
  static String get _fontFamily {
    if (Platform.isWindows) {
      return _windowsFontFamily;
    }
    return _defaultFontFamily;
  }

  /// 代码/编辑器字体
  static String get monoFontFamily {
    if (Platform.isWindows) {
      return 'Cascadia Code, Consolas';
    }
    return 'SF Mono, Menlo';
  }

  /// 获取配色方案的种子颜色
  static Color _getSeedColor(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.neutral:
        return const Color(0xFF6B7280); // 灰色调
      case ColorPalette.warm:
        return const Color(0xFF8B7355); // 暖棕色
      case ColorPalette.tech:
        return const Color(0xFF6366F1); // 靛蓝色
    }
  }

  /// 浅色主题
  static ThemeData lightTheme(ColorPalette palette) {
    final seedColor = _getSeedColor(palette);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: _customizeLightColorScheme(colorScheme, palette),
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  /// 深色主题
  static ThemeData darkTheme(ColorPalette palette) {
    final seedColor = _getSeedColor(palette);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: _customizeDarkColorScheme(colorScheme, palette),
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  /// 自定义浅色配色
  static ColorScheme _customizeLightColorScheme(
    ColorScheme base,
    ColorPalette palette,
  ) {
    switch (palette) {
      case ColorPalette.neutral:
        return base.copyWith(
          surface: const Color(0xFFFAFAFA),
          surfaceContainerHighest: const Color(0xFFF0F0F0),
        );
      case ColorPalette.warm:
        return base.copyWith(
          surface: const Color(0xFFFAF8F5),
          surfaceContainerHighest: const Color(0xFFF5F0E8),
        );
      case ColorPalette.tech:
        return base.copyWith(
          surface: const Color(0xFFFAFAFC),
          surfaceContainerHighest: const Color(0xFFEEF0FF),
        );
    }
  }

  /// 自定义深色配色
  static ColorScheme _customizeDarkColorScheme(
    ColorScheme base,
    ColorPalette palette,
  ) {
    switch (palette) {
      case ColorPalette.neutral:
        return base.copyWith(
          surface: const Color(0xFF1A1A1A),
          surfaceContainerHighest: const Color(0xFF2A2A2A),
        );
      case ColorPalette.warm:
        return base.copyWith(
          surface: const Color(0xFF1C1A18),
          surfaceContainerHighest: const Color(0xFF2C2824),
        );
      case ColorPalette.tech:
        return base.copyWith(
          surface: const Color(0xFF0F0F1A),
          surfaceContainerHighest: const Color(0xFF1A1A2E),
        );
    }
  }

  /// 构建文本主题
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor =
        brightness == Brightness.light
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFE5E5E5);

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        height: 1.3,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        height: 1.3,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.6,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.6,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: baseColor.withValues(alpha: 0.7),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        height: 1.4,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.4,
        color: baseColor.withValues(alpha: 0.7),
      ),
    );
  }

  /// 输入框装饰主题
  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  /// TabBar 主题
  static TabBarThemeData _buildTabBarTheme(ColorScheme colorScheme) {
    return TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      dividerColor: Colors.transparent,
    );
  }
}
