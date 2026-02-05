import 'package:flutter/material.dart';

class ResizableDivider extends StatelessWidget {
  final bool isLeft;
  final ValueChanged<double> onDrag;

  const ResizableDivider({
    super.key,
    required this.isLeft,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 6,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}
