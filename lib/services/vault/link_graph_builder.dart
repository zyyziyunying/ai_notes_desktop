import 'package:path/path.dart' as p;

import '../../models/note_models.dart';
import '../link_resolver.dart';

/// 链接图构建结果。
class LinkGraph {
  const LinkGraph({
    required this.links,
    required this.backlinks,
  });

  final List<NoteLink> links;
  final Map<String, List<NoteLink>> backlinks;
}

/// 从文档列表中构建完整的链接图（wikilink + frontmatter link + backlink）。
class LinkGraphBuilder {
  const LinkGraphBuilder();

  LinkGraph build(List<NoteDocument> docs) {
    final titleToId = <String, String>{};
    final pathToId = <String, String>{};

    for (final doc in docs) {
      titleToId[doc.meta.title.toLowerCase()] = doc.meta.id;
      pathToId[p.basenameWithoutExtension(doc.meta.path).toLowerCase()] =
          doc.meta.id;
    }

    final links = <NoteLink>[];

    for (final doc in docs) {
      _extractWikiLinks(doc, titleToId, pathToId, links);
      _extractFrontmatterLinks(doc, titleToId, pathToId, links);
    }

    final backlinks = <String, List<NoteLink>>{};
    for (final link in links) {
      backlinks.putIfAbsent(link.toId, () => []).add(link);
    }

    return LinkGraph(links: links, backlinks: backlinks);
  }

  void _extractWikiLinks(
    NoteDocument doc,
    Map<String, String> titleToId,
    Map<String, String> pathToId,
    List<NoteLink> out,
  ) {
    final targets = LinkResolver.extractWikiTargets(doc.body);
    for (final target in targets) {
      final toBlock = LinkResolver.extractAnchor(target);
      final toId = LinkResolver.resolveTarget(target, titleToId, pathToId);
      if (toId == null) continue;
      out.add(NoteLink(
        fromId: doc.meta.id,
        toId: toId,
        type: 'wikilink',
        source: 'body',
        rawTarget: target,
        toBlock: toBlock,
      ));
    }
  }

  void _extractFrontmatterLinks(
    NoteDocument doc,
    Map<String, String> titleToId,
    Map<String, String> pathToId,
    List<NoteLink> out,
  ) {
    for (final link in doc.frontmatterLinks) {
      final toId = LinkResolver.resolveTarget(link.to, titleToId, pathToId);
      if (toId == null) continue;
      final rawTarget =
          link.toBlock == null ? link.to : '${link.to}#${link.toBlock}';
      out.add(NoteLink(
        fromId: doc.meta.id,
        toId: toId,
        type: link.type,
        source: 'frontmatter',
        rawTarget: rawTarget,
        fromBlock: link.fromBlock,
        toBlock: link.toBlock,
      ));
    }
  }
}
