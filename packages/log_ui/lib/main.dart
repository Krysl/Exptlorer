import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ignore: riverpod_lint/missing_provider_scope
  runApp(
    MaterialApp(
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
      home: LogUiApp(
        talker:
            TalkerFlutter.init(
                settings: TalkerSettings(),
              )
              ..info('Log UI started')
              ..info('Talker version: 5.1.17'),
      ),
    ),
  );
}
