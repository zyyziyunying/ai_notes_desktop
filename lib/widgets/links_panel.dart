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
    final frontmatterLinks = current.frontmatterLinks;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Frontmatter 关系 (${frontmatterLinks.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('编辑'),
            ),
          ],
        ),
        if (frontmatterLinks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('暂无 Frontmatter 关系'),
          ),
        ...frontmatterLinks.map((link) {
          final blockInfo = _formatBlockInfo(
            fromBlock: link.fromBlock,
            toBlock: link.toBlock,
          );
          return ListTile(
            dense: true,
            title: Text(link.to),
            subtitle: Text(
              blockInfo.isEmpty ? link.type : '${link.type} | $blockInfo',
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
          final blockInfo = _formatBlockInfo(toBlock: link.toBlock);
          return ListTile(
            dense: true,
            title: Text(target?.title ?? link.rawTarget),
            subtitle: Text(
              blockInfo.isEmpty
                  ? '${link.type} | ${link.source}'
                  : '${link.type} | ${link.source} | $blockInfo',
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
          final blockInfo = _formatBlockInfo(fromBlock: link.fromBlock);
          return ListTile(
            dense: true,
            title: Text(source?.title ?? link.rawTarget),
            subtitle: Text(
              blockInfo.isEmpty
                  ? '${link.type} | ${link.source}'
                  : '${link.type} | ${link.source} | $blockInfo',
            ),
            onTap: source == null ? null : () => onSelectNote(link.fromId),
          );
        }),
      ],
    );
  }

  String _formatBlockInfo({String? fromBlock, String? toBlock}) {
    final parts = <String>[];
    if (fromBlock != null && fromBlock.trim().isNotEmpty) {
      parts.add('from $fromBlock');
    }
    if (toBlock != null && toBlock.trim().isNotEmpty) {
      parts.add('to $toBlock');
    }
    return parts.join(' ');
  }
}
