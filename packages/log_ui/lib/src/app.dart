import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'grpc_server.dart';
import 'pages/log_viewer_page.dart';

/// log_ui main application.
///
/// Displays received logs via [TalkerScreen].
class LogUiApp extends StatefulWidget {
  const LogUiApp({super.key, required this.talker});

  final Talker talker;

  @override
  State<LogUiApp> createState() => _LogUiAppState();
}

class _LogUiAppState extends State<LogUiApp> with WindowListener {
  late final LogGrpcServerManager serverManager;
  @override
  void initState() {
    super.initState();
    unawaited(windowManager.setPreventClose(true));
    windowManager.addListener(this);

    // Start the gRPC log server on port 50051.
    serverManager = LogGrpcServerManager(talker: widget.talker);
    unawaited(
      serverManager.start().then((_) {
        widget.talker.info(
          'Send logs via: exptlorer --talker --talker-grpc-host=127.0.0.1 --talker-grpc-port=50051',
        );
      }),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && mounted) {
      final ret = await showDialog<bool>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close this window?'),
            actions: [
              FilledButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              FilledButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          );
        },
      );
      if (ret == true) {
        await serverManager.stop();
        await windowManager.destroy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log UI — gRPC Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: Builder(
        builder: (ctx) => LogViewerPage(talker: widget.talker),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Log UI',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Built with talker_flutter + talker_grpc_logger',
      children: [
        const Text(
          'A gRPC log debugging tool.\n\n'
          '• View live logs forwarded from exptlorer\n'
          '• Supports filtering, searching, and sharing logs',
        ),
      ],
    );
  }
}
