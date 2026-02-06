import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/note_models.dart';
import '../../../services/vault_controller.dart';
import '../../../widgets/editor_panel.dart';
import '../../../widgets/graph_panel.dart';
import '../../../widgets/links_panel.dart';
import '../../../widgets/notes_panel.dart';
import '../../../widgets/preview_panel.dart';
import '../home_screen_state.dart';
import 'resizable_divider.dart';

class HomeBody extends StatelessWidget {
  final VaultController controller;
  final HomeScreenStateManager stateManager;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController searchController;
  final NoteDocument? current;
  final String renderedMarkdown;
  final VoidCallback onChanged;
  final void Function(String?) onTapLink;
  final VoidCallback onEditLinks;

  const HomeBody({
    super.key,
    required this.controller,
    required this.stateManager,
    required this.titleController,
    required this.bodyController,
    required this.searchController,
    required this.current,
    required this.renderedMarkdown,
    required this.onChanged,
    required this.onTapLink,
    required this.onEditLinks,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Row(
        children: [
          if (stateManager.showNotesPanel.value) ...[
            _buildNotesPanel(),
            ResizableDivider(
              isLeft: true,
              onDrag: stateManager.adjustNotesPanelWidth,
            ),
          ],
          if (stateManager.showEditorPanel.value) _buildEditorPanel(),
          if (stateManager.showPreviewPanel.value) ...[
            ResizableDivider(
              isLeft: false,
              onDrag: stateManager.adjustPreviewPanelWidth,
            ),
            _buildPreviewPanel(),
          ],
        ],
      );
    });
  }

  Widget _buildNotesPanel() {
    final bool shouldExpand = !stateManager.showEditorPanel.value &&
        !stateManager.showPreviewPanel.value;
    final child = NotesPanel(
      searchController: searchController,
      notes: controller.notes,
      currentId: current?.meta.id,
      onSearch: controller.updateSearchQuery,
      onSelect: controller.selectNoteById,
    );
    if (shouldExpand) {
      return Expanded(child: child);
    }
    return SizedBox(
      width: stateManager.notesPanelWidth.value,
      child: child,
    );
  }

  Widget _buildEditorPanel() {
    return Expanded(
      child: current == null
          ? const Center(child: Text('请选择或创建笔记'))
          : EditorPanel(
              titleController: titleController,
              bodyController: bodyController,
              onChanged: onChanged,
            ),
    );
  }

  Widget _buildPreviewPanel() {
    final bool shouldExpand = !stateManager.showEditorPanel.value;
    final child = current == null
        ? const Center(child: Text('预览区'))
        : PreviewPanel(
            renderedMarkdown: renderedMarkdown,
            onTapLink: (text, href, title) => onTapLink(href),
            linksPanel: LinksPanel(
              current: current!,
              outgoing: controller.outgoingLinksFor(current!.meta.id),
              incoming: controller.incomingLinksFor(current!.meta.id),
              onEdit: onEditLinks,
              onSelectNote: controller.selectNoteById,
              noteById: controller.noteById,
            ),
            graphPanel: GraphPanel(
              notes: controller.allNotes,
              links: controller.links,
              onSelectNote: controller.selectNoteById,
            ),
          );
    if (shouldExpand) {
      return Expanded(child: child);
    }
    return SizedBox(
      width: stateManager.previewPanelWidth.value,
      child: child,
    );
  }
}
