import 'package:flutter/material.dart';

import 'graph_models.dart';

/// 图谱绘制器
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
    required this.nodeRadius,
    required this.transform,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.edgeColor,
    required this.textStyle,
  }) : super(repaint: transform);

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, GraphNode> nodeMap;
  final double nodeRadius;
  final TransformationController transform;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color edgeColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final matrix = transform.value;
    canvas.transform(matrix.storage);

    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 绘制边
    for (final edge in edges) {
      final from = nodeMap[edge.from];
      final to = nodeMap[edge.to];
      if (from == null || to == null) continue;
      canvas.drawLine(
        Offset(from.x, from.y),
        Offset(to.x, to.y),
        edgePaint,
      );
    }

    // 绘制节点
    final nodePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      // 圆形背景
      canvas.drawCircle(Offset(node.x, node.y), nodeRadius, nodePaint);

      // 文字标签
      final tp = TextPainter(
        text: TextSpan(
          text: node.title.length > 6
              ? '${node.title.substring(0, 6)}…'
              : node.title,
          style: textStyle.copyWith(color: onPrimaryColor),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: nodeRadius * 2.5);

      tp.paint(
        canvas,
        Offset(node.x - tp.width / 2, node.y - tp.height / 2),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
