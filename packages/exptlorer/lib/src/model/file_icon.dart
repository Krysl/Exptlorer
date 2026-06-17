import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide IconData;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/api/file_icon.dart';

part 'file_icon.g.dart';

/// Convenience alias to disambiguate [dart:ui.Image] from Flutter's [Image] widget.
/// [issue & work around](https://github.com/rrousselGit/riverpod/issues/4372)
typedef UiImage = ui.Image;

extension TypeCheck on FileSystemEntity {
  bool get isDir => this is Directory;
}

@riverpod
class FileIcon extends _$FileIcon {
  @override
  FutureOr<UiImage?> build(String path) async {
    final icon = await getIconRgba(path: path);

    if (icon == null) return null;

    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      icon.bgraBytes,
      icon.width,
      icon.height,
      .bgra8888,
      completer.complete,
    );
    return await completer.future;
  }
}
