import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'tab.dart';
import 'tab_group.dart';
import 'window.dart';
import 'workspace.dart';

part 'id.g.dart';

const uuid = Uuid();

extension type Id<T>(UuidValue id) {
  factory Id.create() => Id(uuid.v7obj());
  factory Id.fromJson(Map<String, Object?> json) => Id(UuidValue.fromString(json['id']! as String));
  factory Id.fromString(String str) => Id(UuidValue.fromString(str));
  Map<String, dynamic> toJson() => {'id': id.toString(), 'type': T.toString()};
}

abstract class IdBase<T extends IdBase<T>> {
  const IdBase.id(this.id);
  final Id<T> id;
  IdWrapper<T> wrap() => IdWrapper<T>(this as T);
  Map<String, dynamic> toJson();
  T trueState(Ref ref);
}

final idTypes = <Type>{};

mixin IdWrapperMixin<T extends IdBase<T>> on $Notifier<T> {
  T buildById(IdWrapper<T> tab) {
    // final ids = ref.read(idControllerProvider<T>().notifier);
    // idTypes.add(T);
    // listenSelf((prev, next) {
    //   ids.update(next.id, next);
    // });
    return tab._value;
  }

  IdWrapper<R> update<R extends IdBase<R>>(IdWrapper<R> id, R Function(R) fn) {
    return fn(id._value).wrap();
  }
}
mixin AsyncIdWrapperMixin<T extends IdBase<T>> on $AsyncNotifier<T> {
  T buildById(IdWrapper<T> tab) {
    // final ids = ref.read(idControllerProvider<T>().notifier);
    // idTypes.add(T);
    // listenSelf((prev, next) {
    //   ids.update(next.id, next);
    // });
    return tab._value;
  }

  IdWrapper<R> updateValue<R extends IdBase<R>>(IdWrapper<R> id, R Function(R) fn) {
    return fn(id._value).wrap();
  }
}

typedef FromJson = IdBase Function(Map<String, Object?>);

final fromMap = <String, FromJson>{
  'ExWorkspace': ExWorkspace.fromJson,
  'ExWindow': ExWindow.fromJson,
  'ExTabGroup': ExTabGroup.fromJson,
  'ExTab': ExTab.fromJson,
};

final keyTypeMap = {'tabs': 'ExTabGroup', 'uri': 'ExTab'};

@immutable
class IdWrapper<T extends IdBase<T>> {
  const IdWrapper(this._value);

  factory IdWrapper.fromJson(Map<String, Object?> json) {
    var value = json['value'] as Map<String, Object?>?;
    var type = json['type'] as String?;

    if (value == null) {
      final key = keyTypeMap.keys.firstWhereOrNull((key) => json.containsKey(key));
      if (key != null) {
        value = json;
        type = keyTypeMap[key];
      }
    }
    final t = fromMap[type]!.call(value!) as T;
    return IdWrapper(t);
  }
  Map<String, dynamic> toJson() => {'type': T.toString(), 'value': _value.toJson()};

  final T _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdWrapper<T> && runtimeType == other.runtimeType && _value.id == other._value.id;

  @override
  int get hashCode => _value.id.hashCode;

  @override
  String toString() => 'IdWrapper<$T>($_value)';

  Id<T> get id => _value.id;
}

class IdCollection<T extends IdBase<T>> {
  final Map<Id<T>, T> map = {};
}

@riverpod
class IdController<T extends IdBase<T>> extends _$IdController<T> {
  @override
  IdCollection<T> build() => IdCollection<T>();

  void update(Id<T> id, T value) {
    state.map[id] = value;
    ref.notifyListeners();
  }
}
