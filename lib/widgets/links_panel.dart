import 'package:flutter/material.dart';

import '../models/note_models.dart';

class LinksPanel extends StatelessWidget {
  const LinksPanel({
    super.key,
    required this.current,
    required this.outgoing,
    required this.incoming,
    required this.onEdit,
    required this.onSelectNote,
    required this.noteById,
  });

  final NoteDocument current;
  final List<NoteLink> outgoing;
  final List<NoteLink> incoming;
  final VoidCallback onEdit;
  final ValueChanged<String> onSelectNote;
  final NoteMeta? Function(String id) noteById;

  @override
  Widget build(BuildContext context) {
    final embeddedLinks = current.embeddedLinks;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '笔记关系 (${embeddedLinks.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('编辑'),
            ),
          ],
        ),
        if (embeddedLinks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('暂无笔记关系'),
          ),
        ...embeddedLinks.map((link) {
          final anchorInfo = _formatAnchorInfo(
            fromAnchor: link.fromAnchor,
            toAnchor: link.toAnchor,
          );
          return ListTile(
            dense: true,
            title: Text(link.to),
            subtitle: Text(
              anchorInfo.isEmpty ? link.type : '${link.type} | $anchorInfo',
            ),
          );
        }),
        const Divider(height: 24),
        Text('出链 (${outgoing.length})',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (outgoing.isEmpty) const Text('暂无出链'),
        ...outgoing.map((link) {
          final target = noteById(link.toId);
          final anchorInfo = _formatAnchorInfo(toAnchor: link.toAnchor);
          return ListTile(
            dense: true,
            title: Text(target?.title ?? link.rawTarget),
            subtitle: Text(
              anchorInfo.isEmpty
                  ? '${link.type} | ${link.source}'
                  : '${link.type} | ${link.source} | $anchorInfo',
            ),
            onTap: target == null ? null : () => onSelectNote(link.toId),
          );
        }),
        const Divider(height: 24),
        Text('入链 (${incoming.length})',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (incoming.isEmpty) const Text('暂无入链'),
        ...incoming.map((link) {
          final source = noteById(link.fromId);
          final anchorInfo = _formatAnchorInfo(fromAnchor: link.fromAnchor);
          return ListTile(
            dense: true,
            title: Text(source?.title ?? link.rawTarget),
            subtitle: Text(
              anchorInfo.isEmpty
                  ? '${link.type} | ${link.source}'
                  : '${link.type} | ${link.source} | $anchorInfo',
            ),
            onTap: source == null ? null : () => onSelectNote(link.fromId),
          );
        }),
      ],
    );
  }

  String _formatAnchorInfo({String? fromAnchor, String? toAnchor}) {
    final parts = <String>[];
    if (fromAnchor != null && fromAnchor.trim().isNotEmpty) {
      parts.add('§$fromAnchor');
    }
    if (toAnchor != null && toAnchor.trim().isNotEmpty) {
      parts.add('→ §$toAnchor');
    }
    return parts.join(' ');
  }
}
