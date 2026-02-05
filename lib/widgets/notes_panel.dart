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
  });

  final TextEditingController searchController;
  final List<NoteMeta> notes;
  final String? currentId;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;

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
              return ListTile(
                selected: selected,
                title: Text(note.title),
                subtitle: Text(
                  note.tags.isEmpty ? '无标签' : note.tags.join(', '),
                ),
                onTap: () => onSelect(note.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
