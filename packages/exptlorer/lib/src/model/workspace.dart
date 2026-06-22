import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../utils/log.dart';
import 'id.dart';
import 'tab.dart';
import 'tab_group.dart';
import 'window.dart';

part 'workspace.freezed.dart';
part 'workspace.g.dart';

@freezed
abstract class ExWorkspace extends IdBase<ExWorkspace> with _$ExWorkspace {
  const factory ExWorkspace({
    required Id<ExWorkspace> id,
    required String name,
    @Default([]) List<IdWrapper<ExWindow>> windows,
  }) = _ExWorkspace;

  const ExWorkspace._({required Id<ExWorkspace> id}) : super.id(id);

  factory ExWorkspace.fromJson(Map<String, Object?> json) => _$ExWorkspaceFromJson(json);
  factory ExWorkspace.empty({Id<ExWorkspace>? id, String? name}) => ExWorkspace(
    id: id ?? Id.create(),
    name: name ?? 'Default',
    windows: [
      ExWindow(
        id: Id.create(),
        name: 'default',
        groups: [
          ExTabGroup(
            id: Id.create(),
            tabs: [
              ExTab.create(null).wrap(),
            ],
          ).wrap(),
        ],
      ).wrap(),
    ],
  );
  @override
  ExWorkspace trueState(Ref ref) => ref.read(exWorkspaceControllerProvider(wrap()));

  static Future<ExWorkspace?> loadFromFolder(String id) async {
    final file = await getWorkspaceFileByName(id);
    if (file.existsSync()) {
      final json = await file.readAsString();
      try {
        return ExWorkspace.fromJson(jsonDecode(json) as Map<String, Object?>);
      } catch (e) {
        log.error('error', e);
      }
    }
    return null;
  }
}

Future<Directory> workspaceSavedFolder() async {
  final dir = await getApplicationDocumentsDirectory();
  final workDir = Directory(path.join(dir.path, appTitle, 'workspaces'));
  return workDir;
}

Future<File> getWorkspaceFileByName(String name) async {
  final dir = await workspaceSavedFolder();
  return File(path.join(dir.path, '$name.json'));
}

@Riverpod(keepAlive: true)
class ExWorkspaceController extends _$ExWorkspaceController with IdWrapperMixin<ExWorkspace> {
  @override
  ExWorkspace build(IdWrapper<ExWorkspace> id) => buildById(id);

  String? name() => state.name;

  Future<void> save(Id<ExWorkspace> id) async {
    final file = await getWorkspaceFileByName(id.id.toString());
    final data = state;
    final jsonData = data.toJson();
    log.debugEx('save to ${file.path}: $jsonData', title: 'WorkspaceController', tags: ['workspace', 'save']);
    final a = encoder(ref).convert(
      jsonData,
    );

    await file.writeAsString(a);
  }

  JsonEncoder encoder(Ref ref) {
    return JsonEncoder.withIndent(
      '  ',
      (object) {
        if (object is UuidValue) {
          return {'id': object.toString()};
        } else if (object is IdBase) {
          final trueState = object.trueState(ref);
          log.debugEx('json encode $trueState', title: 'Workspace', tags: ['workspace', 'save', 'json']);
          return trueState.toJson();
        } else if (object is IdWrapper) {
          return object.toJson();
        }
        throw JsonUnsupportedObjectError(object);
      },
    );
  }
}
