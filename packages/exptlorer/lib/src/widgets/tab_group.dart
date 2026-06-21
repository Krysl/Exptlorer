import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/drives.dart';
import '../model/id.dart';
import '../model/tab.dart';
import '../model/tab_group.dart';
import '../utils/log.dart';
import 'miller_columns.dart';

class TabGroupWidget extends ConsumerWidget {
  const TabGroupWidget({super.key, required this.tabGroupId, required this.drives, this.tabsEndIcon});
  final IdWrapper<ExTabGroup> tabGroupId;
  final Drives drives;

  final Widget? tabsEndIcon;

  static const double borderWidth = 2;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);

    WidgetStateColor bgColor({required bool isSel}) => WidgetStateColor.resolveWith(
      (states) {
        final bg = theme.acrylicBackgroundColor;
        final a = isSel ? 0.1 : 0;
        if (states.contains(
          WidgetState.hovered,
        )) {
          return bg.lerpWith(Colors.white, .2 + a);
        }
        return bg.lerpWith(Colors.white, .05 + a);
      },
    );

    final tabsGroupCtl = ref.watch(exTabGroupControllerProvider(tabGroupId).notifier);
    final tabsGroup = ref.watch(exTabGroupControllerProvider(tabGroupId));

    return Focus(
      onFocusChange: (hasFocus) {
        log.debugEx('TabGrop onFocusChange', title: 'TabGroup', tags: ['tabGroup', 'focus', 'change']);
        tabsGroupCtl.setActive(isActive: hasFocus);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: tabsGroup.isActive ? theme.accentColor : theme.acrylicBackgroundColor,
            width: borderWidth,
          ),
        ),
        child: Padding(
          padding: const .all(borderWidth),
          child: TabView(
            currentIndex: tabsGroup.activeTabIndex,
            onChanged: tabsGroupCtl.activeTab,
            closeButtonVisibility: .onHover,
            footer: tabsEndIcon,
            tabs: tabsGroup.tabs.mapIndexed(
              (index, tab) {
                return Tab(
                  text: TabTitle(tab: tab, isActive: tabsGroup.activeTabIndex == index),
                  selectedBackgroundColor: bgColor(isSel: true),
                  backgroundColor: bgColor(isSel: false),
                  body: MillerColumns(
                    tab: tab.wrap(), //
                    drives: drives,
                  ),
                  onClosed: () {
                    tabsGroupCtl.removeTab(tab);
                  },
                );
              },
            ).toList(),
            onNewPressed: tabsGroupCtl.addNewTab,
          ),
        ),
      ),
    );
  }
}

class TabTitle extends ConsumerWidget {
  const TabTitle({super.key, required this.tab, required this.isActive});
  final ExTab tab;
  final bool isActive;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.watch(exTabControllerProvider(tab.wrap()));
    final title = ctl.uri?.toFilePath() ?? '计算机';
    return Text(title);
  }
}
