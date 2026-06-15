import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'tab.freezed.dart';

const uuid = Uuid();

@freezed
abstract class ExTab with _$ExTab {
  factory ExTab({
    required UuidValue id, //
  }) = _ExTab;

  factory ExTab.create() => _ExTab(id: uuid.v7obj());
}
