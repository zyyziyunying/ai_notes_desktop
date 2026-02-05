import 'dart:io';

import 'package:collection/collection.dart';
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

  NoteParserResult parseFile(File file, {bool writeBackIfMissing = true}) {
    final raw = file.readAsStringSync();
    final parsed = _parseFrontmatter(raw);

    final frontmatter = parsed.frontmatter;
    final body = parsed.body;
    var didUpdateFile = false;

    final embeddedLinks = _extractEmbeddedLinks(body);
    if (embeddedLinks.hasBlock) {
      final normalizedEmbedded =
          _normalizeLinksForFrontmatter(embeddedLinks.links);
      final normalizedExisting =
          _normalizeLinksForFrontmatter(_extractFrontmatterLinks(frontmatter));
      if (!const DeepCollectionEquality()
          .equals(normalizedEmbedded, normalizedExisting)) {
        frontmatter['links'] = normalizedEmbedded;
        didUpdateFile = true;
      }
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
    final links = _extractFrontmatterLinks(frontmatter);
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
        frontmatterLinks: links,
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

  List<FrontmatterLink> _extractFrontmatterLinks(
    Map<String, dynamic> map,
  ) {
    final links = map['links'];
    if (links == null) {
      return <FrontmatterLink>[];
    }
    return _frontmatterLinksFromDynamic(links);
  }

  _EmbeddedLinksResult _extractEmbeddedLinks(String body) {
    final blocks = _extractLinkBlocks(body);
    if (blocks.isEmpty) {
      return const _EmbeddedLinksResult(hasBlock: false, links: []);
    }
    final links = <FrontmatterLink>[];
    for (final block in blocks) {
      links.addAll(_parseLinksYaml(block));
    }
    return _EmbeddedLinksResult(
      hasBlock: true,
      links: _dedupeLinks(links),
    );
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

  List<FrontmatterLink> _parseLinksYaml(String yamlContent) {
    final trimmed = yamlContent.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    try {
      final parsed = loadYaml(trimmed);
      final normalized = _convertYamlValue(parsed);
      return _frontmatterLinksFromDynamic(normalized);
    } catch (_) {
      return const [];
    }
  }

  List<FrontmatterLink> _frontmatterLinksFromDynamic(dynamic value) {
    if (value is Map) {
      if (value.containsKey('links')) {
        return _frontmatterLinksFromDynamic(value['links']);
      }
      final toValue = value['to'];
      if (toValue is String && toValue.trim().isNotEmpty) {
        final type = value['type'];
        final note = value['note'];
        final fromBlock = _readBlockField(value, 'from', 'from_block') ??
            _readBlockField(value, 'fromBlock');
        final explicitToBlock = _readBlockField(value, 'to_block', 'toBlock') ??
            _readBlockField(value, 'block');
        final extractedToBlock = explicitToBlock ?? _extractAnchor(toValue);
        final normalizedToBlock = extractedToBlock == null
            ? null
            : _normalizeBlockId(extractedToBlock);
        final to = _stripAnchor(toValue).trim();
        return [
          FrontmatterLink(
            to: to,
            type: type is String && type.trim().isNotEmpty
                ? type.trim()
                : 'relates_to',
            note: note is String ? note.trim() : null,
            fromBlock: fromBlock == null ? null : _normalizeBlockId(fromBlock),
            toBlock: normalizedToBlock,
          ),
        ];
      }
      return const [];
    }
    if (value is List) {
      final result = <FrontmatterLink>[];
      for (final item in value) {
        if (item is String) {
          final trimmed = item.trim();
          if (trimmed.isNotEmpty) {
            final toBlock = _extractAnchor(trimmed);
            result.add(
              FrontmatterLink(
                to: _stripAnchor(trimmed).trim(),
                type: 'relates_to',
                toBlock: toBlock == null ? null : _normalizeBlockId(toBlock),
              ),
            );
          }
          continue;
        }
        if (item is Map) {
          final toValue = item['to'];
          if (toValue is String && toValue.trim().isNotEmpty) {
            final type = item['type'];
            final note = item['note'];
            final fromBlock = _readBlockField(item, 'from', 'from_block') ??
                _readBlockField(item, 'fromBlock');
            final explicitToBlock =
                _readBlockField(item, 'to_block', 'toBlock') ??
                    _readBlockField(item, 'block');
            final extractedToBlock = explicitToBlock ?? _extractAnchor(toValue);
            final normalizedToBlock = extractedToBlock == null
                ? null
                : _normalizeBlockId(extractedToBlock);
            final to = _stripAnchor(toValue).trim();
            result.add(FrontmatterLink(
              to: to,
              type: type is String && type.trim().isNotEmpty
                  ? type.trim()
                  : 'relates_to',
              note: note is String ? note.trim() : null,
              fromBlock:
                  fromBlock == null ? null : _normalizeBlockId(fromBlock),
              toBlock: normalizedToBlock,
            ));
          }
        }
      }
      return result;
    }
    return const [];
  }

  List<FrontmatterLink> _dedupeLinks(List<FrontmatterLink> links) {
    if (links.isEmpty) {
      return links;
    }
    final seen = <String>{};
    final deduped = <FrontmatterLink>[];
    for (final link in links) {
      final key = '${link.to}\u0000${link.type}\u0000${link.note ?? ''}\u0000'
          '${link.fromBlock ?? ''}\u0000${link.toBlock ?? ''}';
      if (seen.add(key)) {
        deduped.add(link);
      }
    }
    return deduped;
  }

  List<Map<String, dynamic>> _normalizeLinksForFrontmatter(
    List<FrontmatterLink> links,
  ) {
    return links.map((link) {
      final map = <String, dynamic>{
        'to': link.to,
        'type': link.type,
      };
      final note = link.note?.trim();
      if (note != null && note.isNotEmpty) {
        map['note'] = note;
      }
      final fromBlock = link.fromBlock?.trim();
      if (fromBlock != null && fromBlock.isNotEmpty) {
        map['from'] = fromBlock;
      }
      final toBlock = link.toBlock?.trim();
      if (toBlock != null && toBlock.isNotEmpty) {
        map['to_block'] = toBlock;
      }
      return map;
    }).toList();
  }

  String? _readBlockField(
    Map<dynamic, dynamic> map,
    String key, [
    String? fallbackKey,
  ]) {
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

  String _normalizeBlockId(String block) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.startsWith('^') ? trimmed : '^$trimmed';
  }

  String? _extractAnchor(String raw) {
    final trimmed = raw.trim();
    final index = trimmed.indexOf('#');
    if (index == -1 || index == trimmed.length - 1) {
      return null;
    }
    final anchor = trimmed.substring(index + 1).trim();
    if (anchor.isEmpty) {
      return null;
    }
    return anchor;
  }

  String _stripAnchor(String raw) {
    final index = raw.indexOf('#');
    if (index == -1) {
      return raw;
    }
    return raw.substring(0, index);
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

class _EmbeddedLinksResult {
  const _EmbeddedLinksResult({
    required this.hasBlock,
    required this.links,
  });

  final bool hasBlock;
  final List<FrontmatterLink> links;
}

class _FrontmatterParseResult {
  _FrontmatterParseResult({
    required this.frontmatter,
    required this.body,
  });

  final Map<String, dynamic> frontmatter;
  final String body;
}
