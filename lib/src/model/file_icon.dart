import 'dart:async';
import 'dart:ui' as ui;

import 'package:exptlorer/src/rust/api/file_icon.dart' hide IconData;
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_icon.g.dart';

/// Convenience alias to disambiguate [dart:ui.Image] from Flutter's [Image] widget.
/// [issue & work around](https://github.com/rrousselGit/riverpod/issues/4372)
typedef UiImage = ui.Image;

@riverpod
class FileIcon extends _$FileIcon {
  @override
  FutureOr<UiImage?> build(String path) async {
    final icon = await getFileIconRgba(path: path);

    if (icon == null) return null;

    final Completer<ui.Image> completer = Completer();

    ui.decodeImageFromPixels(
      icon.bgraBytes,
      icon.width,
      icon.height,
      .bgra8888,
      (ima) => completer.complete(ima),
    );
    return await completer.future;
  }
}
