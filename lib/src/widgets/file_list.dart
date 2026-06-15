import 'dart:io';

import 'package:exptlorer/src/model/file_icon.dart';
import 'package:exptlorer/src/widgets/multi_select_list.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;

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
              loading: () => ProgressRing(),
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
    this.showRightGuide = false,
  });

  final Directory dir;
  final void Function(String? path)? onTapWithoutModifierKeys;
  final bool showRightGuide;

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  @override
  Widget build(BuildContext context) {
    final fileList = widget.dir.listSync();
    return MultiSelectList(
      itemCount: fileList.length,
      itemBuilder: (index, isSelected, isHovered) {
        var entity = fileList[index];
        return FileItem(
          entity: entity.absolute,
          isSelected: isSelected,
          isHovered: isHovered,
        );
      },
      path: (index) => fileList[index].path,
      isDir: (index) => fileList[index].isDir,
      showRightGuide: widget.showRightGuide,
      onTapWithoutModifierKeys: widget.onTapWithoutModifierKeys,
    );
  }
}
