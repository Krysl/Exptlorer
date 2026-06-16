import 'dart:io';

import 'package:exptlorer/src/model/drives.dart';
import 'package:exptlorer/src/model/file_icon.dart';
import 'package:exptlorer/src/utils/num.dart';
import 'package:exptlorer/src/widgets/multi_select_list.dart';
import 'package:exptlorer/src/widgets/miller_columns.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DriveItem extends ConsumerStatefulWidget {
  const DriveItem({
    super.key,
    required this.drive,
    this.isSelected = false,
    this.isHovered = false,
    this.width = 230,
    this.size = const MillerColumnsSize(),
  });
  final Drive drive;
  final double width;
  final MillerColumnsSize size;
  final bool isSelected;
  final bool isHovered;

  @override
  ConsumerState<DriveItem> createState() => _DriveItemState();
}

class _DriveItemState extends ConsumerState<DriveItem> {
  @override
  Widget build(BuildContext context) {
    final img = ref.watch(fileIconProvider(widget.drive.mountPoint));
    final isDark = FluentTheme.of(context).brightness == .dark;
    return Card(
      backgroundColor: (widget.isHovered || widget.isSelected)
          ? (isDark ? Colors.grey[130] : Colors.grey[30])
          : null,
      child: Tooltip(
        message: widget.drive.toString(),
        child: widget.width > widget.size.smallWidth
            ? Row(
                children: [
                  buildIcon(img),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: .spaceBetween,
                      crossAxisAlignment: .stretch,
                      spacing: 10,
                      children: [
                        Row(children: buildLable()),
                        buildProcessBar(),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Row(children: [buildIcon(img), ...buildLable()]),
                  buildProcessBar(),
                ],
              ),
      ),
    );
  }

  ProgressBar buildProcessBar() {
    final rate = widget.drive.usedSpace / widget.drive.totalSpace * 100;
    return ProgressBar(
      activeColor: rate > 90 ? Colors.red : null,
      backgroundColor: Colors.grey[220],
      value: rate,
    );
  }

  SizedBox buildIcon(AsyncValue<UiImage?> img) {
    return SizedBox.square(
      dimension: (widget.width <= widget.size.smallWidth) ? 16 : 32,
      child: img.when(
        data: (data) => RawImage(image: data),
        error: (error, st) => Tooltip(message: '$error, $st'),
        loading: () => ProgressRing(),
      ),
    );
  }

  List<Widget> buildLable() {
    final driveName = widget.drive.mountPoint.split(r'\').first;
    final gb =
        '${widget.drive.availableSpace.inGB.fixed1} / ${widget.drive.totalSpace.inGB.toInt()} GB';
    return widget.size.whens(
      widget.width, //
      [Text(driveName)],
      [Text(driveName)],
      [Text('${widget.drive.name} ($driveName)'), Spacer(), Text(gb)],
    );
  }
}

class DriveList extends StatefulWidget {
  const DriveList({
    super.key,
    required this.drives,
    this.onTapWithoutModifierKeys,
    this.showRightGuide = false,
  });

  final Drives drives;
  final void Function(FileSystemEntity? path)? onTapWithoutModifierKeys;
  final bool showRightGuide;

  @override
  State<DriveList> createState() => _DriveListState();
}

class _DriveListState extends State<DriveList> {
  @override
  Widget build(BuildContext context) {
    var drives = widget.drives.drives;
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiSelectList(
          itemCount: drives.length,
          itemBuilder: (index, isSelected, isHovered) {
            final drive = drives[index];
            return DriveItem(
              drive: drive,
              width: constraints.maxWidth,
              isSelected: isSelected,
              isHovered: isHovered,
            );
          },
          path: (index) => Directory(drives[index].mountPoint),
          isDir: (_) => true,
          showRightGuide: widget.showRightGuide,
          onTapWithoutModifierKeys: widget.onTapWithoutModifierKeys,
        );
      },
    );
  }
}
