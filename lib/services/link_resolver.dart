import '../models/note_models.dart';

class LinkResolver {
  static final RegExp _wikiLink = RegExp(r'\[\[([^\[\]]+)\]\]');

  static List<String> extractWikiTargets(String body) {
    return _wikiLink
        .allMatches(body)
        .map((match) => match.group(1) ?? '')
        .map((raw) => raw.split('|').first.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String? resolveTarget(
    String raw,
    Map<String, String> titleToId,
    Map<String, String> pathToId,
  ) {
    final trimmed = _stripAnchor(raw).trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('id:')) {
      return trimmed.substring(3);
    }
    final normalized = trimmed.toLowerCase();
    if (titleToId.containsKey(normalized)) {
      return titleToId[normalized];
    }
    if (pathToId.containsKey(normalized)) {
      return pathToId[normalized];
    }
    return null;
  }

  static String? extractAnchor(String raw) {
    final trimmed = raw.trim();
    final index = trimmed.indexOf('#');
    if (index == -1 || index == trimmed.length - 1) {
      return null;
    }
    var anchor = trimmed.substring(index + 1).trim();
    if (anchor.isEmpty) {
      return null;
    }
    if (!anchor.startsWith('^')) {
      anchor = '^$anchor';
    }
    return anchor;
  }

  static String _stripAnchor(String raw) {
    final index = raw.indexOf('#');
    if (index == -1) {
      return raw;
    }
    return raw.substring(0, index);
  }

  static List<FrontmatterLink> extractFrontmatterLinks(
    Map<String, dynamic> map,
  ) {
    final links = map['links'];
    if (links is List) {
      final result = <FrontmatterLink>[];
      for (final item in links) {
        if (item is Map) {
          final to = item['to'];
          if (to is String && to.trim().isNotEmpty) {
            final type = item['type'];
            final note = item['note'];
            result.add(FrontmatterLink(
              to: to.trim(),
              type: type is String && type.trim().isNotEmpty
                  ? type.trim()
                  : 'relates_to',
              note: note is String ? note.trim() : null,
            ));
          }
        }
      }
      return result;
    }
    return <FrontmatterLink>[];
  }
}
