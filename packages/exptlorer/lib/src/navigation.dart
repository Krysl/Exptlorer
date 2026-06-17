import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'setting/theme/theme.dart';
import 'view/home.dart';
import 'view/log_settings_page.dart';
import 'window.dart';

class Navigation extends ConsumerStatefulWidget {
  const Navigation({super.key, required this.appTitle});

  final String appTitle;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NavigationState();
}

class _NavigationState extends ConsumerState<Navigation> {
  final viewKey = GlobalKey<NavigationViewState>(debugLabel: 'Navigation View Key');
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();

    super.dispose();
  }

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appThemeData = ref.watch(appThemeProvider);
    final appTheme = ref.watch(appThemeProvider.notifier);
    final theme = FluentTheme.of(context);
    return NavigationView(
      key: viewKey,
      titleBar: TitleBar(
        icon: const FlutterLogo(),
        title: Text(widget.appTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
            child: Builder(
              builder: (context) {
                final allItems = NavigationView.dataOf(context).pane!.allItems
                    .where(
                      (i) => i is PaneItem && i is! PaneItemExpander && i.body != null && i.enabled,
                    )
                    .cast<PaneItem>();
                return AutoSuggestBox<PaneItem>(
                  onSelected: (item) {
                    NavigationView.dataOf(context).pane?.changeTo(item.value!);
                  },
                  items: [
                    for (final item in allItems)
                      AutoSuggestBoxItem<PaneItem>(
                        value: item,
                        label: (item.title! as Text).data!,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        endHeader: Tooltip(
          message: 'Toggle theme',
          child: ToggleButton(
            checked: theme.brightness == Brightness.dark,
            onChanged: (v) {
              appTheme.update((data) {
                return data.copyWith(mode: v ? .dark : .light);
              });
            },
            child: const Icon(WindowsIcons.lightbulb, size: 16),
          ),
        ),
        captionControls: const WindowButtons(),
        onDragStarted: !kIsWeb ? windowManager.startDragging : null,
        onDoubleTap: !kIsWeb
            ? () async {
                final isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  await windowManager.restore();
                } else {
                  await windowManager.maximize();
                }
              }
            : null,
      ),
      pane: NavigationPane(
        selected: _index,
        onChanged: (index) {
          debugPrint('Changed to $index');
          setState(() => _index = index);
        },
        header: SizedBox(
          height: kOneLineTileHeight,
          child: ShaderMask(
            shaderCallback: (rect) {
              final color = appThemeData.color.defaultBrushFor(
                theme.brightness,
              );
              return LinearGradient(colors: [color, color]).createShader(rect);
            },
            child: const FlutterLogo(
              style: FlutterLogoStyle.horizontal,
              size: 80,
              textColor: Colors.white,
              duration: Duration.zero,
            ),
          ),
        ),
        displayMode: appThemeData.displayMode,
        indicator: () {
          switch (appThemeData.indicator) {
            case NavigationIndicators.end:
              return const EndNavigationIndicator();
            case NavigationIndicators.sticky:
              return const StickyNavigationIndicator();
          }
        }(),

        items: [
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.home),
            title: const Text('Home'),
            body: const HomePage(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('日志设置'),
            body: const LogSettingsPage(),
          ),
        ],
      ),
      onOpenSearch: searchFocusNode.requestFocus,
    );
  }
}
