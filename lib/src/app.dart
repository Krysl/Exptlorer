import 'package:exptlorer/src/setting/theme/theme.dart';
import 'package:exptlorer/src/window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:hooks_riverpod/hooks_riverpod.dart';

const String appTitle = 'Exptlorer';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeData = ref.watch(appThemeProvider);
    final appTheme = ref.watch(appThemeProvider.notifier);

    return FluentApp(
      title: appTitle,
      themeMode: appThemeData.mode,
      debugShowCheckedModeBanner: false,
      color: appThemeData.color,
      darkTheme: appTheme.getTheme(true, context),
      theme: appTheme.getTheme(false, context),
      locale: appThemeData.locale,
      builder: (final context, final child) {
        return Directionality(
          textDirection: appThemeData.textDirection,
          child: NavigationPaneTheme(
            data: NavigationPaneThemeData(
              backgroundColor:
                  appThemeData.windowEffect !=
                      flutter_acrylic.WindowEffect.disabled
                  ? Colors.transparent
                  : null,
            ),
            child: child!,
          ),
        );
      },
      home: const Window(appTitle: appTitle),
    );
  }
}
