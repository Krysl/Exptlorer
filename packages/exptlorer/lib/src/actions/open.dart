import 'dart:async';

import 'package:flutter/widgets.dart';

import '../rust/api/opener.dart';
import '../utils/log.dart';
import '../widgets/multi_select_list.dart';

class OpenIntent extends Intent {
  const OpenIntent();
}

class OpenAction extends Action<OpenIntent> {
  OpenAction({required this.controller});

  final MultiSelectController controller;

  @override
  Object? invoke(OpenIntent intent) {
    final entitys = controller.selectedEntitys.toList();
    log.debugEx('open $entitys', title: 'Action');
    for (final entity in entitys) {
      unawaited(openPath(path: entity.path));
    }
    return null;
  }
}
