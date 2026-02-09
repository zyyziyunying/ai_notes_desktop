import 'dart:io';

import '../../models/note_models.dart';
import 'link_graph_builder.dart';
import 'vault_file_watcher_mixin.dart';
import 'vault_link_mixin.dart';
import 'vault_note_crud_mixin.dart';
import 'vault_search_mixin.dart';
import 'vault_state.dart';

/// 笔记库控制器 — 薄协调层。
///
/// 各职责由 mixin 提供，VaultController 仅负责：
/// - 打开笔记库 [openVault]
/// - 全量索引 [indexAll]
/// - AI 导出 [exportAI]
/// - 生命周期 [disposeController]
class VaultController extends VaultState
    with
        VaultFileWatcherMixin,
        VaultSearchMixin,
        VaultLinkMixin,
        VaultNoteCrudMixin {
  VaultController({
    super.parser,
    super.indexService,
    super.exportService,
  });

  final LinkGraphBuilder _graphBuilder = const LinkGraphBuilder();

  Future<void> openVault(Directory dir) async {
    vaultDirS.value = dir;
    statusS.value = '正在打开笔记库...';

    final indexPath = await resolveIndexPath(dir);
    indexService.dispose();
    indexService.open(indexPath);

    relationTypesS.value = await relationTypeService.loadTypes(dir);
    await indexAll();
    watchVault(dir);
  }

  @override
  Future<void> indexAll({String? selectPath}) async {
    final vault = vaultDirS.value;
    if (vault == null) return;
    statusS.value = '正在索引笔记...';

    // 1. 扫描 & 解析
    final files = await scanMarkdownFiles(vault);
    final docs = <NoteDocument>[];
    for (final file in files) {
      docs.add(parser.parseFile(file).document);
    }
    docs.sort((a, b) => a.meta.title.compareTo(b.meta.title));

    // 2. 构建链接图
    final graph = _graphBuilder.build(docs);

    // 3. 更新 Signals
    documentsS.value = docs;
    notesS.value = docs.map((doc) => doc.meta).toList();
    if (searchQueryS.value.trim().isEmpty) {
      filteredNotesS.value = List.of(notesS.value);
    }
    linksS.value = graph.links;
    backlinksS.value = graph.backlinks;

    // 4. 持久化索引
    indexService.replaceNotes(docs);
    indexService.replaceLinks(graph.links);
    await exportService.exportVault(vault, docs, graph.links);

    // 5. 选中笔记
    _resolveCurrentSelection(docs, selectPath);

    // 6. 搜索过滤
    if (searchQueryS.value.trim().isNotEmpty) {
      await updateSearchQuery(searchQueryS.value);
    }

    statusS.value = '索引完成：${docs.length} 条笔记';
  }

  Future<void> exportAI() async {
    final vault = vaultDirS.value;
    if (vault == null) return;
    await exportService.exportVault(vault, documentsS.value, linksS.value);
    statusS.value = 'AI 索引已导出';
  }

  void disposeController() {
    disposeWatcher();
    indexService.dispose();
  }

  void _resolveCurrentSelection(List<NoteDocument> docs, String? selectPath) {
    if (docs.isEmpty) {
      currentS.value = null;
      return;
    }
    if (selectPath != null) {
      currentS.value = docs.firstWhere(
        (doc) => doc.meta.path == selectPath,
        orElse: () => docs.first,
      );
    } else if (currentS.value == null ||
        !docs.any((doc) => doc.meta.id == currentS.value!.meta.id)) {
      currentS.value = docs.first;
    } else {
      currentS.value = docs.firstWhere(
        (doc) => doc.meta.id == currentS.value!.meta.id,
        orElse: () => docs.first,
      );
    }
  }
}
