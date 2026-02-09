import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

import '../../models/note_models.dart';
import '../../services/app_settings.dart';
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
    // 自动加载上次打开的笔记库
    _loadLastVault();
  }

  /// 加载上次打开的笔记库
  Future<void> _loadLastVault() async {
    final lastPath = await AppSettings.instance.getLastVaultPath();
    if (lastPath != null && Directory(lastPath).existsSync()) {
      await controller.openVault(Directory(lastPath));
    }
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
    await AppSettings.instance.setLastVaultPath(path);
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

  /// 渲染 Markdown（处理 wikilink、block 标注、隐藏 links 注释块）
  String renderMarkdown(String body) {
    // 1. 移除多行 <!-- links ... --> 和 <!-- relations ... --> 注释块
    var result = body.replaceAll(
      RegExp(r'<!--\s*(?:links|relations)\b.*?-->', dotAll: true),
      '',
    );

    // 2. 将 <!-- §xxx --> 转换为自定义标记
    result = result.replaceAllMapped(
      RegExp(r'<!--\s*§(\S+)\s*-->'),
      (match) => '<block-tag>${match.group(1)}</block-tag>',
    );

    // 3. 处理 wikilink
    result = result.replaceAllMapped(RegExp(r'\[\[([^\[\]]+)\]\]'), (match) {
      final raw = match.group(1) ?? '';
      final parts = raw.split('|');
      final target = parts.first.trim();
      final label = parts.length > 1 ? parts[1].trim() : target;
      final encoded = Uri.encodeComponent(target);
      return '[$label](note://$encoded)';
    });

    return result;
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
