import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'id.dart';
import 'tab.dart';
import 'tab_group.dart';

part 'window.freezed.dart';
part 'window.g.dart';

@freezed
abstract class ExWindow extends IdBase<ExWindow> with _$ExWindow {
  const factory ExWindow({
    required Id<ExWindow> id,
    @Default([]) List<ExTabGroup> groups,
    @Default(0) int activeTabGroupIndex,
  }) = _ExWindow;

  const ExWindow._({required Id<ExWindow> id}) : super.id(id);

  factory ExWindow.fromJson(Map<String, Object?> json) => _$ExWindowFromJson(json);

  @override
  ExWindow trueState(Ref ref) => ref.read(exWindowControllerProvider(wrap()));
}

@Riverpod(keepAlive: true)
class ExWindowController extends _$ExWindowController with IdWrapperMixin<ExWindow> {
  @override
  ExWindow build(IdWrapper<ExWindow> tabWindow) => buildById(tabWindow);

  @pragma('vm:prefer-inline')
  List<ExTabGroup> _newList() => List<ExTabGroup>.from(state.groups);

  void addNewTabGroup([ExTabGroup? group]) {
    final newTabGroup = group ?? ExTabGroup.create(tabs: [ExTab.create(null)]);
    state = state.copyWith(groups: _newList()..add(newTabGroup));
  }

  void removeTabGroup(ExTabGroup tabGroup) {
    state = state.copyWith(groups: _newList()..remove(tabGroup));
  }

  void activeTabGroup(int index) {
    final currentIdx = state.activeTabGroupIndex;
    if (currentIdx != index) {
      final current = state.groups[currentIdx];
      state = state.copyWith(
        activeTabGroupIndex: index,
        groups:
            _newList() //
              ..[currentIdx] = current.copyWith(isActive: false),
      );
    }
  }
}
