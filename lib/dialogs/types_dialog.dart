import 'package:flutter/material.dart';

Future<void> showTypesDialog({
  required BuildContext context,
  required List<String> initialTypes,
  required Future<void> Function(List<String>) onSave,
}) async {
  final types = initialTypes.toList();
  final controller = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('关系类型管理'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < types.length; i++)
                    ListTile(
                      dense: true,
                      title: Text(types[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          types.removeAt(i);
                          setState(() {});
                        },
                      ),
                    ),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: '新增类型',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isNotEmpty && !types.contains(trimmed)) {
                        types.add(trimmed);
                        controller.clear();
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        final trimmed = controller.text.trim();
                        if (trimmed.isEmpty || types.contains(trimmed)) {
                          return;
                        }
                        types.add(trimmed);
                        controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('添加'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  await onSave(types);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
}
