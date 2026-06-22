import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'workspace.dart';

part 'workspace_list.freezed.dart';
part 'workspace_list.g.dart';

@freezed
abstract class ExWorkspaceList with _$ExWorkspaceList {
  const factory ExWorkspaceList({
    @Default([]) List<String> workspaces,
  }) = _ExWorkspaceList;

  factory ExWorkspaceList.fromJson(Map<String, Object?> json) => _$ExWorkspaceListFromJson(json);
}

@riverpod
class ExWorkspaceListController extends _$ExWorkspaceListController {
  @override
  FutureOr<ExWorkspaceList> build() async {
    final dir = await workspaceSavedFolder();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final ws = await dir.list().where((p) => p.path.endsWith('.json')).toList();
    return ExWorkspaceList(workspaces: ws.map((e) => path.basenameWithoutExtension(e.path)).toList());
  }
}
