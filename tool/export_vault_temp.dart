import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:ai_notes_desktop/models/note_models.dart';
import 'package:ai_notes_desktop/services/ai_export_service.dart';
import 'package:ai_notes_desktop/services/link_resolver.dart';
import 'package:ai_notes_desktop/services/note_parser.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/export_vault_temp.dart <vault_path>');
    exit(1);
  }
  final vault = Directory(args.first);
  if (!vault.existsSync()) {
    stderr.writeln('Vault not found: ${vault.path}');
    exit(1);
  }

  final parser = NoteParser();
  final docs = <NoteDocument>[];

  await for (final entity in vault.list(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (!_isMarkdownFile(entity.path)) {
      continue;
    }
    if (_isIgnoredPath(entity.path, vault.path)) {
      continue;
    }
    final result = parser.parseFile(entity);
    docs.add(result.document);
  }

  docs.sort((a, b) => a.meta.title.compareTo(b.meta.title));

  final titleToId = <String, String>{};
  final pathToId = <String, String>{};
  for (final doc in docs) {
    titleToId[doc.meta.title.toLowerCase()] = doc.meta.id;
    pathToId[p.basenameWithoutExtension(doc.meta.path).toLowerCase()] = doc.meta.id;
  }

  final links = <NoteLink>[];
  for (final doc in docs) {
    final wikiTargets = LinkResolver.extractWikiTargets(doc.body);
    for (final target in wikiTargets) {
      final toId = LinkResolver.resolveTarget(target, titleToId, pathToId);
      if (toId == null) {
        continue;
      }
      links.add(NoteLink(
        fromId: doc.meta.id,
        toId: toId,
        type: 'wikilink',
        source: 'body',
        rawTarget: target,
      ));
    }

    for (final link in doc.frontmatterLinks) {
      final toId = LinkResolver.resolveTarget(link.to, titleToId, pathToId);
      if (toId == null) {
        continue;
      }
      links.add(NoteLink(
        fromId: doc.meta.id,
        toId: toId,
        type: link.type,
        source: 'frontmatter',
        rawTarget: link.to,
      ));
    }
  }

  final exportService = AIExportService();
  await exportService.exportVault(vault, docs, links);

  stdout.writeln('Exported ${docs.length} notes, ${links.length} links.');
  stdout.writeln('AI output dir: ${p.join(vault.path, '.ai')}');
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
