import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'id.dart';

part 'tab.freezed.dart';
part 'tab.g.dart';

@freezed
abstract class ExTab extends IdBase<ExTab> with _$ExTab {
  const factory ExTab({
    required Id<ExTab> id,
    required Uri? uri,
    @Default(false) bool isActive,
  }) = _ExTab;

  const ExTab._({required Id<ExTab> id}) : super.id(id);

  factory ExTab.create(Uri? uri) => _ExTab(id: Id.create(), uri: uri);

  factory ExTab.fromJson(Map<String, Object?> json) => _$ExTabFromJson(json);

  @override
  ExTab trueState(Ref ref) => ref.read(exTabControllerProvider(wrap()));
}

@Riverpod(keepAlive: true)
class ExTabController extends _$ExTabController with IdWrapperMixin<ExTab> {
  @override
  ExTab build(IdWrapper<ExTab> tab) => buildById(tab);

  void updateUri(Uri? uri) => state = state.copyWith(uri: uri);
}
