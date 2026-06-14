import 'package:exptlorer/src/model/drives.dart';
import 'package:exptlorer/src/widgets/drive_list.dart';
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
    return a.when(
      loading: () => ProgressRing(),
      error: (err, st) => Text("$err"),
      data: (drives) {
        return DriveList(drives: drives);
      },
    );
  }
}
