import 'package:exptlorer/src/utils/num.dart';
import 'package:flutter/services.dart';

mixin MultiSelect {
  List<bool> selected = [];
  int lastSelected = 0;

  void clearSelectedIfLengthChanged(int length) {
    if (selected.length != length) {
      selected = List.filled(length, false);
    }
  }

  void select(int index) {
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
    }
  }

  bool isSelected(int index) => selected[index];
}
