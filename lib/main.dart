import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/theme_controller.dart';

final themeController = ThemeController();

void main() {
  runApp(const AiNotesApp());
}

class AiNotesApp extends StatelessWidget {
  const AiNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'AI Notes Desktop',
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
