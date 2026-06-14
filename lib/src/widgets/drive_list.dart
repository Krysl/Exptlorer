import 'package:exptlorer/src/model/drives.dart';
import 'package:exptlorer/src/model/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DriveItem extends ConsumerWidget {
  const DriveItem({super.key, required this.drive});
  final Drive drive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate = drive.usedSpace / drive.totalSpace * 100;
    final img = ref.watch(fileIconProvider(drive.mountPoint));
    return Card(
      child: Tooltip(
        message: drive.toString(),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 32,
              child: img.when(
                data: (data) => RawImage(image: data),
                error: (error, st) => Tooltip(message: '$error, $st'),
                loading: () => ProgressRing(),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: .spaceBetween,
                crossAxisAlignment: .stretch,
                spacing: 10,
                children: [
                  Row(
                    children: [
                      Text(
                        '${drive.name} (${drive.mountPoint.split(r'\').first})',
                      ),
                      Spacer(), //
                      Text(
                        '${(drive.availableSpace / 1e9).toStringAsFixed(1)} / ${(drive.totalSpace / 1e9).toInt()} GB',
                      ),
                    ],
                  ),
                  ProgressBar(
                    activeColor: rate > 90 ? Colors.red : null, //
                    backgroundColor: Colors.grey[220],
                    value: rate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriveList extends StatefulWidget {
  const DriveList({super.key, required this.drives});

  final Drives drives;

  @override
  State<DriveList> createState() => _DriveListState();
}

class _DriveListState extends State<DriveList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 5,
      children: widget.drives.drives
          .map((drive) => DriveItem(drive: drive))
          .toList(),
    );
  }
}
