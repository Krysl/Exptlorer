import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'src/app.dart';
import 'src/rust/frb_generated.dart';
import 'src/utils/cli_args.dart';
import 'src/utils/log.dart';
import 'src/utils/platform.dart';

void main(List<String> args) async {
  final cliConfig = parseCliArgs(args);
  printToConsole('CLI config: $cliConfig');

  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await loadAccentColor();
  await windowInit();

  runApp(
    ProviderScope(
      overrides: [
        cliConfigProvider.overrideWithValue(cliConfig), //
      ],
      observers: [
        TalkerRiverpodObserver(talker: log), //
      ],
      child: const MyApp(),
    ),
  );
}
