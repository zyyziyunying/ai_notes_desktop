import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:watcher/watcher.dart';

import '../models/note_models.dart';
import 'ai_export_service.dart';
import 'index_service.dart';
import 'link_resolver.dart';
import 'note_parser.dart';
import 'relation_type_service.dart';

class VaultController extends ChangeNotifier {
  VaultController({
    NoteParser? parser,
    IndexService? indexService,
    AIExportService? exportService,
  })  : _parser = parser ?? NoteParser(),
        _indexService = indexService ?? IndexService(),
        _exportService = exportService ?? AIExportService();

  final NoteParser _parser;
  final IndexService _indexService;
  final AIExportService _exportService;
  final Uuid _uuid = const Uuid();
  final RelationTypeService _relationTypeService = RelationTypeService();

  Directory? _vaultDir;
  String _status = '未选择笔记库';
  List<NoteDocument> _documents = [];
  List<NoteMeta> _notes = [];
  List<NoteMeta> _filteredNotes = [];
  List<NoteLink> _links = [];
  Map<String, List<NoteLink>> _backlinks = {};
  NoteDocument? _current;
  List<String> _relationTypes = List<String>.from(
    RelationTypeService.defaultTypes,
  );
  StreamSubscription<WatchEvent>? _watcher;
  Timer? _watchDebounce;
  Timer? _indexDebounce;
  int _searchToken = 0;
  String _searchQuery = '';

  Directory? get vaultDir => _vaultDir;
  String get status => _status;
  List<NoteMeta> get notes => _filteredNotes;
  List<NoteMeta> get allNotes => _notes;
  NoteDocument? get current => _current;
  String get searchQuery => _searchQuery;
  List<NoteLink> get links => _links;
  List<String> get relationTypes => List<String>.unmodifiable(_relationTypes);

  NoteMeta? noteById(String id) {
    for (final note in _notes) {
      if (note.id == id) {
        return note;
      }
    }
    return null;
  }

  List<NoteLink> outgoingLinksFor(String noteId) {
    return _links.where((link) => link.fromId == noteId).toList();
  }

  List<NoteLink> incomingLinksFor(String noteId) {
    return _backlinks[noteId] ?? const [];
  }

  Future<void> openVault(Directory dir) async {
    _vaultDir = dir;
    _status = '正在打开笔记库...';
    notifyListeners();

    final indexPath = await _resolveIndexPath(dir);
    _indexService.dispose();
    _indexService.open(indexPath);

    _relationTypes = await _relationTypeService.loadTypes(dir);
    await _indexAll();
    _watchVault(dir);
  }

  Future<void> createNote() async {
    final vault = _vaultDir;
    if (vault == null) {
      return;
    }
    final baseName = _suggestNewTitle();
    final filePath = _uniqueNotePath(vault, baseName);
    final frontmatter = {
      'id': _uuid.v4(),
      'title': baseName,
      'tags': <String>[],
      'links': <Map<String, dynamic>>[],
    };
    final content = _parser.buildNoteContent(frontmatter, '');
    File(filePath).writeAsStringSync(content);
    await _indexAll(selectPath: filePath);
  }

  Future<void> saveCurrent({required String body, required String title}) async {
    final current = _current;
    if (current == null) {
      return;
    }
    final frontmatter = Map<String, dynamic>.from(current.frontmatter);
    frontmatter['title'] = title.trim().isEmpty ? current.meta.title : title;
    final content = _parser.buildNoteContent(frontmatter, body);
    File(current.meta.path).writeAsStringSync(content);
    await _indexAll(selectPath: current.meta.path);
  }

  Future<void> updateFrontmatterLinks(List<FrontmatterLink> links) async {
    final current = _current;
    if (current == null) {
      return;
    }
    final frontmatter = Map<String, dynamic>.from(current.frontmatter);
    frontmatter['links'] = links
        .map((link) => {
              'to': link.to,
              'type': link.type,
              if (link.note != null && link.note!.trim().isNotEmpty)
                'note': link.note,
            })
        .toList();
    final content = _parser.buildNoteContent(frontmatter, current.body);
    File(current.meta.path).writeAsStringSync(content);
    await _indexAll(selectPath: current.meta.path);
  }

  Future<void> updateRelationTypes(List<String> types) async {
    final vault = _vaultDir;
    if (vault == null) {
      return;
    }
    final cleaned = types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    _relationTypes = cleaned.isEmpty
        ? List<String>.from(RelationTypeService.defaultTypes)
        : cleaned;
    await _relationTypeService.saveTypes(vault, _relationTypes);
    notifyListeners();
  }

  void selectNoteById(String id) {
    if (_documents.isEmpty) {
      return;
    }
    final doc = _documents.firstWhere(
      (item) => item.meta.id == id,
      orElse: () => _current ?? _documents.first,
    );
    _current = doc;
    notifyListeners();
  }

  void selectNoteByTarget(String target) {
    if (_documents.isEmpty) {
      return;
    }
    final normalized = target.trim().toLowerCase();
    final doc = _documents.firstWhere(
      (item) =>
          item.meta.id == target ||
          item.meta.title.toLowerCase() == normalized ||
          p.basenameWithoutExtension(item.meta.path).toLowerCase() ==
              normalized,
      orElse: () => _current ?? _documents.first,
    );
    _current = doc;
    notifyListeners();
  }

  Future<void> updateSearchQuery(String query) async {
    _searchQuery = query;
    final token = ++_searchToken;
    if (query.trim().isEmpty) {
      _filteredNotes = List.of(_notes);
      notifyListeners();
      return;
    }
    final ids = await Future(() => _indexService.searchNoteIds(query));
    if (token != _searchToken) {
      return;
    }
    if (_notes.isEmpty) {
      _filteredNotes = [];
      notifyListeners();
      return;
    }
    _filteredNotes = ids
        .map((id) => _notes.firstWhere(
              (note) => note.id == id,
              orElse: () => _notes.first,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> exportAI() async {
    final vault = _vaultDir;
    if (vault == null) {
      return;
    }
    await _exportService.exportVault(vault, _documents, _links);
    _status = 'AI 索引已导出';
    notifyListeners();
  }

  void disposeController() {
    _watcher?.cancel();
    _watchDebounce?.cancel();
    _indexDebounce?.cancel();
    _indexService.dispose();
  }

  Future<void> _indexAll({String? selectPath}) async {
    final vault = _vaultDir;
    if (vault == null) {
      return;
    }
    _status = '正在索引笔记...';
    notifyListeners();

    final files = await _scanMarkdownFiles(vault);
    final docs = <NoteDocument>[];

    for (final file in files) {
      final result = _parser.parseFile(file);
      docs.add(result.document);
    }

    docs.sort((a, b) => a.meta.title.compareTo(b.meta.title));

    final titleToId = <String, String>{};
    final pathToId = <String, String>{};

    for (final doc in docs) {
      titleToId[doc.meta.title.toLowerCase()] = doc.meta.id;
      pathToId[p.basenameWithoutExtension(doc.meta.path).toLowerCase()] =
          doc.meta.id;
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

    final backlinks = <String, List<NoteLink>>{};
    for (final link in links) {
      backlinks.putIfAbsent(link.toId, () => []).add(link);
    }

    _documents = docs;
    _notes = docs.map((doc) => doc.meta).toList();
    if (_searchQuery.trim().isEmpty) {
      _filteredNotes = List.of(_notes);
    }
    _links = links;
    _backlinks = backlinks;

    _indexService.replaceNotes(docs);
    _indexService.replaceLinks(links);
    await _exportService.exportVault(vault, docs, links);

    if (docs.isNotEmpty) {
      if (selectPath != null) {
        final selected = docs.firstWhere(
          (doc) => doc.meta.path == selectPath,
          orElse: () => docs.first,
        );
        _current = selected;
      } else if (_current == null ||
          !docs.any((doc) => doc.meta.id == _current!.meta.id)) {
        _current = docs.first;
      } else {
        _current = docs.firstWhere(
          (doc) => doc.meta.id == _current!.meta.id,
          orElse: () => docs.first,
        );
      }
    } else {
      _current = null;
    }

    if (_searchQuery.trim().isNotEmpty) {
      await updateSearchQuery(_searchQuery);
    }

    _status = '索引完成：${docs.length} 条笔记';
    notifyListeners();
  }

  void _watchVault(Directory dir) {
    _watcher?.cancel();
    _watcher = DirectoryWatcher(dir.path).events.listen((event) {
      if (!_isMarkdownFile(event.path)) {
        return;
      }
      if (_isIgnoredPath(event.path, dir.path)) {
        return;
      }
      _watchDebounce?.cancel();
      _watchDebounce = Timer(const Duration(milliseconds: 600), () {
        _indexDebounce?.cancel();
        _indexDebounce = Timer(const Duration(milliseconds: 300), () {
          _indexAll();
        });
      });
    });
  }

  Future<List<File>> _scanMarkdownFiles(Directory root) async {
    final files = <File>[];
    final stream = root.list(recursive: true, followLinks: false);
    await for (final entity in stream) {
      if (entity is! File) {
        continue;
      }
      if (!_isMarkdownFile(entity.path)) {
        continue;
      }
      if (_isIgnoredPath(entity.path, root.path)) {
        continue;
      }
      files.add(entity);
    }
    return files;
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

  String _uniqueNotePath(Directory vault, String baseName) {
    final sanitized = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
    var candidate = p.join(vault.path, '$sanitized.md');
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(vault.path, '$sanitized ($counter).md');
      counter++;
    }
    return candidate;
  }

  String _suggestNewTitle() {
    final base = 'New Note';
    if (_notes.every((note) => note.title != base)) {
      return base;
    }
    var counter = 2;
    while (_notes.any((note) => note.title == '$base $counter')) {
      counter++;
    }
    return '$base $counter';
  }

  Future<String> _resolveIndexPath(Directory vault) async {
    final supportDir = await getApplicationSupportDirectory();
    final sanitized = vault.path.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final folder =
        Directory(p.join(supportDir.path, 'ai_notes_desktop', sanitized));
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return p.join(folder.path, 'index.db');
  }
}
