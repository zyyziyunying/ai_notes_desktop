import 'dart:io';

import 'package:path/path.dart' as p;

import '../../models/note_models.dart';
import '../relation_type_service.dart';
import 'vault_state.dart';

/// 链接与关系类型管理。
mixin VaultLinkMixin on VaultState {
  List<NoteLink> outgoingLinksFor(String noteId) {
    return linksS.value.where((link) => link.fromId == noteId).toList();
  }

  List<NoteLink> incomingLinksFor(String noteId) {
    return backlinksS.value[noteId] ?? const [];
  }

  Future<void> updateFrontmatterLinks(List<FrontmatterLink> links) async {
    final current = currentS.value;
    if (current == null) return;
    final frontmatter = Map<String, dynamic>.from(current.frontmatter);
    frontmatter['links'] = links
        .map((link) => {
              'to': link.to,
              'type': link.type,
              if (link.fromBlock != null && link.fromBlock!.trim().isNotEmpty)
                'from': link.fromBlock,
              if (link.toBlock != null && link.toBlock!.trim().isNotEmpty)
                'to_block': link.toBlock,
              if (link.note != null && link.note!.trim().isNotEmpty)
                'note': link.note,
            })
        .toList();
    final content = parser.buildNoteContent(frontmatter, current.body);
    File(current.meta.path).writeAsStringSync(content);
    await indexAll(selectPath: current.meta.path);
  }

  Future<void> updateRelationTypes(List<String> types) async {
    final vault = vaultDirS.value;
    if (vault == null) return;
    final cleaned = types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    relationTypesS.value = cleaned.isEmpty
        ? List<String>.from(RelationTypeService.defaultTypes)
        : cleaned;
    await relationTypeService.saveTypes(vault, relationTypesS.value);
  }

  void selectNoteById(String id) {
    if (documentsS.value.isEmpty) return;
    final doc = documentsS.value.firstWhere(
      (item) => item.meta.id == id,
      orElse: () => currentS.value ?? documentsS.value.first,
    );
    currentS.value = doc;
  }

  void selectNoteByTarget(String target) {
    if (documentsS.value.isEmpty) return;
    final trimmed = target.trim();
    final base = trimmed.split('#').first.trim();
    final normalized = base.toLowerCase();
    final idCandidate = base.startsWith('id:') ? base.substring(3) : base;
    final doc = documentsS.value.firstWhere(
      (item) =>
          item.meta.id == idCandidate ||
          item.meta.title.toLowerCase() == normalized ||
          p.basenameWithoutExtension(item.meta.path).toLowerCase() ==
              normalized,
      orElse: () => currentS.value ?? documentsS.value.first,
    );
    currentS.value = doc;
  }

  /// 由 VaultController 实现，触发全量索引。
  Future<void> indexAll({String? selectPath});
}
