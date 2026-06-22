import 'dart:async';

import 'package:flutter/widgets.dart';

import '../model/workspace.dart';
import '../utils/log.dart';

class SaveWorkspaceIntent extends Intent {
  const SaveWorkspaceIntent();
}

class SaveWorkspaceAction extends Action<SaveWorkspaceIntent> {
  SaveWorkspaceAction({required this.controller, required this.name});

  final ExWorkspaceController controller;
  final String name;

  @override
  Object? invoke(SaveWorkspaceIntent intent) {
    log.debugEx('save Workspace ${controller.name}', title: 'Action', tags: ['workspace', 'save']);
    unawaited(controller.save(name));
    return null;
  }
}
