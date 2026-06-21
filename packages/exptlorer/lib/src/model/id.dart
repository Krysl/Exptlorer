import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'id.g.dart';

const uuid = Uuid();

extension type Id<T>(UuidValue id) {
  factory Id.create() => Id(uuid.v7obj());
  factory Id.fromJson(Map<String, Object?> json) => Id(UuidValue.fromString(json['id']! as String));
  Map<String, dynamic> toJson() => {'id': id.toString()};
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
}

@immutable
class IdWrapper<T extends IdBase<T>> {
  const IdWrapper(this._value);
  final T _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdWrapper<T> && runtimeType == other.runtimeType && _value.id == other._value.id;

  @override
  int get hashCode => _value.id.hashCode;

  @override
  String toString() => 'IdWrapper<$T>($_value)';
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
