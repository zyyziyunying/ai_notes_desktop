import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用设置服务，用于持久化存储用户偏好
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  File? _settingsFile;
  Map<String, dynamic> _settings = {};

  static const String _lastVaultPathKey = 'lastVaultPath';

  Future<void> _ensureInitialized() async {
    if (_settingsFile != null) {
      return;
    }
    final supportDir = await getApplicationSupportDirectory();
    final folder = Directory(p.join(supportDir.path, 'ai_notes_desktop'));
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    _settingsFile = File(p.join(folder.path, 'settings.json'));
    if (_settingsFile!.existsSync()) {
      try {
        final content = _settingsFile!.readAsStringSync();
        _settings = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        _settings = {};
      }
    }
  }

  Future<void> _save() async {
    await _ensureInitialized();
    _settingsFile!.writeAsStringSync(jsonEncode(_settings));
  }

  /// 获取上次打开的笔记库路径
  Future<String?> getLastVaultPath() async {
    await _ensureInitialized();
    return _settings[_lastVaultPathKey] as String?;
  }

  /// 保存上次打开的笔记库路径
  Future<void> setLastVaultPath(String path) async {
    await _ensureInitialized();
    _settings[_lastVaultPathKey] = path;
    await _save();
  }
}
