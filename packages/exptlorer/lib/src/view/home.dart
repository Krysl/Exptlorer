import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../actions/workspace.dart';
import '../model/drives.dart';
import '../model/id.dart';
import '../model/window.dart';
import '../model/workspace.dart';
import '../widgets/tab_window.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.window});

  final IdWrapper<ExWindow> window;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final drivesData = ref.watch(drivesControllerProvider);
    final window = ref.watch(exWindowControllerProvider(widget.window));
    final workspaceCtl = ref.read(exWorkspaceControllerProvider('Default').notifier);

    return drivesData.when(
      loading: ProgressRing.new,
      error: (err, st) => Text('$err'),
      data: (drives) {
        return Actions(
          actions: {
            SaveWorkspaceIntent: SaveWorkspaceAction(controller: workspaceCtl, name: 'Default'),
          },
          child: TabWindow(
            windowId: window.wrap(),
            drives: drives,
          ),
        );
      },
    );
  }
}
