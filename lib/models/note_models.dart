import 'package:collection/collection.dart';

class NoteMeta {
  NoteMeta({
    required this.id,
    required this.title,
    required this.path,
    required this.tags,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String path;
  final List<String> tags;
  final DateTime updatedAt;

  NoteMeta copyWith({
    String? id,
    String? title,
    String? path,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return NoteMeta(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NoteMeta &&
        other.id == id &&
        other.title == title &&
        other.path == path &&
        const ListEquality<String>().equals(other.tags, tags) &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, title, path, tags, updatedAt);
}

class NoteDocument {
  NoteDocument({
    required this.meta,
    required this.body,
    required this.frontmatter,
    required this.frontmatterLinks,
  });

  final NoteMeta meta;
  final String body;
  final Map<String, dynamic> frontmatter;
  final List<FrontmatterLink> frontmatterLinks;
}

class NoteLink {
  NoteLink({
    required this.fromId,
    required this.toId,
    required this.type,
    required this.source,
    required this.rawTarget,
  });

  final String fromId;
  final String toId;
  final String type;
  final String source;
  final String rawTarget;
}

class FrontmatterLink {
  FrontmatterLink({
    required this.to,
    required this.type,
    this.note,
  });

  final String to;
  final String type;
  final String? note;
}
