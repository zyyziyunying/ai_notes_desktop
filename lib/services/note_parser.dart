import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

import '../models/note_models.dart';
import '../utils/yaml_writer.dart';

class NoteParserResult {
  NoteParserResult({
    required this.document,
    required this.didUpdateFile,
  });

  final NoteDocument document;
  final bool didUpdateFile;
}

class NoteParser {
  NoteParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static final RegExp _arrowLine =
      RegExp(r'^§(\S+)\s*->\s*(.+?)\s+§(\S+)\s*:\s*(\S+)\s*$');
  static final RegExp _summaryLine = RegExp(r'^\|\s*(.+)$');

  NoteParserResult parseFile(File file, {bool writeBackIfMissing = true}) {
    final raw = file.readAsStringSync();
    final parsed = _parseFrontmatter(raw);

    final frontmatter = parsed.frontmatter;
    final body = parsed.body;
    var didUpdateFile = false;

    // Clean up legacy frontmatter links if present
    if (frontmatter.containsKey('links')) {
      frontmatter.remove('links');
      didUpdateFile = true;
    }

    final String id = _ensureId(frontmatter, () {
      didUpdateFile = true;
      return _uuid.v4();
    });

    final title = _ensureTitle(
      frontmatter,
      body,
      fallback: p.basenameWithoutExtension(file.path),
      onWriteBack: () {
        didUpdateFile = true;
      },
    );

    final tags = _extractTags(frontmatter);
    final links = _extractEmbeddedLinks(body);
    final updatedAt = file.lastModifiedSync();

    if (didUpdateFile && writeBackIfMissing) {
      final content = buildNoteContent(frontmatter, body);
      file.writeAsStringSync(content);
    }

    final meta = NoteMeta(
      id: id,
      title: title,
      path: file.path,
      tags: tags,
      updatedAt: updatedAt,
    );

    return NoteParserResult(
      document: NoteDocument(
        meta: meta,
        body: body,
        frontmatter: frontmatter,
        embeddedLinks: links,
      ),
      didUpdateFile: didUpdateFile,
    );
  }

  String buildNoteContent(Map<String, dynamic> frontmatter, String body) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.write(yamlEncode(frontmatter));
    buffer.writeln('---');
    if (body.isNotEmpty) {
      buffer.write(body);
      if (!body.endsWith('\n')) {
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  /// Parse arrow-syntax links from a links block content string.
  List<EmbeddedLink> _parseArrowLinks(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final links = <EmbeddedLink>[];
    for (var i = 0; i < lines.length; i++) {
      final match = _arrowLine.firstMatch(lines[i].trim());
      if (match == null) continue;
      final fromAnchor = match.group(1)!;
      final target = match.group(2)!.trim();
      final toAnchor = match.group(3)!;
      final type = match.group(4)!;
      String? summary;
      if (i + 1 < lines.length) {
        final nextMatch = _summaryLine.firstMatch(lines[i + 1].trim());
        if (nextMatch != null) {
          summary = nextMatch.group(1)!.trim();
          i++;
        }
      }
      links.add(EmbeddedLink(
        to: target,
        type: type,
        fromAnchor: fromAnchor,
        toAnchor: toAnchor,
        summary: summary,
      ));
    }
    return links;
  }

  /// Build the arrow-syntax links block text (including comment delimiters).
  String buildArrowLinksBlock(List<EmbeddedLink> links) {
    if (links.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('<!-- links');
    for (final link in links) {
      buffer.writeln(
        '§${link.fromAnchor ?? '_'} -> ${link.to} §${link.toAnchor ?? '_'} : ${link.type}',
      );
      if (link.summary != null && link.summary!.trim().isNotEmpty) {
        buffer.writeln('| ${link.summary}');
      }
    }
    buffer.write('-->');
    return buffer.toString();
  }

  /// Replace the links comment block in body, or append if not present.
  String replaceLinksBlock(String body, String newBlock) {
    final pattern = RegExp(
      r'<!--\s*(?:links|relations)\b.*?-->',
      dotAll: true,
    );
    if (pattern.hasMatch(body)) {
      return body.replaceAll(pattern, newBlock);
    }
    if (newBlock.isEmpty) return body;
    final trimmed = body.trimRight();
    return '$trimmed\n\n$newBlock\n';
  }

  List<EmbeddedLink> _extractEmbeddedLinks(String body) {
    final blocks = _extractLinkBlocks(body);
    if (blocks.isEmpty) return const [];
    final links = <EmbeddedLink>[];
    for (final block in blocks) {
      // Try arrow syntax first
      final arrowLinks = _parseArrowLinks(block);
      if (arrowLinks.isNotEmpty) {
        links.addAll(arrowLinks);
      } else {
        // Fall back to legacy YAML parsing
        links.addAll(_parseLegacyYamlLinks(block));
      }
    }
    return _dedupeLinks(links);
  }

  /// Legacy YAML link parsing for backward compatibility during migration.
  List<EmbeddedLink> _parseLegacyYamlLinks(String yamlContent) {
    final trimmed = yamlContent.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final parsed = loadYaml(trimmed);
      final normalized = _convertYamlValue(parsed);
      return _legacyLinksFromDynamic(normalized);
    } catch (_) {
      return const [];
    }
  }

  List<EmbeddedLink> _legacyLinksFromDynamic(dynamic value) {
    if (value is Map) {
      if (value.containsKey('links')) {
        return _legacyLinksFromDynamic(value['links']);
      }
      final toValue = value['to'];
      if (toValue is String && toValue.trim().isNotEmpty) {
        final type = value['type'];
        final note = value['note'];
        final fromAnchor = _readStringField(value, 'from', 'from_block') ??
            _readStringField(value, 'fromBlock');
        final explicitToAnchor =
            _readStringField(value, 'to_block', 'toBlock') ??
                _readStringField(value, 'block');
        final extractedToAnchor =
            explicitToAnchor ?? _extractAnchorFromTarget(toValue);
        final to = _stripAnchorFromTarget(toValue).trim();
        return [
          EmbeddedLink(
            to: to,
            type: type is String && type.trim().isNotEmpty
                ? type.trim()
                : 'relates_to',
            summary: note is String ? note.trim() : null,
            fromAnchor: fromAnchor,
            toAnchor: extractedToAnchor,
          ),
        ];
      }
      return const [];
    }
    if (value is List) {
      final result = <EmbeddedLink>[];
      for (final item in value) {
        if (item is String) {
          final trimmed = item.trim();
          if (trimmed.isNotEmpty) {
            final toAnchor = _extractAnchorFromTarget(trimmed);
            result.add(EmbeddedLink(
              to: _stripAnchorFromTarget(trimmed).trim(),
              type: 'relates_to',
              toAnchor: toAnchor,
            ));
          }
          continue;
        }
        if (item is Map) {
          final toValue = item['to'];
          if (toValue is String && toValue.trim().isNotEmpty) {
            final type = item['type'];
            final note = item['note'];
            final fromAnchor =
                _readStringField(item, 'from', 'from_block') ??
                    _readStringField(item, 'fromBlock');
            final explicitToAnchor =
                _readStringField(item, 'to_block', 'toBlock') ??
                    _readStringField(item, 'block');
            final extractedToAnchor =
                explicitToAnchor ?? _extractAnchorFromTarget(toValue);
            final to = _stripAnchorFromTarget(toValue).trim();
            result.add(EmbeddedLink(
              to: to,
              type: type is String && type.trim().isNotEmpty
                  ? type.trim()
                  : 'relates_to',
              summary: note is String ? note.trim() : null,
              fromAnchor: fromAnchor,
              toAnchor: extractedToAnchor,
            ));
          }
        }
      }
      return result;
    }
    return const [];
  }

  String? _readStringField(Map<dynamic, dynamic> map, String key,
      [String? fallbackKey]) {
    final direct = map[key];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    if (fallbackKey != null && fallbackKey.isNotEmpty) {
      final fallback = map[fallbackKey];
      if (fallback is String && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    }
    return null;
  }

  String? _extractAnchorFromTarget(String raw) {
    final trimmed = raw.trim();
    final index = trimmed.indexOf('#');
    if (index == -1 || index == trimmed.length - 1) return null;
    final anchor = trimmed.substring(index + 1).trim();
    return anchor.isEmpty ? null : anchor;
  }

  String _stripAnchorFromTarget(String raw) {
    final index = raw.indexOf('#');
    return index == -1 ? raw : raw.substring(0, index);
  }

  List<EmbeddedLink> _dedupeLinks(List<EmbeddedLink> links) {
    if (links.isEmpty) return links;
    final seen = <String>{};
    final deduped = <EmbeddedLink>[];
    for (final link in links) {
      final key =
          '${link.to}\u0000${link.type}\u0000${link.summary ?? ''}\u0000'
          '${link.fromAnchor ?? ''}\u0000${link.toAnchor ?? ''}';
      if (seen.add(key)) {
        deduped.add(link);
      }
    }
    return deduped;
  }

  List<String> _extractLinkBlocks(String body) {
    final lines = body.split(RegExp(r'\r?\n'));
    final blocks = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('```')) {
        if (_isCommentBlockStart(line)) {
          final buffer = StringBuffer();
          final endIndex = line.indexOf('-->');
          if (endIndex != -1) {
            final inner = line.substring(4, endIndex).trim();
            final content = _stripCommentHeader(inner);
            if (content.isNotEmpty) {
              buffer.writeln(content);
            }
          } else {
            i++;
            for (; i < lines.length; i++) {
              final end = lines[i].indexOf('-->');
              if (end != -1) {
                buffer.writeln(lines[i].substring(0, end));
                break;
              }
              buffer.writeln(lines[i]);
            }
          }
          final block = buffer.toString().trimRight();
          if (block.isNotEmpty) {
            blocks.add(block);
          }
        }
        continue;
      }
      final language = line.substring(3).trim().toLowerCase();
      if (language != 'links' && language != 'relations') {
        continue;
      }
      final buffer = StringBuffer();
      i++;
      for (; i < lines.length; i++) {
        if (lines[i].trim().startsWith('```')) {
          break;
        }
        buffer.writeln(lines[i]);
      }
      blocks.add(buffer.toString().trimRight());
    }
    return blocks;
  }

  bool _isCommentBlockStart(String line) {
    if (!line.startsWith('<!--')) {
      return false;
    }
    final content = line.substring(4).trimLeft().toLowerCase();
    return content.startsWith('links') || content.startsWith('relations');
  }

  String _stripCommentHeader(String content) {
    final trimmed = content.trimLeft();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('links')) {
      return trimmed.substring(5).replaceFirst(RegExp(r'^[:\\s]+'), '');
    }
    if (lower.startsWith('relations')) {
      return trimmed.substring(9).replaceFirst(RegExp(r'^[:\\s]+'), '');
    }
    return trimmed;
  }

  _FrontmatterParseResult _parseFrontmatter(String content) {
    final lines = content.split(RegExp('\r?\n'));
    if (lines.isEmpty || lines.first.trim() != '---') {
      return _FrontmatterParseResult(
        frontmatter: <String, dynamic>{},
        body: content,
      );
    }

    var endIndex = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      return _FrontmatterParseResult(
        frontmatter: <String, dynamic>{},
        body: content,
      );
    }

    final yamlContent = lines.sublist(1, endIndex).join('\n');
    final body = lines.sublist(endIndex + 1).join('\n');
    final yamlMap = yamlContent.trim().isEmpty ? null : loadYaml(yamlContent);

    final frontmatter = _convertYaml(yamlMap);
    return _FrontmatterParseResult(
      frontmatter: frontmatter,
      body: body,
    );
  }

  String _ensureId(Map<String, dynamic> map, String Function() createId) {
    final id = map['id'];
    if (id is String && id.trim().isNotEmpty) {
      return id.trim();
    }
    final newId = createId();
    map['id'] = newId;
    return newId;
  }

  String _ensureTitle(
    Map<String, dynamic> map,
    String body, {
    required String fallback,
    required void Function() onWriteBack,
  }) {
    final existing = map['title'];
    if (existing is String && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final detected = _detectTitleFromBody(body) ?? fallback;
    map['title'] = detected;
    onWriteBack();
    return detected;
  }

  String? _detectTitleFromBody(String body) {
    for (final line in body.split(RegExp('\r?\n'))) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return null;
  }

  List<String> _extractTags(Map<String, dynamic> map) {
    final tags = map['tags'];
    if (tags is List) {
      return tags
          .whereType<String>()
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Map<String, dynamic> _convertYaml(dynamic yamlMap) {
    if (yamlMap is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in yamlMap.entries) {
        map[entry.key.toString()] = _convertYamlValue(entry.value);
      }
      return map;
    }
    if (yamlMap is Map) {
      return yamlMap.map((key, value) => MapEntry(
            key.toString(),
            _convertYamlValue(value),
          ));
    }
    return <String, dynamic>{};
  }

  dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in value.entries) {
        map[entry.key.toString()] = _convertYamlValue(entry.value);
      }
      return map;
    }
    if (value is YamlList) {
      return value.map(_convertYamlValue).toList();
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(
            key.toString(),
            _convertYamlValue(val),
          ));
    }
    if (value is List) {
      return value.map(_convertYamlValue).toList();
    }
    return value;
  }
}

class _FrontmatterParseResult {
  _FrontmatterParseResult({
    required this.frontmatter,
    required this.body,
  });

  final Map<String, dynamic> frontmatter;
  final String body;
}
