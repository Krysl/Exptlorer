import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'id.dart';
import 'workspace.dart';

part 'workspace_list.freezed.dart';
part 'workspace_list.g.dart';

@freezed
abstract class ExWorkspaceList with _$ExWorkspaceList {
  const factory ExWorkspaceList({
    @Default([]) List<IdWrapper<ExWorkspace>> workspaces,
  }) = _ExWorkspaceList;
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
    final ids = ws.map((e) => path.basenameWithoutExtension(e.path)).toList();
    final wss =
        (await Future.wait(
              ids.map(ExWorkspace.loadFromFolder),
            ))
            .whereType<ExWorkspace>()
            .map((e) => e.wrap())
            .map((id) => ref.watch(exWorkspaceControllerProvider(id)).wrap())
            .toList();

    return ExWorkspaceList(workspaces: wss);
  }

  void addNewWorkspace({String? name}) {
    final ws = state.requireValue;
    state = AsyncValue.data(
      ws.copyWith(
        workspaces: [
          ...ws.workspaces,
          ExWorkspace.empty(name: name).wrap(),
        ],
      ),
    );
  }

  void removeWorkspace(IdWrapper<ExWorkspace> id) {
    final ws = state.requireValue;
    state = AsyncValue.data(
      ws.copyWith(
        workspaces: List.from(ws.workspaces)..remove(id),
      ),
    );
  }
}
