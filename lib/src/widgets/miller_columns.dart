import 'dart:io';

import 'package:collection/collection.dart';
import 'package:exptlorer/src/model/drives.dart';
import 'package:exptlorer/src/model/tab.dart';
import 'package:exptlorer/src/widgets/drive_list.dart';
import 'package:exptlorer/src/widgets/file_list.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'miller_columns.g.dart';
part 'miller_columns.freezed.dart';

class MillerColumnState {
  /// if (path==null) { show(DriveList);}
  final String? path;

  MillerColumnState({required this.path});
  MillerColumnState.drives() : this(path: null);

  bool get isDriveList => path == null;

  @override
  String toString() => 'MillerColumnState($path)';
}

@freezed
abstract class MillerColumnListState extends DelegatingList<MillerColumnState>
    with _$MillerColumnListState {
  factory MillerColumnListState({
    required ExTab tab,
    required List<MillerColumnState> base,
  }) = _MillerColumnListState;

  MillerColumnListState._(super.base) : _base = base;

  factory MillerColumnListState.init(ExTab tab) =>
      _MillerColumnListState(tab: tab, base: [MillerColumnState.drives()]);

  @override
  final List<MillerColumnState> _base;

  @override
  List<MillerColumnState> get base => _base;
}

typedef MillerColumnLayout = ({double offset, double width});

@riverpod
class MillerColumnsController extends _$MillerColumnsController {
  @override
  MillerColumnListState build(ExTab tab) {
    return MillerColumnListState.init(tab);
  }

  List<MillerColumnLayout> calcWidths(
    double maxWidth,
    MillerColumnsSize size,
    int len,
  ) {
    if (size.maxWidth * len < maxWidth) {
      return List.generate(len, (i) {
        return (offset: size.maxWidth * i, width: size.maxWidth);
      });
    } else if (size.smallWidth * len < maxWidth) {
      final maxNum =
          (maxWidth - size.smallWidth * len) /
          (size.maxWidth - size.smallWidth);
      final smallNum = len - maxNum;

      double currentOffset = 0.0;
      return List.generate(len, (i) {
        final w = i < smallNum ? size.smallWidth : size.maxWidth;
        final ofst = currentOffset;
        currentOffset += w;
        return (offset: ofst, width: w);
      });
    } else if (size.minWidth * len < maxWidth) {
      final smallNum =
          (maxWidth - size.minWidth * len) / (size.smallWidth - size.minWidth);
      final smallNum2 = len - smallNum;

      double currentOffset = 0.0;
      return List.generate(len, (i) {
        final w = i < smallNum2 ? size.smallWidth : size.maxWidth;
        final ofst = currentOffset;
        currentOffset += w;
        return (offset: ofst, width: w);
      });
    }
    throw UnimplementedError();
  }

  List<Widget> buildChildren(
    BoxConstraints constraints,
    MillerColumnsSize size,
    Drives drives,
    FluentThemeData theme,
  ) {
    final layouts = calcWidths(constraints.maxWidth, size, state.length);
    final children = state.mapIndexed((index, c) {
      final layout = layouts[index];
      return Positioned(
        left: layout.offset,
        width: layout.width,
        child: SizedBox(
          width: layout.width,
          height: constraints.maxHeight,
          child: ColoredBox(
            color: theme.acrylicBackgroundColor,
            child: (c.path == null)
                ? DriveList(
                    drives: drives,
                    showRightGuide: index < state.length - 1,
                    onTapWithoutModifierKeys: (path) => openAside(index, path),
                  )
                : FileList(
                    dir: Directory(c.path!),
                    showRightGuide: index < state.length - 1,
                    onTapWithoutModifierKeys: (path) => openAside(index, path),
                  ),
          ),
        ),
      );
    }).toList();
    print('buildChildren: children = $children');
    return children;
  }

  void openAside(int index, String? path) {
    var newState = state;
    if (state.length > index) {
      newState = state.copyWith(base: state.sublist(0, index + 1));
      if (path != null) {
        newState.add(MillerColumnState(path: path));
      }
      state = newState;
    }
    print('onTap: $state');
  }
}

@freezed
abstract class MillerColumnsSize with _$MillerColumnsSize {
  const factory MillerColumnsSize({
    @Default(20) double minWidth,
    @Default(120) double smallWidth,
    @Default(230) double maxWidth,
  }) = _MillerColumnsSize;
}

extension MillerColumnsSizeHelper on MillerColumnsSize {
  T whens<T>(num size, T min, T small, T max) {
    if (size <= minWidth) {
      return min;
    } else if (size <= smallWidth) {
      return small;
    }
    {
      return max;
    }
  }
}

/// [Miller columns](https://en.wikipedia.org/wiki/Miller_columns)
class MillerColumns extends ConsumerStatefulWidget {
  const MillerColumns({
    super.key,
    required this.tab,
    required this.drives,
    required this.controller,
    this.size = const MillerColumnsSize(),
  });

  final MillerColumnsSize size;

  final ExTab tab;
  final Drives drives;
  final MillerColumnsController controller;

  @override
  ConsumerState<MillerColumns> createState() => _MillerColumnsState();
}

class _MillerColumnsState extends ConsumerState<MillerColumns> {
  @override
  Widget build(BuildContext context) {
    ref.watch(millerColumnsControllerProvider(widget.tab));
    print('MillerColumns rebuild, ${widget.tab}');
    final theme = FluentTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.hardEdge,
        children: widget.controller.buildChildren(
          constraints,
          widget.size,
          widget.drives,
          theme,
        ),
      ),
    );
  }
}
