import 'package:flutter/material.dart';

import '../models/note_models.dart';

class NotesPanel extends StatelessWidget {
  const NotesPanel({
    super.key,
    required this.searchController,
    required this.notes,
    required this.currentId,
    required this.onSearch,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
  });

  final TextEditingController searchController;
  final List<NoteMeta> notes;
  final String? currentId;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String id, String newTitle) onRename;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索笔记',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final selected = currentId == note.id;
              return GestureDetector(
                onSecondaryTapUp: (details) {
                  _showContextMenu(context, details.globalPosition, note);
                },
                child: ListTile(
                  selected: selected,
                  title: Text(note.title),
                  subtitle: Text(
                    note.tags.isEmpty ? '无标签' : note.tags.join(', '),
                  ),
                  onTap: () => onSelect(note.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    NoteMeta note,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem(value: 'rename', child: Text('重命名')),
        PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    ).then((value) {
      if (!context.mounted || value == null) return;
      if (value == 'delete') {
        _confirmDelete(context, note);
      } else if (value == 'rename') {
        _showRenameDialog(context, note);
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, NoteMeta note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除「${note.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete(note.id);
    }
  }

  Future<void> _showRenameDialog(BuildContext context, NoteMeta note) async {
    final renameController = TextEditingController(text: note.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名笔记'),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '新标题',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, renameController.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    renameController.dispose();
    if (newTitle != null &&
        newTitle.trim().isNotEmpty &&
        newTitle != note.title) {
      await onRename(note.id, newTitle);
    }
  }
}
