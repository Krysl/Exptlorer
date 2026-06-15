import 'package:exptlorer/src/rust/api/opener.dart';
import 'package:flutter/widgets.dart';
import 'package:exptlorer/src/widgets/multi_select_list.dart';

class OpenIntent extends Intent {
  const OpenIntent();
}

class OpenAction extends Action<OpenIntent> {
  OpenAction({required this.controller});

  final MultiSelectController controller;

  @override
  Object? invoke(OpenIntent intent) {
    final entitys = controller.selectedEntitys.toList();
    print('open $entitys');
    for (final entity in entitys) {
      openPath(path: entity.path);
    }
    return null;
  }
}
