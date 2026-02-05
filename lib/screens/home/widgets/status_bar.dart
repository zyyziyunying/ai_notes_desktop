import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  final String status;

  const StatusBar({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
