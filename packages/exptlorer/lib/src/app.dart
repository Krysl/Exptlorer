import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'actions/actions.dart';
import 'setting/log/log_settings.dart';
import 'setting/theme/theme.dart';
import 'window.dart';

const String appTitle = 'Expᵗlorer';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeData = ref.watch(appThemeProvider);
    final appTheme = ref.watch(appThemeProvider.notifier);
    ref.read(logSettingsControllerProvider);
    return FluentApp(
      title: appTitle,
      themeMode: appThemeData.mode,
      debugShowCheckedModeBanner: false,
      color: appThemeData.color,
      darkTheme: appTheme.getTheme(isDark: true, context),
      theme: appTheme.getTheme(isDark: false, context),
      locale: appThemeData.locale,
      builder: (context, child) {
        final widget = Directionality(
          textDirection: appThemeData.textDirection,
          child: NavigationPaneTheme(
            data: NavigationPaneThemeData(
              backgroundColor: appThemeData.windowEffect != flutter_acrylic.WindowEffect.disabled
                  ? Colors.transparent
                  : null,
            ),
            child: child!,
          ),
        );
        return Shortcuts(
          /// [Actions](view/home.dart#L33)
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(.enter): const OpenIntent(),
            LogicalKeySet(.control, .keyS): const SaveWorkspaceIntent(),
            LogicalKeySet(.control, .keyB): const PaneDisplayModeIntent(),
          },
          child: Actions(
            actions: {
              PaneDisplayModeIntent: PaneDisplayModeAction(
                controller: appTheme,
                displayMode: switch (appTheme.getDisplayMode()) {
                  .top => throw UnimplementedError(),
                  .expanded => .compact,
                  .compact => .expanded,
                  .minimal => throw UnimplementedError(),
                  .auto => throw UnimplementedError(),
                },
              ),
            },
            child: widget,
          ),
        );
      },
      home: const Window(appTitle: appTitle),
    );
  }
}
