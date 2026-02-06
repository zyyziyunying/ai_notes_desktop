import 'package:flutter/material.dart';

import '../../models/note_models.dart';
import 'graph_layout.dart';
import 'graph_models.dart';
import 'graph_painter.dart';

class GraphPanel extends StatefulWidget {
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
  State<GraphPanel> createState() => _GraphPanelState();
}

class _GraphPanelState extends State<GraphPanel> {
  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  Map<String, GraphNode> _nodeMap = {};

  /// 当前正在拖拽的节点索引
  int? _draggingIndex;

  /// 缩放和平移
  final TransformationController _transformController =
      TransformationController();

  /// 节点半径
  static const double nodeRadius = 24;

  /// 布局是否已初始化
  bool _layoutDone = false;

  /// 记录上次布局使用的尺寸
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _buildGraph();
  }

  @override
  void didUpdateWidget(covariant GraphPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes || oldWidget.links != widget.links) {
      _layoutDone = false;
      _buildGraph();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _buildGraph() {
    final displayNotes = widget.notes.take(GraphPanel.maxNodes).toList();
    final nodeMap = <String, GraphNode>{};
    final nodes = <GraphNode>[];

    for (final note in displayNotes) {
      final node = GraphNode(id: note.id, title: note.title);
      nodeMap[note.id] = node;
      nodes.add(node);
    }

    // 只保留两端都存在的边
    final edges = <GraphEdge>[];
    for (final link in widget.links) {
      if (nodeMap.containsKey(link.fromId) &&
          nodeMap.containsKey(link.toId)) {
        edges.add(GraphEdge(from: link.fromId, to: link.toId));
      }
    }

    _nodes = nodes;
    _edges = edges;
    _nodeMap = nodeMap;
  }

  void _runLayout(Size size) {
    if (_nodes.isEmpty || _layoutDone) return;

    GraphLayout.runFruchtermanReingold(
      nodes: _nodes,
      edges: _edges,
      nodeMap: _nodeMap,
      size: size,
      nodeRadius: nodeRadius,
    );

    _layoutDone = true;
    _lastSize = size;
  }

  /// 查找点击/拖拽位置对应的节点索引
  int? _hitTest(Offset localPosition) {
    for (int i = _nodes.length - 1; i >= 0; i--) {
      final node = _nodes[i];
      final dx = localPosition.dx - node.x;
      final dy = localPosition.dy - node.y;
      if (dx * dx + dy * dy <= nodeRadius * nodeRadius) {
        return i;
      }
    }
    return null;
  }

  /// 将屏幕坐标转换为图谱坐标
  Offset _toGraphCoords(Offset screenPos) {
    final inv = Matrix4.inverted(_transformController.value);
    final s = inv.storage;
    final x = s[0] * screenPos.dx + s[4] * screenPos.dy + s[12];
    final y = s[1] * screenPos.dx + s[5] * screenPos.dy + s[13];
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return const Center(child: Text('暂无笔记'));
    }

    if (_edges.isEmpty) {
      return const Center(child: Text('暂无关联关系'));
    }

    return Column(
      children: [
        if (widget.notes.length > GraphPanel.maxNodes)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '图谱节点过多，仅显示前 ${GraphPanel.maxNodes} 条笔记',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (!_layoutDone || _lastSize != size) {
                _runLayout(size);
              }
              return GestureDetector(
                onTapUp: (details) {
                  final pos = _toGraphCoords(details.localPosition);
                  final idx = _hitTest(pos);
                  if (idx != null) {
                    widget.onSelectNote(_nodes[idx].id);
                  }
                },
                onPanStart: (details) {
                  final pos = _toGraphCoords(details.localPosition);
                  _draggingIndex = _hitTest(pos);
                },
                onPanUpdate: (details) {
                  if (_draggingIndex != null) {
                    final pos = _toGraphCoords(details.localPosition);
                    setState(() {
                      final node = _nodes[_draggingIndex!];
                      final padding = nodeRadius + 4;
                      node.x = pos.dx.clamp(padding, size.width - padding);
                      node.y = pos.dy.clamp(padding, size.height - padding);
                    });
                  } else {
                    // 没有拖拽节点时，平移画布
                    final matrix = _transformController.value.clone();
                    matrix.storage[12] += details.delta.dx;
                    matrix.storage[13] += details.delta.dy;
                    _transformController.value = matrix;
                  }
                },
                onPanEnd: (_) {
                  _draggingIndex = null;
                },
                child: CustomPaint(
                  size: size,
                  painter: GraphPainter(
                    nodes: _nodes,
                    edges: _edges,
                    nodeMap: _nodeMap,
                    nodeRadius: nodeRadius,
                    transform: _transformController,
                    primaryColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    onPrimaryColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    edgeColor:
                        Theme.of(context).colorScheme.outline.withAlpha(80),
                    textStyle: Theme.of(context).textTheme.labelSmall ??
                        const TextStyle(fontSize: 10),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
