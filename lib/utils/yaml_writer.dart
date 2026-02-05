String yamlEncode(Map<String, dynamic> map, {int indent = 0}) {
  final buffer = StringBuffer();
  final keys = map.keys.toList();
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final value = map[key];
    buffer.write(' ' * indent);
    buffer.write('$key:');
    if (value == null) {
      buffer.writeln('');
      continue;
    }
    if (value is String || value is num || value is bool) {
      buffer.writeln(' ${_encodeScalar(value)}');
      continue;
    }
    if (value is List) {
      if (value.isEmpty) {
        buffer.writeln(' []');
        continue;
      }
      buffer.writeln('');
      for (final item in value) {
        buffer.write(' ' * (indent + 2));
        buffer.write('-');
        if (item is Map) {
          buffer.writeln('');
          buffer.write(yamlEncode(
            Map<String, dynamic>.from(item),
            indent: indent + 4,
          ));
        } else {
          buffer.writeln(' ${_encodeScalar(item)}');
        }
      }
      continue;
    }
    if (value is Map) {
      buffer.writeln('');
      buffer.write(yamlEncode(
        Map<String, dynamic>.from(value),
        indent: indent + 2,
      ));
      continue;
    }
    buffer.writeln(' ${_encodeScalar(value.toString())}');
  }
  return buffer.toString();
}

String _encodeScalar(Object value) {
  if (value is num || value is bool) {
    return value.toString();
  }
  final text = value.toString();
  final needsQuotes = text.contains(':') ||
      text.contains('#') ||
      text.contains('\n') ||
      text.contains('\r') ||
      text.contains('"') ||
      text.contains('[') ||
      text.contains(']') ||
      text.trim() != text ||
      text.isEmpty;
  if (!needsQuotes) {
    return text;
  }
  final escaped = text.replaceAll('"', '\\"');
  return '"$escaped"';
}
