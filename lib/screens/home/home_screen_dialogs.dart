import 'package:flutter/material.dart';

import '../../dialogs/link_editor_dialog.dart';
import '../../dialogs/types_dialog.dart';
import '../../models/note_models.dart';
import '../../services/vault_controller.dart';

/// 处理 HomeScreen 的对话框逻辑
mixin HomeScreenDialogMixin<T extends StatefulWidget> on State<T> {
  // 子类需要提供这些依赖
  VaultController get controller;

  /// 打开链接编辑器对话框
  Future<void> openLinkEditor(NoteDocument current) async {
    await showLinkEditorDialog(
      context: context,
      current: current,
      relationTypes: controller.relationTypes,
      onSave: controller.updateFrontmatterLinks,
    );
  }

  /// 打开关系类型管理对话框
  Future<void> openTypesDialog() async {
    await showTypesDialog(
      context: context,
      initialTypes: controller.relationTypes,
      onSave: controller.updateRelationTypes,
    );
  }
}
