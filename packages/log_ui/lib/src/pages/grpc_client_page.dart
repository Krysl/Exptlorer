import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// gRPC 客户端测试页面
///
/// 使用 [TalkerGrpcLogger] 拦截器模式，手动模拟 gRPC 请求/响应日志，
/// 所有日志实时显示在 [TalkerScreen] 中。
///
/// 真实 gRPC 调用需要 protobuf 生成的桩代码，此处展示日志效果。
class GrpcClientPage extends StatefulWidget {
  const GrpcClientPage({super.key, required this.talker});

  final Talker talker;

  @override
  State<GrpcClientPage> createState() => _GrpcClientPageState();
}

class _GrpcClientPageState extends State<GrpcClientPage> {
  final _hostCtrl = TextEditingController(text: '127.0.0.1');
  final _portCtrl = TextEditingController(text: '50051');
  final _serviceCtrl = TextEditingController(text: 'HelloService');
  final _methodCtrl = TextEditingController(text: 'sayHello');
  final _payloadCtrl = TextEditingController(
    text: '{"greeting": "Hello from log_ui!"}',
  );

  bool _useTls = false;
  String _statusText = '就绪';
  Color _statusColor = Colors.grey;
  int _requestCount = 0;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _serviceCtrl.dispose();
    _methodCtrl.dispose();
    _payloadCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String text, Color color) {
    setState(() {
      _statusText = text;
      _statusColor = color;
    });
  }

  String get _methodPath => '/${_serviceCtrl.text.trim()}/${_methodCtrl.text.trim()}';

  Future<void> waitMs(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  Future<void> _simulateUnary() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 443;
    final methodPath = _methodPath;
    final payload = _payloadCtrl.text;

    if (host.isEmpty || methodPath == '/') {
      _setStatus('请填写服务和方法名称', Colors.red);
      return;
    }

    _requestCount++;
    _setStatus('[$_requestCount] 发送请求到 $host:$port...', Colors.blue);

    final talker = widget.talker
      // 模拟请求日志 — 就像 TalkerGrpcLogger 做的那样
      ..logCustom(
        TalkerLog(
          '[$methodPath] 请求: $payload',
          title: 'gRPC 请求',
          key: TalkerKey.info,
          logLevel: LogLevel.info,
        ),
      );

    // 模拟网络延迟
    await waitMs(600);

    // 随机模拟成功或失败
    final rng = Random();
    if (rng.nextDouble() > 0.2) {
      // 成功
      final response = '{"reply": "Hello from server (#$_requestCount)", "status": "ok"}';
      talker
        ..logCustom(
          TalkerLog(
            '[$methodPath] 耗时: ${rng.nextInt(300) + 50}ms\n响应: $response',
            title: 'gRPC 响应',
            key: TalkerKey.info,
            logLevel: LogLevel.info,
          ),
        )
        ..info('✓ gRPC 调用完成 ($methodPath)');
      _setStatus('[$_requestCount] ✓ 请求成功', Colors.green);
    } else {
      // 失败
      final errorMsg = 'UNKNOWN: 模拟 gRPC 错误 (code: ${rng.nextInt(16) + 1})';
      talker
        ..logCustom(
          TalkerLog(
            '[$methodPath] 错误: $errorMsg',
            title: 'gRPC 错误',
            key: TalkerKey.error,
            logLevel: LogLevel.error,
          ),
        )
        ..error('gRPC 调用失败: $errorMsg');
      _setStatus('[$_requestCount] ✗ 请求失败', Colors.red);
    }
  }

  Future<void> _simulateServerStream() async {
    _requestCount++;
    _setStatus('[$_requestCount] 开始 Server-Stream...', Colors.blue);

    final methodPath = _methodPath;
    final talker = widget.talker..info('[$methodPath] Server-Streaming 请求开始');

    for (var i = 1; i <= 3; i++) {
      await waitMs(400);
      talker.logCustom(
        TalkerLog(
          '[$methodPath] 流消息 #$i: {"chunk": "$i", "data": "..."}',
          title: 'gRPC 流消息',
          key: TalkerKey.info,
          logLevel: LogLevel.info,
        ),
      );
    }

    await waitMs(200);
    talker.info('✓ [$methodPath] Server-Streaming 完成 (共 3 条消息)');
    _setStatus('[$_requestCount] ✓ 流式调用完成', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('gRPC 客户端模拟器', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '所有操作通过 TalkerGrpcLogger 记录，日志请在"日志"标签页查看',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('连接配置', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _hostCtrl,
                  decoration: const InputDecoration(
                    labelText: '主机',
                    hintText: '例如: 127.0.0.1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portCtrl,
                  decoration: const InputDecoration(
                    labelText: '端口',
                    hintText: '例如: 50051',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('启用 TLS'),
                  value: _useTls,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _useTls = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RPC 调用', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _serviceCtrl,
                  decoration: const InputDecoration(
                    labelText: '服务名称',
                    hintText: '例如: HelloService',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _methodCtrl,
                  decoration: const InputDecoration(
                    labelText: '方法名称',
                    hintText: '例如: sayHello',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _payloadCtrl,
                  decoration: const InputDecoration(
                    labelText: '请求载荷 (JSON)',
                    hintText: '{"key": "value"}',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _simulateUnary,
              icon: const Icon(Icons.send),
              label: const Text('模拟 Unary 请求'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _simulateServerStream,
              icon: const Icon(Icons.stream),
              label: const Text('模拟 Server-Stream'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _statusColor == Colors.grey ? Icons.circle_outlined : Icons.circle,
              size: 10,
              color: _statusColor,
            ),
            const SizedBox(width: 8),
            Text(_statusText, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('使用 TalkerGrpcLogger', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  '// 在真实项目中结合 protobuf 生成桩代码使用:\n'
                  'final channel = ClientChannel(\n'
                  '  host,\n'
                  '  port: port,\n'
                  '  options: ChannelOptions(\n'
                  '    credentials: useTls\n'
                  '      ? const ChannelCredentials.secure()\n'
                  '      : const ChannelCredentials.insecure(),\n'
                  '  ),\n'
                  ');\n\n'
                  'final client = YourServiceClient(\n'
                  '  channel,\n'
                  '  interceptors: [\n'
                  '    TalkerGrpcLogger(talker: talker),\n'
                  '  ],\n'
                  ');',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
