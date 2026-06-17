import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';

import '../setting/log/log_settings.dart';
import '../utils/log.dart';

/// Log settings page.
class LogSettingsPage extends ConsumerStatefulWidget {
  const LogSettingsPage({super.key});

  @override
  ConsumerState<LogSettingsPage> createState() => _LogSettingsPageState();
}

class _LogSettingsPageState extends ConsumerState<LogSettingsPage> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(logSettingsControllerProvider);
    _hostCtrl.text = s.grpcHost ?? '';
    _portCtrl.text = s.grpcPort.toString();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 50051;

    if (host.isEmpty) {
      unawaited(
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('请输入主机地址'),
            severity: InfoBarSeverity.warning,
            action: IconButton(
              icon: const Icon(WindowsIcons.clear),
              onPressed: close,
            ),
          ),
        ),
      );
      return;
    }

    await ref.read(logSettingsControllerProvider.notifier).connect(host, port);
  }

  Future<void> _disconnect() async {
    await ref.read(logSettingsControllerProvider.notifier).disconnect();
  }

  void _sendTestLog() {
    log
      ..debug('Test DEBUG log')
      ..info('Test INFO log')
      ..warning('Test WARNING log')
      ..error('Test ERROR log')
      ..info('If connected, these 4 test logs should appear in log_ui');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(logSettingsControllerProvider);
    final ctrl = ref.read(logSettingsControllerProvider.notifier);
    final status = settings.connectionStatus;

    return ScaffoldPage(
      header: const PageHeader(title: Text('日志设置')),
      content: ListView(
        children: [
          // —— Talker toggle ——
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Talker 日志框架',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ToggleSwitch(
                    checked: settings.enableTalker,
                    onChanged: (v) => ctrl.setEnabled(enable: v),
                    content: const Text('启用 Talker 日志'),
                  ),
                ],
              ),
            ),
          ),

          // —— gRPC connection ——
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'gRPC 服务器',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: '主机地址',
                    child: TextBox(
                      controller: _hostCtrl,
                      placeholder: '例如: 127.0.0.1',
                      suffix: IconButton(
                        icon: const Icon(WindowsIcons.clear),
                        onPressed: _hostCtrl.clear,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: '端口',
                    child: TextBox(
                      controller: _portCtrl,
                      placeholder: '例如: 50051',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: status == GrpcConnectionStatus.connected ? _disconnect : _connect,
                        child: Text(
                          status == GrpcConnectionStatus.connected ? '断开连接' : '连接',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(status),
                      const SizedBox(width: 8),
                      HyperlinkButton(
                        onPressed: status == GrpcConnectionStatus.connected ? _sendTestLog : null,
                        child: const Text('发送测试日志'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // —— Log level ——
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日志级别',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<LogLevel>(
                    groupValue: settings.logLevel,
                    onChanged: (level) => level != null ? ctrl.setLogLevel(level) : null,
                    child: Row(
                      children: [
                        for (final level in [
                          LogLevel.debug,
                          LogLevel.info,
                          LogLevel.warning,
                          LogLevel.error,
                        ])
                          RadioButton<LogLevel>(
                            value: level,
                            content: Text(level.name),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(GrpcConnectionStatus status) {
    final (color, text) = switch (status) {
      GrpcConnectionStatus.disconnected => (Colors.grey, '未连接'),
      GrpcConnectionStatus.connecting => (Colors.orange, '连接中…'),
      GrpcConnectionStatus.connected => (Colors.green, '已连接'),
      GrpcConnectionStatus.error => (Colors.red, '连接失败'),
    };
    return InfoBadge(
      color: color,
      source: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
