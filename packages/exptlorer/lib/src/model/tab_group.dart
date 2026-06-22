import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'id.dart';
import 'tab.dart';

part 'tab_group.g.dart';
part 'tab_group.freezed.dart';

@freezed
abstract class ExTabGroup extends IdBase<ExTabGroup> with _$ExTabGroup {
  const factory ExTabGroup({
    required Id<ExTabGroup> id,
    @Default([]) List<IdWrapper<ExTab>> tabs,
    @Default(0) int activeTabIndex,
    @Default(false) bool isActive,
  }) = _ExTabGroup;

  const ExTabGroup._({required Id<ExTabGroup> id}) : super.id(id);
  factory ExTabGroup.create({Id<ExTabGroup>? id, List<IdWrapper<ExTab>>? tabs}) =>
      _ExTabGroup(id: id ?? Id.create(), tabs: tabs ?? []);

  factory ExTabGroup.fromJson(Map<String, Object?> json) => _$ExTabGroupFromJson(json);

  @override
  ExTabGroup trueState(Ref ref) => ref.read(exTabGroupControllerProvider(wrap()));

  IdWrapper<ExTab> get activeTab => tabs[activeTabIndex];
}

@Riverpod(keepAlive: true)
class ExTabGroupController extends _$ExTabGroupController with IdWrapperMixin<ExTabGroup> {
  @override
  ExTabGroup build(IdWrapper<ExTabGroup> tabGroup) => buildById(tabGroup);

  @pragma('vm:prefer-inline')
  List<IdWrapper<ExTab>> _newList() => List<IdWrapper<ExTab>>.from(state.tabs);

  void addNewTab([ExTab? tab]) {
    final newTab = tab ?? ExTab.create(null);
    state = state.copyWith(tabs: _newList()..add(newTab.wrap()));
  }

  void removeTab(ExTab tab) {
    state = state.copyWith(tabs: _newList()..remove(tab.wrap()));
  }

  void activeTab(int index) {
    final currentIdx = state.activeTabIndex;
    if (currentIdx != index) {
      final current = state.tabs[currentIdx];
      state = state.copyWith(
        activeTabIndex: index,
        tabs:
            _newList() //
              ..[currentIdx] = update(current, (v) => v.copyWith(isActive: false)),
      );
    }
  }

  void setActive({required bool isActive}) {
    state = state.copyWith(isActive: isActive);
  }
}
