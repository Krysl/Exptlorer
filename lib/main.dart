import 'package:exptlorer/src/app.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'src/utils/platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  loadAccentColor();
  windowInit();

  runApp(ProviderScope(child: const MyApp()));
}
