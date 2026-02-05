import 'package:signals/signals_flutter.dart';

/// 管理 HomeScreen 的所有 UI 状态
class HomeScreenStateManager {
  // 当前选中的笔记 ID
  final Signal<String?> currentId = signal(null);

  // 面板可见性状态
  final Signal<bool> showNotesPanel = signal(true);
  final Signal<bool> showEditorPanel = signal(true);
  final Signal<bool> showPreviewPanel = signal(true);

  // 面板宽度
  final Signal<double> notesPanelWidth = signal(260.0);
  final Signal<double> previewPanelWidth = signal(360.0);

  // 面板宽度约束
  static const double minPanelWidth = 200;
  static const double maxPanelWidth = 600;

  /// 切换笔记面板显示状态
  void toggleNotesPanel() {
    showNotesPanel.value = !showNotesPanel.value;
  }

  /// 切换编辑器面板显示状态
  void toggleEditorPanel() {
    showEditorPanel.value = !showEditorPanel.value;
  }

  /// 切换预览面板显示状态
  void togglePreviewPanel() {
    showPreviewPanel.value = !showPreviewPanel.value;
  }

  /// 调整笔记面板宽度
  void adjustNotesPanelWidth(double delta) {
    notesPanelWidth.value = (notesPanelWidth.value + delta)
        .clamp(minPanelWidth, maxPanelWidth);
  }

  /// 调整预览面板宽度
  void adjustPreviewPanelWidth(double delta) {
    previewPanelWidth.value = (previewPanelWidth.value - delta)
        .clamp(minPanelWidth, maxPanelWidth);
  }

  /// 重置所有面板状态
  void reset() {
    currentId.value = null;
    showNotesPanel.value = true;
    showEditorPanel.value = true;
    showPreviewPanel.value = true;
    notesPanelWidth.value = 260.0;
    previewPanelWidth.value = 360.0;
  }

  /// 清理资源
  void dispose() {
    // signals 会自动清理，但保留此方法以备将来需要
  }
}
