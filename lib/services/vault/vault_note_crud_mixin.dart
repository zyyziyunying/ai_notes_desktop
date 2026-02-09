import 'dart:io';

import 'package:uuid/uuid.dart';

import 'vault_state.dart';

/// 笔记 CRUD 操作。
mixin VaultNoteCrudMixin on VaultState {
  final Uuid _uuid = const Uuid();

  Future<void> createNote() async {
    final vault = vaultDirS.value;
    if (vault == null) return;
    final baseName = _suggestNewTitle();
    final filePath = uniqueNotePath(vault, baseName);
    final frontmatter = {
      'id': _uuid.v4(),
      'title': baseName,
      'tags': <String>[],
    };
    final content = parser.buildNoteContent(frontmatter, '');
    File(filePath).writeAsStringSync(content);
    await indexAll(selectPath: filePath);
  }

  Future<void> saveCurrent({
    required String body,
    required String title,
  }) async {
    final current = currentS.value;
    if (current == null) return;
    final frontmatter = Map<String, dynamic>.from(current.frontmatter);
    frontmatter['title'] = title.trim().isEmpty ? current.meta.title : title;
    final content = parser.buildNoteContent(frontmatter, body);
    File(current.meta.path).writeAsStringSync(content);
    await indexAll(selectPath: current.meta.path);
  }

  Future<void> deleteNote(String id) async {
    final vault = vaultDirS.value;
    if (vault == null) return;
    final doc = documentsS.value.firstWhere(
      (d) => d.meta.id == id,
      orElse: () => documentsS.value.first,
    );
    if (doc.meta.id != id) return;
    final file = File(doc.meta.path);
    if (file.existsSync()) file.deleteSync();
    await indexAll();
  }

  Future<void> renameNote(String id, String newTitle) async {
    final vault = vaultDirS.value;
    if (vault == null || newTitle.trim().isEmpty) return;
    final doc = documentsS.value.firstWhere(
      (d) => d.meta.id == id,
      orElse: () => documentsS.value.first,
    );
    if (doc.meta.id != id) return;
    final frontmatter = Map<String, dynamic>.from(doc.frontmatter);
    frontmatter['title'] = newTitle.trim();
    final content = parser.buildNoteContent(frontmatter, doc.body);
    final oldFile = File(doc.meta.path);
    final newPath = uniqueNotePath(vault, newTitle.trim());
    oldFile.writeAsStringSync(content);
    if (newPath != doc.meta.path) {
      File(newPath).writeAsStringSync(content);
      oldFile.deleteSync();
    }
    await indexAll(
      selectPath: newPath != doc.meta.path ? newPath : doc.meta.path,
    );
  }

  /// 由 VaultController 实现，触发全量索引。
  Future<void> indexAll({String? selectPath});

  /// 生成不重复的文件路径，由 VaultFileWatcherMixin 提供。
  String uniqueNotePath(Directory vault, String baseName);

  String _suggestNewTitle() {
    const base = 'New Note';
    if (notesS.value.every((note) => note.title != base)) return base;
    var counter = 2;
    while (notesS.value.any((note) => note.title == '$base $counter')) {
      counter++;
    }
    return '$base $counter';
  }
}
