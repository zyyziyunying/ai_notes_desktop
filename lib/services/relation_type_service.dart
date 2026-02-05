import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class RelationTypeService {
  static const List<String> defaultTypes = <String>[
    'relates_to',
    'parent',
    'child',
    'references',
  ];

  Future<List<String>> loadTypes(Directory vault) async {
    final file = File(p.join(vault.path, '.ai', 'relations.json'));
    if (!file.existsSync()) {
      return List<String>.from(defaultTypes);
    }
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw);
      if (data is List) {
        final types = data
            .whereType<String>()
            .map((type) => type.trim())
            .where((type) => type.isNotEmpty)
            .toSet()
            .toList();
        return types.isEmpty ? List<String>.from(defaultTypes) : types;
      }
    } catch (_) {}
    return List<String>.from(defaultTypes);
  }

  Future<void> saveTypes(Directory vault, List<String> types) async {
    final aiDir = Directory(p.join(vault.path, '.ai'));
    if (!aiDir.existsSync()) {
      aiDir.createSync(recursive: true);
    }
    final file = File(p.join(aiDir.path, 'relations.json'));
    final cleaned = types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(cleaned),
    );
  }
}
