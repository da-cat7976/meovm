part of '../generics.dart';

base mixin _$GenericParam<T extends models.Entity, V extends ChildVm>
    on ViewModelParameter {
  ValueMember<T> get value;
  V get child;
  @override
  bool shouldUpdateDependencies(covariant GenericParam<T, V>? oldParam) {
    return oldParam?.value != value || oldParam?.child != child;
  }
}
