import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;

import '../model/file_icon.dart';
import 'multi_select_list.dart';

class FileItem extends ConsumerStatefulWidget {
  const FileItem({
    super.key,
    required this.entity,
    this.isSelected = false,
    this.isHovered = false,
  });
  final FileSystemEntity entity;
  final bool isSelected;
  final bool isHovered;

  @override
  ConsumerState<FileItem> createState() => _FileItemState();
}

class _FileItemState extends ConsumerState<FileItem> {
  @override
  Widget build(BuildContext context) {
    final img = ref.watch(fileIconProvider(widget.entity.path));
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == .dark;
    return ColoredBox(
      color: (widget.isHovered || widget.isSelected)
          ? (isDark ? Colors.grey[130] : Colors.grey[30])
          : theme.acrylicBackgroundColor,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 32,
            child: img.when(
              data: (data) => RawImage(image: data),
              error: (error, st) => Tooltip(message: '$error, $st'),
              loading: ProgressRing.new,
            ),
          ),
          Expanded(
            child: Text(path.basename(widget.entity.path), overflow: .ellipsis),
          ),
        ],
      ),
    );
  }
}

class FileList extends StatefulWidget {
  const FileList({
    super.key,
    required this.dir,
    this.onTapWithoutModifierKeys,
    this.onTapEmpty,
    this.showRightGuide = false,
    this.selectedPath,
  });

  final Directory dir;
  final String? selectedPath;
  final void Function(FileSystemEntity? path)? onTapWithoutModifierKeys;
  final void Function()? onTapEmpty;
  final bool showRightGuide;

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  late final MultiSelectController controller;
  @override
  void initState() {
    super.initState();
    controller = .new();
  }

  @override
  Widget build(BuildContext context) {
    final fileList = widget.dir.listSync();

    final initSelectItemIndex = widget.selectedPath != null
        ? fileList.indexWhere((drive) => widget.selectedPath!.startsWith(drive.path))
        : null;
    return MultiSelectList(
      itemCount: fileList.length,
      itemBuilder: ({required index, required isSelected, required isHovered}) {
        final entity = fileList[index];
        return FileItem(
          entity: entity.absolute,
          isSelected: isSelected,
          isHovered: isHovered,
        );
      },
      path: (index) => fileList[index],
      isDir: (index) => fileList[index].isDir,
      initSelectItemIndex: initSelectItemIndex,
      showRightGuide: widget.showRightGuide,
      onTapWithoutModifierKeys: widget.onTapWithoutModifierKeys,
      onTapEmpty: widget.onTapEmpty,
    );
  }
}
