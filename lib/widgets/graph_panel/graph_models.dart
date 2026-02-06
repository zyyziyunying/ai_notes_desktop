/// 图谱节点数据
class GraphNode {
  GraphNode({required this.id, required this.title});

  final String id;
  final String title;
  double x = 0;
  double y = 0;

  /// 力导向布局用的位移累加
  double dx = 0;
  double dy = 0;
}

/// 图谱边数据
class GraphEdge {
  GraphEdge({required this.from, required this.to});

  final String from;
  final String to;
}
