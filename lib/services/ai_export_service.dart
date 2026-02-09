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
    const schemaVersion = '2.0';
    const generator = {'app': 'AI Notes Desktop', 'module': 'AIExportService'};
    Map<String, dynamic> buildMeta(String kind) => {
      'schema_version': schemaVersion,
      'generated_at': now,
      'machine_generated': true,
      'generator': generator,
      'kind': kind,
    };
    final notes = docs
        .map(
          (doc) => {
            'id': doc.meta.id,
            'title': doc.meta.title,
            'path': doc.meta.path,
            'relative_path': p.relative(doc.meta.path, from: vault.path),
            'tags': doc.meta.tags,
            'updated_at': doc.meta.updatedAt.toIso8601String(),
          },
        )
        .toList();

    final vaultIndex = {
      'meta': buildMeta('vault_index'),
      'generated_at': now,
      'note_count': notes.length,
      'notes': notes,
    };

    final linkGraph = {
      'meta': buildMeta('link_graph'),
      'generated_at': now,
      'node_count': notes.length,
      'edge_count': links.length,
      'nodes': notes
          .map(
            (note) => {
              'id': note['id'],
              'title': note['title'],
              'path': note['relative_path'],
            },
          )
          .toList(),
      'edges': links
          .map(
            (link) => {
              'from': link.fromId,
              'to': link.toId,
              'type': link.type,
              'source': link.source,
              if (link.fromAnchor != null) 'from_anchor': link.fromAnchor,
              if (link.toAnchor != null) 'to_anchor': link.toAnchor,
              if (link.summary != null) 'summary': link.summary,
            },
          )
          .toList(),
    };

    final manifest = docs
        .map((doc) {
          return jsonEncode({
            'id': doc.meta.id,
            'title': doc.meta.title,
            'path': p.relative(doc.meta.path, from: vault.path),
            'tags': doc.meta.tags,
          });
        })
        .join('\n');

    final exportManifest = {
      'meta': buildMeta('ai_export_manifest'),
      'vault': {'note_count': notes.length},
      'files': [
        {
          'name': 'vault_index.json',
          'kind': 'vault_index',
          'format': 'json',
          'schema_version': schemaVersion,
        },
        {
          'name': 'link_graph.json',
          'kind': 'link_graph',
          'format': 'json',
          'schema_version': schemaVersion,
        },
        {
          'name': 'note_manifest.jsonl',
          'kind': 'note_manifest',
          'format': 'jsonl',
          'schema_version': schemaVersion,
          'fields': ['id', 'title', 'path', 'tags'],
        },
      ],
    };

    await File(
      p.join(aiDir.path, 'vault_index.json'),
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(vaultIndex));
    await File(
      p.join(aiDir.path, 'link_graph.json'),
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(linkGraph));
    await File(
      p.join(aiDir.path, 'note_manifest.jsonl'),
    ).writeAsString(manifest);
    await File(
      p.join(aiDir.path, 'ai_export_manifest.json'),
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(exportManifest));
  }
}
