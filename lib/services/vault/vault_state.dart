import 'dart:io';

import 'package:signals/signals.dart';

import '../../models/note_models.dart';
import '../ai_export_service.dart';
import '../index_service.dart';
import '../note_parser.dart';
import '../relation_type_service.dart';

/// VaultController 的共享状态基类。
///
/// 持有所有 Signal、服务实例和公共 getter，供各 mixin 访问。
class VaultState {
  VaultState({
    NoteParser? parser,
    IndexService? indexService,
    AIExportService? exportService,
  })  : parser = parser ?? NoteParser(),
        indexService = indexService ?? IndexService(),
        exportService = exportService ?? AIExportService();

  final NoteParser parser;
  final IndexService indexService;
  final AIExportService exportService;
  final RelationTypeService relationTypeService = RelationTypeService();

  // ── Signals ──────────────────────────────────────────────────────────
  final Signal<Directory?> vaultDirS = signal(null);
  final Signal<String> statusS = signal('未选择笔记库');
  final Signal<List<NoteDocument>> documentsS = signal([]);
  final Signal<List<NoteMeta>> notesS = signal([]);
  final Signal<List<NoteMeta>> filteredNotesS = signal([]);
  final Signal<List<NoteLink>> linksS = signal([]);
  final Signal<Map<String, List<NoteLink>>> backlinksS = signal({});
  final Signal<NoteDocument?> currentS = signal(null);
  final Signal<List<String>> relationTypesS = signal(
    List<String>.from(RelationTypeService.defaultTypes),
  );
  final Signal<String> searchQueryS = signal('');

  // ── Public getters (值) ──────────────────────────────────────────────
  Directory? get vaultDir => vaultDirS.value;
  String get status => statusS.value;
  List<NoteMeta> get notes => filteredNotesS.value;
  List<NoteMeta> get allNotes => notesS.value;
  NoteDocument? get current => currentS.value;
  String get searchQuery => searchQueryS.value;
  List<NoteLink> get links => linksS.value;
  List<String> get relationTypes =>
      List<String>.unmodifiable(relationTypesS.value);

  // ── Expose signals for Watch widget ──────────────────────────────────
  Signal<Directory?> get vaultDirSignal => vaultDirS;
  Signal<String> get statusSignal => statusS;
  Signal<List<NoteMeta>> get notesSignal => filteredNotesS;
  Signal<List<NoteMeta>> get allNotesSignal => notesS;
  Signal<NoteDocument?> get currentSignal => currentS;
  Signal<List<NoteLink>> get linksSignal => linksS;
  Signal<List<String>> get relationTypesSignal => relationTypesS;

  // ── 通用查询 ─────────────────────────────────────────────────────────
  NoteMeta? noteById(String id) {
    for (final note in notesS.value) {
      if (note.id == id) return note;
    }
    return null;
  }
}
