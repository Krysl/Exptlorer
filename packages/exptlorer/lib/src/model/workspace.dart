import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
    @Default([]) List<ExWindow> windows,
  }) = _ExWorkspace;

  const ExWorkspace._({required Id<ExWorkspace> id}) : super.id(id);

  factory ExWorkspace.fromJson(Map<String, Object?> json) => _$ExWorkspaceFromJson(json);
  @override
  ExWorkspace trueState(Ref ref) {
    final read = ref.read(workspaceControllerProvider(name));
    return read.requireValue;
  }
}

@Riverpod(keepAlive: true)
class WorkspaceController extends _$WorkspaceController {
  Future<File> _getFileByName(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, name));
    return file;
  }

  @override
  Future<ExWorkspace> build(String name) async {
    final file = await _getFileByName(name);
    if (file.existsSync()) {
      final json = await file.readAsString();
      try {
        return ExWorkspace.fromJson(jsonDecode(json) as Map<String, Object?>);
      } catch (e) {
        log.error('error', e);
      }
    }
    return ExWorkspace(
      id: Id.create(),
      name: name,
      windows: [
        ExWindow(
          id: Id.create(),
          groups: [
            ExTabGroup(
              id: Id.create(),
              tabs: [
                ExTab.create(null), //
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> save(String name) async {
    final file = await _getFileByName(name);
    final data = state.requireValue;
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
        // Id<T> 是 extension type，运行时擦除为 UuidValue
        // json.encode 不认识 UuidValue，通过 toEncodable 转成正确格式
        if (object is UuidValue) {
          return {'id': object.toString()};
        } else if (object is IdBase) {
          final trueState = object.trueState(ref);
          log.debugEx('json encode $trueState', title: 'Workspace', tags: ['workspace', 'save', 'json']);
          return trueState.toJson();
        }
        throw JsonUnsupportedObjectError(object);
      },
    );
  }
}
