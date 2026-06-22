import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'model/window.dart';
import 'model/workspace.dart';
import 'model/workspace_list.dart';
import 'setting/theme/theme.dart';
import 'utils/log.dart';
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

  List<NavigationPaneItem> _buildTabGroupPanes(ExWorkspace data) {
    final wins = data.windows.map((window) => ref.watch(exWindowControllerProvider(window.wrap()))).toList();
    return wins.map(
      (win) {
        final window = ref.watch(exWindowControllerProvider(win.wrap()));
        return PaneItemExpander(
          icon: const WindowsIcon(FluentIcons.tab_two_column), //
          title: Text(window.name ?? window.id.toString()),
          infoBadge: InfoBadge(source: Text('${window.groups.length}标签页组')),
          body: HomePage(
            window: window.wrap(),
          ),
          items: window.groups
              .map(
                (group) => PaneItem(
                  icon: const WindowsIcon(FluentIcons.column),
                  title: Text(group.id.toString()),
                ),
              )
              .toList(),
        );
      },
    ).toList();
  }

  NavigationPaneItem _buildWorkspacePane(String name) {
    final w = ref.watch(exWorkspaceControllerProvider(name));
    return PaneItemExpander(
      title: Text(name),
      icon: const WindowsIcon(FluentIcons.folder_list),
      infoBadge: InfoBadge(
        source: w.when(
          data: (data) {
            return Text('${data.windows.length}窗口');
          },
          error: (error, stackTrace) {
            return null;
          },
          loading: () {
            return null;
          },
        ),
      ),
      items: w.when(
        data: _buildTabGroupPanes,
        error: (error, stackTrace) {
          return [];
        },
        loading: () {
          return [_loaddingItem];
        },
      ),
    );
  }

  final _loaddingItem = PaneItem(icon: const WindowsIcon(FluentIcons.refresh));
  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(exWorkspaceListControllerProvider);
    final appThemeData = ref.watch(appThemeProvider);
    final appTheme = ref.watch(appThemeProvider.notifier);
    final theme = FluentTheme.of(context);

    final paneItems = ws.when<List<NavigationPaneItem>>(
      data: (data) {
        return data.workspaces.map(_buildWorkspacePane).toList();
      },
      error: (err, st) => [],
      loading: () => [_loaddingItem],
    );

    return NavigationView(
      key: viewKey,
      onDisplayModeChanged: (mode) {},
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
          log.debug('Changed to $index');
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

        items: paneItems,
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
