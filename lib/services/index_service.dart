import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../models/note_models.dart';

class IndexService {
  Database? _db;

  bool get isOpen => _db != null;

  void open(String dbPath) {
    _db = sqlite3.open(dbPath);
    _initSchema();
  }

  void dispose() {
    _db?.close();
    _db = null;
  }

  void replaceNotes(List<NoteDocument> docs) {
    final db = _db;
    if (db == null) {
      return;
    }
    db.execute('DELETE FROM notes');
    db.execute('DELETE FROM fts_notes');

    final insertNote = db.prepare(
      'INSERT INTO notes (id, title, path, updated_at, tags) VALUES (?, ?, ?, ?, ?)',
    );
    final insertFts = db.prepare(
      'INSERT INTO fts_notes (id, title, body) VALUES (?, ?, ?)',
    );

    for (final doc in docs) {
      insertNote.execute([
        doc.meta.id,
        doc.meta.title,
        doc.meta.path,
        doc.meta.updatedAt.millisecondsSinceEpoch,
        jsonEncode(doc.meta.tags),
      ]);
      insertFts.execute([
        doc.meta.id,
        doc.meta.title,
        doc.body,
      ]);
    }

    insertNote.close();
    insertFts.close();
  }

  void replaceLinks(List<NoteLink> links) {
    final db = _db;
    if (db == null) {
      return;
    }
    db.execute('DELETE FROM links');
    final insertLink = db.prepare(
      'INSERT INTO links (from_id, to_id, type, source, raw_target, from_anchor, to_anchor, summary) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    for (final link in links) {
      insertLink.execute([
        link.fromId,
        link.toId,
        link.type,
        link.source,
        link.rawTarget,
        link.fromAnchor,
        link.toAnchor,
        link.summary,
      ]);
    }
    insertLink.close();
  }

  List<String> searchNoteIds(String query) {
    final db = _db;
    if (db == null) {
      return const [];
    }
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    try {
      final result = db.select(
        'SELECT id FROM fts_notes WHERE fts_notes MATCH ? LIMIT 200',
        [trimmed],
      );
      return result.map((row) => row['id'] as String).toList();
    } catch (_) {
      return const [];
    }
  }

  void _initSchema() {
    final db = _db;
    if (db == null) {
      return;
    }
    db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        path TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        tags TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS fts_notes
      USING fts5(id, title, body)
    ''');
    db.execute('DROP TABLE IF EXISTS links');
    db.execute('''
      CREATE TABLE links (
        from_id TEXT NOT NULL,
        to_id TEXT NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        raw_target TEXT NOT NULL,
        from_anchor TEXT,
        to_anchor TEXT,
        summary TEXT
      )
    ''');
  }
}
