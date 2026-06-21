import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/drives.dart';
import '../model/id.dart';
import '../model/tab.dart';
import '../utils/log.dart';
import 'drive_list.dart';
import 'file_list.dart';

part 'miller_columns.freezed.dart';
part 'miller_columns.g.dart';

class MillerColumnState {
  MillerColumnState({required this.path});
  MillerColumnState.drives() : this(path: null);

  /// if (path==null) { show(DriveList);}
  final FileSystemEntity? path;

  bool get isDriveList => path == null;

  @override
  String toString() => 'MillerColumnState($path)';
}

@freezed
abstract class MillerColumnListState extends DelegatingList<MillerColumnState> with _$MillerColumnListState {
  factory MillerColumnListState({
    required ExTab tab,
    required List<MillerColumnState> base,
    required FocusNode focusNode,
  }) = _MillerColumnListState;

  MillerColumnListState._(super.base) : _base = base;

  factory MillerColumnListState.init(ExTab tab) {
    final list = <MillerColumnState>[MillerColumnState.drives()];
    if (tab.uri != null) {
      final path = tab.uri!.toFilePath(windows: true);
      final a = r'\'.allMatches(path).map((m) => path.substring(0, m.start + 1)).toList();
      if (!path.endsWith(r'\')) {
        a.add(path);
      }
      list.addAll(
        a.map((dir) => MillerColumnState(path: Directory(dir))),
      );
    }
    final focusNode = FocusNode(debugLabel: "MillerColumns's FocusNode");
    return _MillerColumnListState(tab: tab, base: list, focusNode: focusNode);
  }

  @override
  final List<MillerColumnState> _base;

  @override
  List<MillerColumnState> get base => _base;

  String? get path => isNotEmpty ? last.path?.path : null;
  Uri? get uri {
    final p = path;
    return p != null ? .file(p, windows: true) : null;
  }
}

typedef MillerColumnLayout = ({double offset, double width});

@Riverpod(keepAlive: true)
class MillerColumnsController extends _$MillerColumnsController {
  @override
  MillerColumnListState build(IdWrapper<ExTab> tabId) {
    final t = ref.read(exTabControllerProvider(tabId).notifier);
    final tab = ref.read(exTabControllerProvider(tabId));
    listenSelf((prev, next) {
      unawaited(
        Future.microtask(() {
          log.debugEx('uri: ${next.uri}', title: 'Miller', tags: ['miller', 'state']);
          t.updateUri(next.uri);
        }),
      );
    });
    ref.onDispose(() {
      log.debugEx('uri: ${tab.uri}', title: 'Miller', tags: ['miller', 'dispose']);
      state.focusNode.dispose();
    });
    log.debugEx('uri: ${tab.uri}', title: 'Miller', tags: ['miller', 'build']);
    return MillerColumnListState.init(tab);
  }

  List<MillerColumnLayout> calcWidths(
    double maxWidth,
    MillerColumnsSize size,
    int len,
  ) {
    if (size.maxWidth * len < maxWidth) {
      final remain = maxWidth - size.maxWidth * len;
      return List.generate(len, (i) {
        var w = size.maxWidth;
        if (i == len - 1) {
          w += min(remain, size.lastWidth - size.maxWidth);
        }
        return (offset: size.maxWidth * i, width: w);
      });
    } else if (size.smallWidth * len < maxWidth) {
      final maxNum = (maxWidth - size.smallWidth * len) ~/ (size.maxWidth - size.smallWidth);
      final smallNum = len - maxNum;
      final remain = maxWidth - size.maxWidth * maxNum - size.smallWidth * smallNum;

      double currentOffset = 0;
      return List.generate(len, (i) {
        var w = i < smallNum ? size.smallWidth : size.maxWidth;
        if (i == len - 1) {
          w += remain;
        }
        final ofst = currentOffset;
        currentOffset += w;
        return (offset: ofst, width: w);
      });
    } else if (size.minWidth * len < maxWidth) {
      final smallNum = (maxWidth - size.minWidth * len) ~/ (size.smallWidth - size.minWidth);
      final minNum = len - smallNum;
      final minExtStartIndex = minNum > 1 ? 1 : 0;
      final minExtNum = minNum > 1 ? minNum - 1 : 1;
      final minExt = (maxWidth - size.minWidth * minNum - size.smallWidth * smallNum) / minExtNum;

      double currentOffset = 0;
      return List.generate(len, (i) {
        var w = i < minNum ? size.minWidth : size.smallWidth;
        if (i >= minExtStartIndex && i < minExtStartIndex + minExtNum) {
          w += minExt;
        }
        final ofst = currentOffset;
        currentOffset += w;
        return (offset: ofst, width: w);
      });
    }
    throw UnimplementedError('calcWidths');
  }

  Widget? buildEmpty(
    List<MillerColumnLayout> layouts,
    BoxConstraints constraints,
    // ignore: riverpod_lint/avoid_build_context_in_providers
    BuildContext context,
  ) {
    final last = layouts.lastOrNull;
    if (last != null) {
      final (offset: a, width: b) = last;
      final w = constraints.maxWidth - a - b;
      if (w < 0) {
        return null;
      }

      return Positioned(
        left: a + b,
        width: w,
        child: SizedBox(
          width: w,
          height: constraints.maxHeight,
          child: Focus(
            focusNode: state.focusNode,
            child: GestureDetector(
              onTap: () {
                state.focusNode.requestFocus();
                log.debugEx(
                  'miller empty onTap ${state.focusNode}',
                  title: 'Miller',
                  tags: ['miller', 'empty', 'onTap'],
                );
              },
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
    }
    return null;
  }

  List<Widget> buildChildren(
    // ignore: riverpod_lint/avoid_build_context_in_providers
    BuildContext context,
    BoxConstraints constraints,
    MillerColumnsSize size,
    Drives drives,
    FluentThemeData theme,
  ) {
    final layouts = calcWidths(constraints.maxWidth, size, state.length);
    final empty = buildEmpty(layouts, constraints, context);
    final children = state.mapIndexed((index, c) {
      final layout = layouts[index];
      final selectedPath = index + 1 < state.length ? state[index + 1].path?.path : null;
      final showRightGuide = index < state.length - 1;
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
                    selectedPath: selectedPath,
                    showRightGuide: showRightGuide,
                    onTapWithoutModifierKeys: (path) => openAside(context, index, path),
                    onTapEmpty: () {
                      state.focusNode.requestFocus();
                    },
                  )
                : FileList(
                    dir: c.path! as Directory,
                    selectedPath: selectedPath,
                    showRightGuide: showRightGuide,
                    onTapWithoutModifierKeys: (path) => openAside(context, index, path),
                  ),
          ),
        ),
      );
    }).toList();
    log.debugEx('children = $children', title: 'Miller', tags: ['miller', 'buildChildren']);
    return [...children, ?empty];
  }

  // ignore: riverpod_lint/avoid_build_context_in_providers
  void openAside(BuildContext context, int index, FileSystemEntity? path) {
    var newState = state;
    if (state.length > index) {
      newState = state.copyWith(base: state.sublist(0, index + 1));
      if (path != null && path is Directory) {
        final stat = path.statSync();
        if (stat.type != FileSystemEntityType.notFound) {
          newState.add(MillerColumnState(path: path));
        } else {
          showError(context, '拒绝访问', '');
        }
      }
      state = newState;
    }
    log.debugEx('onTap: $state', title: 'Miller', tags: ['miller', 'openAside']);
  }

  // ignore: riverpod_lint/avoid_build_context_in_providers
  void showError(BuildContext context, String title, String? msg) => displayInfoBar(
    context,
    builder: (context, close) => InfoBar(
      title: Text(title),
      content: msg != null ? Text(msg) : null,
      action: IconButton(
        icon: const WindowsIcon(WindowsIcons.clear),
        onPressed: close,
      ),
      severity: InfoBarSeverity.warning,
    ),
  );
}

@freezed
abstract class MillerColumnsSize with _$MillerColumnsSize {
  const factory MillerColumnsSize({
    @Default(20) double minWidth,
    @Default(120) double smallWidth,
    @Default(230) double maxWidth,
    @Default(400) double lastWidth,
  }) = _MillerColumnsSize;
}

extension MillerColumnsSizeHelper on MillerColumnsSize {
  T whens<T>(num size, {required T min, required T small, required T max}) {
    if (size <= minWidth) {
      return min;
    } else if (size <= smallWidth) {
      return small;
    } else {
      return max;
    }
  }

  (bool, bool, bool) size(num size) => (size <= minWidth, size <= maxWidth && size > minWidth, size > maxWidth);
}

/// [Miller columns](https://en.wikipedia.org/wiki/Miller_columns)
class MillerColumns extends ConsumerStatefulWidget {
  const MillerColumns({
    super.key,
    required this.tab,
    required this.drives,
    this.controller,
    this.size = const MillerColumnsSize(),
  });

  final MillerColumnsSize size;

  final IdWrapper<ExTab> tab;
  final Drives drives;
  final MillerColumnsController? controller;

  @override
  ConsumerState<MillerColumns> createState() => _MillerColumnsState();
}

class _MillerColumnsState extends ConsumerState<MillerColumns> {
  late final MillerColumnsController controller;
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else {
      final ctl = ref.read(millerColumnsControllerProvider(widget.tab).notifier);
      controller = ctl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(millerColumnsControllerProvider(widget.tab));
    log.debugEx('MillerColumns rebuild, ${widget.tab} ${s.path}', title: 'Miller', tags: ['miller', 'build']);
    final theme = FluentTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: controller.buildChildren(
          context,
          constraints,
          widget.size,
          widget.drives,
          theme,
        ),
      ),
    );
  }
}
