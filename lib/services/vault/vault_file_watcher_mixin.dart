import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';

import 'vault_state.dart';

/// 文件系统监听与工具方法。
mixin VaultFileWatcherMixin on VaultState {
  StreamSubscription<WatchEvent>? _watcher;
  Timer? _watchDebounce;
  Timer? _indexDebounce;

  void watchVault(Directory dir) {
    _watcher?.cancel();
    _watcher = DirectoryWatcher(dir.path).events.listen((event) {
      if (!_isMarkdownFile(event.path)) return;
      if (_isIgnoredPath(event.path, dir.path)) return;
      _watchDebounce?.cancel();
      _watchDebounce = Timer(const Duration(milliseconds: 600), () {
        _indexDebounce?.cancel();
        _indexDebounce = Timer(const Duration(milliseconds: 300), () {
          indexAll();
        });
      });
    });
  }

  void disposeWatcher() {
    _watcher?.cancel();
    _watchDebounce?.cancel();
    _indexDebounce?.cancel();
  }

  Future<List<File>> scanMarkdownFiles(Directory root) async {
    final files = <File>[];
    final stream = root.list(recursive: true, followLinks: false);
    await for (final entity in stream) {
      if (entity is! File) continue;
      if (!_isMarkdownFile(entity.path)) continue;
      if (_isIgnoredPath(entity.path, root.path)) continue;
      files.add(entity);
    }
    return files;
  }

  String uniqueNotePath(Directory vault, String baseName) {
    final sanitized = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
    var candidate = p.join(vault.path, '$sanitized.md');
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(vault.path, '$sanitized ($counter).md');
      counter++;
    }
    return candidate;
  }

  Future<String> resolveIndexPath(Directory vault) async {
    final supportDir = await getApplicationSupportDirectory();
    final sanitized = vault.path.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final folder =
        Directory(p.join(supportDir.path, 'ai_notes_desktop', sanitized));
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return p.join(folder.path, 'index.db');
  }

  bool _isMarkdownFile(String path) {
    return path.toLowerCase().endsWith('.md');
  }

  bool _isIgnoredPath(String path, String root) {
    final relative = p.relative(path, from: root);
    final segments = p.split(relative).map((s) => s.toLowerCase()).toList();
    const ignore = <String>{
      '.git',
      '.dart_tool',
      '.ai',
      'build',
      '.idea',
      '.vscode',
      'windows',
      'linux',
      'macos',
      'android',
      'ios',
    };
    return segments.any(ignore.contains);
  }

  /// 由 VaultController 实现，触发全量索引。
  Future<void> indexAll({String? selectPath});
}
