import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/drives.dart';
import '../model/file_icon.dart';
import '../utils/num.dart';
import 'miller_columns.dart';
import 'multi_select_list.dart';

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
      backgroundColor: (widget.isHovered || widget.isSelected) ? (isDark ? Colors.grey[130] : Colors.grey[30]) : null,
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
                        Row(mainAxisAlignment: .spaceBetween, children: buildLable()),
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
        loading: ProgressRing.new,
      ),
    );
  }

  List<Widget> buildLable() {
    final driveName = widget.drive.mountPoint.split(r'\').first;
    final gb = '${widget.drive.availableSpace.inGB.fixed1} / ${widget.drive.totalSpace.inGB.toInt()} GB';
    return widget.size.whens(
      widget.width, //
      [Text(driveName)],
      [Text(driveName)],
      [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.drive.name,
                  overflow: .ellipsis,
                ),
              ),
              Text('($driveName)'),
            ],
          ),
        ),
        Text(gb),
      ],
    );
  }
}

class DriveList extends StatefulWidget {
  const DriveList({
    super.key,
    required this.drives,
    this.selectedPath,
    this.onTapWithoutModifierKeys,
    this.onTapEmpty,
    this.showRightGuide = false,
  });

  final Drives drives;
  final String? selectedPath;
  final void Function(FileSystemEntity? path)? onTapWithoutModifierKeys;
  final void Function()? onTapEmpty;
  final bool showRightGuide;

  @override
  State<DriveList> createState() => _DriveListState();
}

class _DriveListState extends State<DriveList> {
  late final MultiSelectController controller;
  @override
  void initState() {
    super.initState();
    controller = .new();
  }

  bool _inited = false;
  @override
  Widget build(BuildContext context) {
    final drives = widget.drives.drives;
    int? lastSelected;
    if (!_inited) {
      lastSelected = widget.selectedPath != null
          ? drives.indexWhere((drive) => widget.selectedPath!.startsWith(drive.mountPoint))
          : 0;
      _inited = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiSelectList(
          controller: controller,
          itemCount: drives.length,
          itemBuilder: ({required index, required isSelected, required isHovered}) {
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
          initSelectItemIndex: lastSelected,
          showRightGuide: widget.showRightGuide,
          onTapWithoutModifierKeys: widget.onTapWithoutModifierKeys,
          onTapEmpty: widget.onTapEmpty,
        );
      },
    );
  }
}
