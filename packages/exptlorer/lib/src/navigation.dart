import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'model/id.dart';
import 'model/window.dart';
import 'model/workspace.dart';
import 'model/workspace_list.dart';
import 'setting/theme/theme.dart';
import 'utils/log.dart';
import 'view/home.dart';
import 'view/log_settings_page.dart';
import 'widgets/hover_visible.dart';
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
  final newWorkspaceController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();

    super.dispose();
  }

  int _index = 0;

  List<NavigationPaneItem> _buildTabGroupPanes(ExWorkspace data) {
    final wins = data.windows.map((window) => ref.watch(exWindowControllerProvider(window))).toList();
    return wins.map(
      (win) {
        final window = ref.watch(exWindowControllerProvider(win.wrap()));
        return PaneItemExpander(
          icon: const WindowsIcon(FluentIcons.tab_two_column), //
          title: Text(window.name ?? window.id.toString()),
          infoBadge: InfoBadge(source: Text('${window.groups.length}标签页组')),
          body: HomePage(
            window: window.wrap(),
            workspaceId: data.wrap(),
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

  NavigationPaneItem _buildWorkspacePane(IdWrapper<ExWorkspace> id, ExWorkspaceListController wsCtl) {
    final w = ref.watch(exWorkspaceControllerProvider(id));
    return PaneItemExpander(
      title: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(w.name),
          HoverVisible(
            child: FilledButton(
              onPressed: () {
                wsCtl.removeWorkspace(id);
              },
              child: const Text('删除'),
            ),
          ),
        ],
      ),
      icon: const WindowsIcon(FluentIcons.folder_list),
      infoBadge: InfoBadge(
        source: Text('${w.windows.length}窗口'),
      ),
      items: _buildTabGroupPanes(w),
    );
  }

  final _loaddingItem = PaneItem(icon: const WindowsIcon(FluentIcons.refresh));
  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(exWorkspaceListControllerProvider);
    final wsCtl = ref.read(exWorkspaceListControllerProvider.notifier);
    final appThemeData = ref.watch(appThemeProvider);
    final appTheme = ref.watch(appThemeProvider.notifier);
    final theme = FluentTheme.of(context);

    final paneItems = ws.when<List<NavigationPaneItem>>(
      data: (data) => [
        ...data.workspaces.map((ws) => _buildWorkspacePane(ws, wsCtl)),
        PaneItem(
          title: TextBox(
            controller: newWorkspaceController,
            placeholder: '输入工作区名称',
            suffixMode: .editing,
            suffix: FilledButton(
              onPressed: () {
                wsCtl.addNewWorkspace(name: newWorkspaceController.text);
              },
              child: const Text('新建'),
            ),
            onSubmitted: (value) => wsCtl.addNewWorkspace(name: value),
            // icon: const WindowsIcon(WindowsIcons.add),
          ),
        ),
      ],
      error: (err, st) => [PaneItem(icon: const WindowsIcon(WindowsIcons.error))],
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
        toggleButtonPosition: .titleBar,
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
