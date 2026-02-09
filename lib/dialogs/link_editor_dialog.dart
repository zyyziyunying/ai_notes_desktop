import 'package:flutter/material.dart';

import '../models/note_models.dart';

Future<void> showLinkEditorDialog({
  required BuildContext context,
  required NoteDocument current,
  required List<String> relationTypes,
  required Future<void> Function(List<EmbeddedLink>) onSave,
}) async {
  final workingLinks = current.embeddedLinks
      .map((link) => EmbeddedLink(
            to: link.to,
            type: link.type,
            summary: link.summary,
            fromAnchor: link.fromAnchor,
            toAnchor: link.toAnchor,
          ))
      .toList();
  final controllers =
      workingLinks.map((link) => TextEditingController(text: link.to)).toList();
  final summaries = workingLinks
      .map((link) => TextEditingController(text: link.summary ?? ''))
      .toList();

  final typeSet = <String>{
    ...relationTypes,
    ...workingLinks.map((link) => link.type),
  };
  final types = typeSet.isEmpty ? <String>['relates_to'] : typeSet.toList();
  for (var i = 0; i < workingLinks.length; i++) {
    if (!types.contains(workingLinks[i].type)) {
      workingLinks[i] = EmbeddedLink(
        to: workingLinks[i].to,
        type: types.first,
        summary: workingLinks[i].summary,
        fromAnchor: workingLinks[i].fromAnchor,
        toAnchor: workingLinks[i].toAnchor,
      );
    }
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('编辑笔记关系'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < workingLinks.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controllers[i],
                                    decoration: const InputDecoration(
                                      labelText: '目标',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String>(
                                    initialValue:
                                        types.contains(workingLinks[i].type)
                                            ? workingLinks[i].type
                                            : types.first,
                                    items: types
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      workingLinks[i] = EmbeddedLink(
                                        to: workingLinks[i].to,
                                        type: value,
                                        summary: workingLinks[i].summary,
                                        fromAnchor: workingLinks[i].fromAnchor,
                                        toAnchor: workingLinks[i].toAnchor,
                                      );
                                      setState(() {});
                                    },
                                    decoration: const InputDecoration(
                                      labelText: '关系类型',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    controllers.removeAt(i).dispose();
                                    summaries.removeAt(i).dispose();
                                    workingLinks.removeAt(i);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: summaries[i],
                              decoration: const InputDecoration(
                                labelText: '备注（可选）',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          final defaultType =
                              types.isNotEmpty ? types.first : 'relates_to';
                          workingLinks.add(
                            EmbeddedLink(to: '', type: defaultType),
                          );
                          controllers.add(TextEditingController());
                          summaries.add(TextEditingController());
                          setState(() {});
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('添加关系'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '提示：如果想新增关系类型，可在主界面右上角"关系类型"中管理。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  final updated = <EmbeddedLink>[];
                  for (var i = 0; i < workingLinks.length; i++) {
                    final target = controllers[i].text.trim();
                    if (target.isEmpty) {
                      continue;
                    }
                    final type = workingLinks[i].type;
                    final summary = summaries[i].text.trim();
                    updated.add(
                      EmbeddedLink(
                        to: target,
                        type: type,
                        summary: summary.isEmpty ? null : summary,
                        fromAnchor: workingLinks[i].fromAnchor,
                        toAnchor: workingLinks[i].toAnchor,
                      ),
                    );
                  }
                  await onSave(updated);
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

  for (final controller in controllers) {
    controller.dispose();
  }
  for (final controller in summaries) {
    controller.dispose();
  }
}
