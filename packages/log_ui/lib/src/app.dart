import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'pages/grpc_client_page.dart';
import 'pages/log_viewer_page.dart';

/// log_ui main application.
///
/// Two tabs:
/// 1. **gRPC client** — configure host/port, simulate requests, logged via [TalkerGrpcLogger]
/// 2. **Log viewer** — [TalkerScreen] displaying all received logs.
class LogUiApp extends StatefulWidget {
  const LogUiApp({super.key, required this.talker});

  final Talker talker;

  @override
  State<LogUiApp> createState() => _LogUiAppState();
}

class _LogUiAppState extends State<LogUiApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log UI',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
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
        body: IndexedStack(
          index: _currentIndex,
          children: [
            GrpcClientPage(talker: widget.talker),
            LogViewerPage(talker: widget.talker),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wifi_tethering),
              selectedIcon: Icon(Icons.wifi_tethering),
              label: 'gRPC Client',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Logs',
            ),
          ],
        ),
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
          '• Configure gRPC server address and send requests\n'
          '• All requests/responses/errors logged via TalkerGrpcLogger\n'
          '• View live logs in the log viewer tab\n'
          '• Supports filtering, searching, and sharing logs',
        ),
      ],
    );
  }
}
