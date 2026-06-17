import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/drives.dart';
import '../model/tab.dart';
import '../widgets/miller_columns.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final a = ref.watch(drivesControllerProvider);
    final tab = ExTab.create();
    final controller = ref.watch(millerColumnsControllerProvider(tab).notifier);
    return a.when(
      loading: ProgressRing.new,
      error: (err, st) => Text('$err'),
      data: (drives) {
        return MillerColumns(tab: tab, controller: controller, drives: drives);
      },
    );
  }
}
