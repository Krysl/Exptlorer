import 'package:exptlorer/src/model/drives.dart';
import 'package:exptlorer/src/model/tab.dart';
import 'package:exptlorer/src/widgets/miller_columns.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final a = ref.watch(drivesControllerProvider);
    var tab = ExTab.create();
    final controller = ref.watch(millerColumnsControllerProvider(tab).notifier);
    return a.when(
      loading: () => ProgressRing(),
      error: (err, st) => Text("$err"),
      data: (drives) {
        return MillerColumns(tab: tab, controller: controller, drives: drives);
      },
    );
  }
}
