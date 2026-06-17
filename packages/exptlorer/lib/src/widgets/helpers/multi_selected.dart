import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/num.dart';

mixin Selectable<T extends Widget> on StatefulWidget {
  abstract final bool isSelected;
  abstract final GestureTapDownCallback? onTapDown;

  // T selectableBuilder({bool isSelected});
}

mixin MultiSelectable<T extends Selectable> on StatefulWidget {
  abstract final void Function(String? path)? onTapWithoutModifierKeys;
}

mixin MultiSelect<I extends Selectable, T extends MultiSelectable<I>> on State<T> {
  List<bool> selected = [];
  int lastSelected = 0;

  void clearSelectedIfLengthChanged(int length) {
    if (selected.length != length) {
      selected = List.filled(length, false);
    }
  }

  void select({
    required int index,
    String? path,
    required bool isDir,
    required void Function(String? path)? onTapWithoutModifierKeys,
  }) {
    final instance = HardwareKeyboard.instance;
    if (instance.isControlPressed) {
      selected[index] = !selected[index];
      lastSelected = index;
    } else if (instance.isShiftPressed) {
      selected.fillRange(0, selected.length, false);
      final (start, end) = sort2(lastSelected, index);
      selected.fillRange(start, end + 1, true);
    } else {
      selected.fillRange(0, selected.length, false);
      selected[index] = true;
      lastSelected = index;
      onTapWithoutModifierKeys?.call(isDir ? path : null);
    }
  }

  bool isSelected(int index) => selected[index];
  Widget multiSelectBuilder({
    required int itemCount,
    required Widget Function({
      required int index,
      required bool isSelected,
      GestureTapDownCallback? onTapDown,
    })
    itemBuilder,
    required String Function(int index) path,
    required bool Function(int index) isDir,
  }) {
    clearSelectedIfLengthChanged(itemCount);
    return GestureDetector(
      onTap: () {
        widget.onTapWithoutModifierKeys?.call(null);
      },
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (ctx, index) {
          return itemBuilder(
            index: index, //
            isSelected: isSelected(index),
            onTapDown: (details) {
              setState(() {
                select(
                  index: index,
                  path: path(index),
                  isDir: isDir(index),
                  onTapWithoutModifierKeys: widget.onTapWithoutModifierKeys,
                );
              });
            },
          );
        },
      ),
    );
  }
}
