import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/widgets.dart';

import '../setting/theme/theme.dart';
import '../utils/log.dart';

class PaneDisplayModeIntent extends Intent {
  const PaneDisplayModeIntent();
}

class PaneDisplayModeAction extends Action<PaneDisplayModeIntent> {
  PaneDisplayModeAction({required this.controller, required this.displayMode});

  final AppTheme controller;
  final PaneDisplayMode displayMode;

  @override
  Object? invoke(PaneDisplayModeIntent intent) {
    log.debugEx('PaneDisplayMode changed to ${displayMode.name}', title: 'Action', tags: ['theme', 'displayMode']);
    controller.setDisplayMode(displayMode);
    return null;
  }
}
