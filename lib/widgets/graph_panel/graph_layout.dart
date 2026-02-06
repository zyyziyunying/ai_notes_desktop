import 'dart:math';

import 'package:flutter/material.dart';

import 'graph_models.dart';

/// Fruchterman-Reingold 力导向布局算法
class GraphLayout {
  GraphLayout._();

  static void runFruchtermanReingold({
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required Map<String, GraphNode> nodeMap,
    required Size size,
    required double nodeRadius,
  }) {
    if (nodes.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final area = w * h;
    final k = sqrt(area / max(nodes.length, 1));
    final rng = Random(42);
    final padding = nodeRadius + 4;

    // 随机初始化位置（在可用区域内）
    for (final node in nodes) {
      node.x = padding + rng.nextDouble() * (w - padding * 2);
      node.y = padding + rng.nextDouble() * (h - padding * 2);
    }

    const iterations = 300;
    double temperature = w / 4;

    for (int iter = 0; iter < iterations; iter++) {
      // 重置位移
      for (final node in nodes) {
        node.dx = 0;
        node.dy = 0;
      }

      // 斥力：所有节点对之间
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final ni = nodes[i];
          final nj = nodes[j];
          var deltaX = ni.x - nj.x;
          var deltaY = ni.y - nj.y;
          var dist = sqrt(deltaX * deltaX + deltaY * deltaY);
          if (dist < 0.01) {
            deltaX = (rng.nextDouble() - 0.5) * 0.1;
            deltaY = (rng.nextDouble() - 0.5) * 0.1;
            dist = sqrt(deltaX * deltaX + deltaY * deltaY);
          }
          final repulsion = (k * k) / dist;
          final fx = (deltaX / dist) * repulsion;
          final fy = (deltaY / dist) * repulsion;
          ni.dx += fx;
          ni.dy += fy;
          nj.dx -= fx;
          nj.dy -= fy;
        }
      }

      // 引力：沿边
      for (final edge in edges) {
        final ni = nodeMap[edge.from]!;
        final nj = nodeMap[edge.to]!;
        final deltaX = ni.x - nj.x;
        final deltaY = ni.y - nj.y;
        final dist = sqrt(deltaX * deltaX + deltaY * deltaY);
        if (dist < 0.01) continue;
        final attraction = (dist * dist) / k;
        final fx = (deltaX / dist) * attraction;
        final fy = (deltaY / dist) * attraction;
        ni.dx -= fx;
        ni.dy -= fy;
        nj.dx += fx;
        nj.dy += fy;
      }

      // 应用位移，限制在温度范围内，并约束在边界内
      for (final node in nodes) {
        final disp = sqrt(node.dx * node.dx + node.dy * node.dy);
        if (disp > 0) {
          node.x += (node.dx / disp) * min(disp, temperature);
          node.y += (node.dy / disp) * min(disp, temperature);
        }
        // 约束在可见区域内
        node.x = node.x.clamp(padding, w - padding);
        node.y = node.y.clamp(padding, h - padding);
      }

      // 冷却
      temperature *= 0.95;
    }
  }
}
