import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../models/note_models.dart';

class GraphPanel extends StatelessWidget {
  const GraphPanel({
    super.key,
    required this.notes,
    required this.links,
    required this.onSelectNote,
  });

  final List<NoteMeta> notes;
  final List<NoteLink> links;
  final ValueChanged<String> onSelectNote;

  static const int maxNodes = 200;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Center(child: Text('暂无笔记'));
    }

    final displayNotes = notes.take(maxNodes).toList();
    final graph = Graph()..isTree = false;
    final nodeMap = <String, Node>{};

    for (final note in displayNotes) {
      final node = Node.Id(note.id);
      nodeMap[note.id] = node;
      graph.addNode(node);
    }

    for (final link in links) {
      final from = nodeMap[link.fromId];
      final to = nodeMap[link.toId];
      if (from == null || to == null) {
        continue;
      }
      graph.addEdge(from, to);
    }

    // GraphView crashes with RangeError when there are no edges
    if (graph.edges.isEmpty) {
      return const Center(child: Text('暂无关联关系'));
    }

    final algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(iterations: 1000),
    );

    return Column(
      children: [
        if (notes.length > maxNodes)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '图谱节点过多，仅显示前 $maxNodes 条笔记',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.1,
            maxScale: 4,
            child: GraphView(
              graph: graph,
              algorithm: algorithm,
              builder: (Node node) {
                final key = node.key;
                final id = key is ValueKey ? key.value as String : null;
                final note = id == null
                    ? null
                    : notes.firstWhere(
                        (item) => item.id == id,
                        orElse: () => notes.first,
                      );
                return GestureDetector(
                  onTap: note == null ? null : () => onSelectNote(note.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note?.title ?? '未知',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
