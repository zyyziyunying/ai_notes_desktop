import 'dart:io';

enum AITool {
  claude('Claude', 'claude --dangerously-skip-permissions'),
  codex('Codex', 'codex');

  final String label;
  final String command;
  const AITool(this.label, this.command);
}

class TerminalService {
  TerminalService._();

  /// 在系统终端中启动 AI 工具
  static Future<void> launchInTerminal(
    AITool tool,
    Directory workingDir,
  ) async {
    final path = workingDir.path;
    final command = tool.command;

    if (Platform.isWindows) {
      await Process.start(
        'cmd.exe',
        ['/c', 'start', 'cmd', '/k', 'cd /d "$path" && $command'],
        mode: ProcessStartMode.detached,
      );
    } else if (Platform.isMacOS) {
      await Process.start(
        'osascript',
        [
          '-e',
          'tell application "Terminal" to do script "cd \'$path\' && $command"',
          '-e',
          'tell application "Terminal" to activate',
        ],
        mode: ProcessStartMode.detached,
      );
    } else {
      // Linux: try common terminal emulators
      final terminals = ['x-terminal-emulator', 'gnome-terminal', 'xterm'];
      for (final term in terminals) {
        try {
          if (term == 'gnome-terminal') {
            await Process.start(
              term,
              ['--working-directory=$path', '--', 'bash', '-c', '$command; exec bash'],
              mode: ProcessStartMode.detached,
            );
          } else {
            await Process.start(
              term,
              ['-e', 'bash -c "cd \'$path\' && $command; exec bash"'],
              mode: ProcessStartMode.detached,
            );
          }
          return;
        } catch (_) {
          continue;
        }
      }
    }
  }
}
