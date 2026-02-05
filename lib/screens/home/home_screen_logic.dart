import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

import '../../models/note_models.dart';
import '../../services/vault_controller.dart';
import 'home_screen_state.dart';

/// 处理 HomeScreen 的业务逻辑
mixin HomeScreenLogicMixin<T extends StatefulWidget> on State<T> {
  // 子类需要提供这些依赖
  VaultController get controller;
  HomeScreenStateManager get stateManager;
  TextEditingController get titleController;
  TextEditingController get bodyController;
  TextEditingController get searchController;

  Timer? _saveTimer;
  EffectCleanup? _currentEffect;

  /// 初始化业务逻辑
  void initLogic() {
    // 使用 effect 监听 current signal 变化
    _currentEffect = effect(() {
      final current = controller.currentSignal.value;
      _onCurrentChanged(current);
    });
  }

  /// 清理业务逻辑资源
  void disposeLogic() {
    controller.disposeController();
    _currentEffect?.call();
    _saveTimer?.cancel();
  }

  /// 当前笔记变化时更新编辑器
  void _onCurrentChanged(NoteDocument? current) {
    if (current == null) {
      stateManager.currentId.value = null;
      titleController.text = '';
      bodyController.text = '';
      return;
    }
    if (stateManager.currentId.value != current.meta.id) {
      stateManager.currentId.value = current.meta.id;
      titleController.text = current.meta.title;
      bodyController.text = current.body;
    }
  }

  /// 选择笔记库目录
  Future<void> selectVault() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择 Markdown 笔记库目录',
    );
    if (path == null) {
      return;
    }
    await controller.openVault(Directory(path));
  }

  /// 调度自动保存
  void scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      final current = controller.current;
      if (current == null) {
        return;
      }
      controller.saveCurrent(
        body: bodyController.text,
        title: titleController.text,
      );
    });
  }

  /// 渲染 Markdown（处理 wikilink）
  String renderMarkdown(String body) {
    return body.replaceAllMapped(RegExp(r'\[\[([^\[\]]+)\]\]'), (match) {
      final raw = match.group(1) ?? '';
      final parts = raw.split('|');
      final target = parts.first.trim();
      final label = parts.length > 1 ? parts[1].trim() : target;
      final encoded = Uri.encodeComponent(target);
      return '[$label](note://$encoded)';
    });
  }

  /// 处理笔记链接点击
  void handleNoteLink(String? href) {
    if (href == null) {
      return;
    }
    if (href.startsWith('note://')) {
      final target = Uri.decodeComponent(href.substring(7));
      controller.selectNoteByTarget(target);
    }
  }
}
