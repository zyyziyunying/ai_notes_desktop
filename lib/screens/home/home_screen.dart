import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../services/vault_controller.dart';
import 'home_screen_dialogs.dart';
import 'home_screen_logic.dart';
import 'home_screen_state.dart';
import 'widgets/widgets.dart';

export 'home_screen_state.dart';
export 'home_screen_logic.dart';
export 'home_screen_dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with HomeScreenLogicMixin, HomeScreenDialogMixin {
  @override
  final VaultController controller = VaultController();

  @override
  final HomeScreenStateManager stateManager = HomeScreenStateManager();

  @override
  final TextEditingController titleController = TextEditingController();

  @override
  final TextEditingController bodyController = TextEditingController();

  @override
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initLogic();
  }

  @override
  void dispose() {
    disposeLogic();
    stateManager.dispose();
    titleController.dispose();
    bodyController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      // 访问 signals 以触发 Watch 重建
      final current = controller.currentSignal.value;
      final vaultDir = controller.vaultDirSignal.value;
      final status = controller.statusSignal.value;
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: HomeAppBar(
            vaultDir: vaultDir,
            onSelectVault: selectVault,
            onOpenTypesDialog: openTypesDialog,
            onCreateNote: controller.createNote,
            onExportAI: controller.exportAI,
            showNotesPanel: stateManager.showNotesPanel.value,
            showEditorPanel: stateManager.showEditorPanel.value,
            showPreviewPanel: stateManager.showPreviewPanel.value,
            onToggleNotesPanel: (_) => stateManager.toggleNotesPanel(),
            onToggleEditorPanel: (_) => stateManager.toggleEditorPanel(),
            onTogglePreviewPanel: (_) => stateManager.togglePreviewPanel(),
          ),
          body: HomeBody(
            controller: controller,
            stateManager: stateManager,
            titleController: titleController,
            bodyController: bodyController,
            searchController: searchController,
            current: current,
            renderedMarkdown: renderMarkdown(bodyController.text),
            onChanged: scheduleSave,
            onTapLink: handleNoteLink,
            onEditLinks: () => openLinkEditor(current!),
          ),
          bottomNavigationBar: StatusBar(status: status),
        ),
      );
    });
  }
}
