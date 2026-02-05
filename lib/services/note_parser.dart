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

  NoteParserResult parseFile(File file, {bool writeBackIfMissing = true}) {
    final raw = file.readAsStringSync();
    final parsed = _parseFrontmatter(raw);

    final frontmatter = parsed.frontmatter;
    final body = parsed.body;
    var didUpdateFile = false;

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
    if (links is List) {
      final result = <FrontmatterLink>[];
      for (final item in links) {
        if (item is Map) {
          final to = item['to'];
          if (to is String && to.trim().isNotEmpty) {
            final type = item['type'];
            final note = item['note'];
            result.add(FrontmatterLink(
              to: to.trim(),
              type: type is String && type.trim().isNotEmpty
                  ? type.trim()
                  : 'relates_to',
              note: note is String ? note.trim() : null,
            ));
          }
        }
      }
      return result;
    }
    return <FrontmatterLink>[];
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
