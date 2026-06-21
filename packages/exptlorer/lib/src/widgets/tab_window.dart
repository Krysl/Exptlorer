import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/drives.dart';
import '../model/id.dart';
import '../model/window.dart';
import '../utils/log.dart';
import 'tab_group.dart';

class TabWindow extends ConsumerStatefulWidget {
  const TabWindow({super.key, required this.drives, required this.windowId, this.layoutDirection = .horizontal});

  final IdWrapper<ExWindow> windowId;
  final Axis layoutDirection;
  final Drives drives;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TabWindowState();
}

class _TabWindowState extends ConsumerState<TabWindow> {
  @override
  Widget build(BuildContext context) {
    final window = ref.watch(exWindowControllerProvider(widget.windowId));
    final windowCtl = ref.read(exWindowControllerProvider(widget.windowId).notifier);
    final children = window.groups
        .map(
          (group) => Expanded(
            child: TabGroupWidget(
              tabGroupId: group.wrap(),
              drives: widget.drives,
              tabsEndIcon: IconButton(
                icon: const RotatedBox(
                  quarterTurns: 1, //
                  child: Icon(FluentIcons.cell_split_vertical),
                ),
                onPressed: () {
                  log.debugEx('add new tab', title: 'TabWindow', tags: ['TabWindow', 'tab', 'add']);
                  windowCtl.addNewTabGroup();
                },
              ),
            ),
          ),
        )
        .toList();
    return switch (widget.layoutDirection) {
      Axis.horizontal => Row(
        children: children,
      ),
      Axis.vertical => Column(
        children: children,
      ),
    };
  }
}
