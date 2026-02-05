import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../dialogs/link_editor_dialog.dart';
import '../dialogs/types_dialog.dart';
import '../main.dart';
import '../models/note_models.dart';
import '../services/vault_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_panel.dart';
import '../widgets/graph_panel.dart';
import '../widgets/links_panel.dart';
import '../widgets/notes_panel.dart';
import '../widgets/preview_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VaultController _controller = VaultController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _saveTimer;
  String? _currentId;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.disposeController();
    _controller.removeListener(_onControllerChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _searchController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    final current = _controller.current;
    if (current == null) {
      _currentId = null;
      _titleController.text = '';
      _bodyController.text = '';
      setState(() {});
      return;
    }
    if (_currentId != current.meta.id) {
      _currentId = current.meta.id;
      _titleController.text = current.meta.title;
      _bodyController.text = current.body;
    }
    setState(() {});
  }

  Future<void> _selectVault() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择 Markdown 笔记库目录',
    );
    if (path == null) {
      return;
    }
    await _controller.openVault(Directory(path));
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      final current = _controller.current;
      if (current == null) {
        return;
      }
      _controller.saveCurrent(
        body: _bodyController.text,
        title: _titleController.text,
      );
    });
    setState(() {});
  }

  String _renderMarkdown(String body) {
    return body.replaceAllMapped(RegExp(r'\[\[([^\[\]]+)\]\]'), (match) {
      final raw = match.group(1) ?? '';
      final parts = raw.split('|');
      final target = parts.first.trim();
      final label = parts.length > 1 ? parts[1].trim() : target;
      final encoded = Uri.encodeComponent(target);
      return '[$label](note://$encoded)';
    });
  }

  Future<void> _openLinkEditor(NoteDocument current) async {
    await showLinkEditorDialog(
      context: context,
      current: current,
      relationTypes: _controller.relationTypes,
      onSave: _controller.updateFrontmatterLinks,
    );
  }

  Future<void> _openTypesDialog() async {
    await showTypesDialog(
      context: context,
      initialTypes: _controller.relationTypes,
      onSave: _controller.updateRelationTypes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _controller.current;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_controller.vaultDir?.path ?? '请选择笔记库'),
          actions: [
            // 主题切换按钮
            PopupMenuButton<ColorPalette>(
              icon: const Icon(Icons.palette_outlined),
              tooltip: '配色方案',
              onSelected: themeController.setPalette,
              itemBuilder: (context) => ColorPalette.values
                  .map(
                    (p) => PopupMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          if (themeController.palette == p)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(p.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            IconButton(
              icon: Icon(themeController.themeModeIcon),
              tooltip: themeController.themeModeLabel,
              onPressed: themeController.toggleThemeMode,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _selectVault,
              icon: const Icon(Icons.folder_open),
              label: const Text('打开'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _controller.vaultDir == null ? null : _openTypesDialog,
              icon: const Icon(Icons.schema_outlined),
              label: const Text('关系类型'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed:
                  _controller.vaultDir == null ? null : _controller.createNote,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('新建'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed:
                  _controller.vaultDir == null ? null : _controller.exportAI,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('导出 AI 索引'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            SizedBox(
              width: 260,
              child: NotesPanel(
                searchController: _searchController,
                notes: _controller.notes,
                currentId: _controller.current?.meta.id,
                onSearch: _controller.updateSearchQuery,
                onSelect: _controller.selectNoteById,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: current == null
                  ? const Center(child: Text('请选择或创建笔记'))
                  : EditorPanel(
                      titleController: _titleController,
                      bodyController: _bodyController,
                      onChanged: _scheduleSave,
                    ),
            ),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 360,
              child: current == null
                  ? const Center(child: Text('预览区'))
                  : PreviewPanel(
                      renderedMarkdown: _renderMarkdown(_bodyController.text),
                      onTapLink: (text, href, title) {
                        if (href == null) {
                          return;
                        }
                        if (href.startsWith('note://')) {
                          final target =
                              Uri.decodeComponent(href.substring(7));
                          _controller.selectNoteByTarget(target);
                        }
                      },
                      linksPanel: LinksPanel(
                        current: current,
                        outgoing:
                            _controller.outgoingLinksFor(current.meta.id),
                        incoming:
                            _controller.incomingLinksFor(current.meta.id),
                        onEdit: () => _openLinkEditor(current),
                        onSelectNote: _controller.selectNoteById,
                        noteById: _controller.noteById,
                      ),
                      graphPanel: GraphPanel(
                        notes: _controller.allNotes,
                        links: _controller.links,
                        onSelectNote: _controller.selectNoteById,
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            _controller.status,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
