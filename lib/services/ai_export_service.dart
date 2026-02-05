import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/note_models.dart';

class AIExportService {
  Future<void> exportVault(
    Directory vault,
    List<NoteDocument> docs,
    List<NoteLink> links,
  ) async {
    final aiDir = Directory(p.join(vault.path, '.ai'));
    if (!aiDir.existsSync()) {
      aiDir.createSync(recursive: true);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final notes = docs
        .map((doc) => {
              'id': doc.meta.id,
              'title': doc.meta.title,
              'path': doc.meta.path,
              'relative_path': p.relative(doc.meta.path, from: vault.path),
              'tags': doc.meta.tags,
              'updated_at': doc.meta.updatedAt.toIso8601String(),
            })
        .toList();

    final vaultIndex = {
      'generated_at': now,
      'note_count': notes.length,
      'notes': notes,
    };

    final linkGraph = {
      'generated_at': now,
      'nodes': notes
          .map((note) => {
                'id': note['id'],
                'title': note['title'],
                'path': note['relative_path'],
              })
          .toList(),
      'edges': links
          .map((link) => {
                'from': link.fromId,
                'to': link.toId,
                'type': link.type,
                'source': link.source,
                'raw_target': link.rawTarget,
              })
          .toList(),
    };

    final manifest = docs.map((doc) {
      return jsonEncode({
        'id': doc.meta.id,
        'title': doc.meta.title,
        'path': p.relative(doc.meta.path, from: vault.path),
        'tags': doc.meta.tags,
      });
    }).join('\n');

    await File(p.join(aiDir.path, 'vault_index.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(vaultIndex));
    await File(p.join(aiDir.path, 'link_graph.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(linkGraph));
    await File(p.join(aiDir.path, 'note_manifest.jsonl')).writeAsString(manifest);
  }
}
