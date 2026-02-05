import 'package:flutter/material.dart';

import '../models/note_models.dart';

Future<void> showLinkEditorDialog({
  required BuildContext context,
  required NoteDocument current,
  required List<String> relationTypes,
  required Future<void> Function(List<FrontmatterLink>) onSave,
}) async {
  final workingLinks = current.frontmatterLinks
      .map((link) => FrontmatterLink(
            to: link.to,
            type: link.type,
            note: link.note,
          ))
      .toList();
  final controllers = workingLinks
      .map((link) => TextEditingController(text: link.to))
      .toList();
  final notes = workingLinks
      .map((link) => TextEditingController(text: link.note ?? ''))
      .toList();

  final typeSet = <String>{
    ...relationTypes,
    ...workingLinks.map((link) => link.type),
  };
  final types = typeSet.isEmpty ? <String>['relates_to'] : typeSet.toList();
  for (var i = 0; i < workingLinks.length; i++) {
    if (!types.contains(workingLinks[i].type)) {
      workingLinks[i] = FrontmatterLink(
        to: workingLinks[i].to,
        type: types.first,
        note: workingLinks[i].note,
      );
    }
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('编辑 Frontmatter 关系'),
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
                                    initialValue: types.contains(workingLinks[i].type)
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
                                      workingLinks[i] = FrontmatterLink(
                                        to: workingLinks[i].to,
                                        type: value,
                                        note: workingLinks[i].note,
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
                                    notes.removeAt(i).dispose();
                                    workingLinks.removeAt(i);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notes[i],
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
                            FrontmatterLink(to: '', type: defaultType),
                          );
                          controllers.add(TextEditingController());
                          notes.add(TextEditingController());
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
                  final updated = <FrontmatterLink>[];
                  for (var i = 0; i < workingLinks.length; i++) {
                    final target = controllers[i].text.trim();
                    if (target.isEmpty) {
                      continue;
                    }
                    final type = workingLinks[i].type;
                    final note = notes[i].text.trim();
                    updated.add(
                      FrontmatterLink(
                        to: target,
                        type: type,
                        note: note.isEmpty ? null : note,
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
  for (final controller in notes) {
    controller.dispose();
  }
}
