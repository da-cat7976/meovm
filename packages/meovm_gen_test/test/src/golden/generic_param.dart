part of '../generics.dart';

base mixin _$GenericParam<T extends models.Entity> on ViewModelParameter {
  ValueMember<T> get value;
  @override
  bool shouldUpdateDependencies(covariant GenericParam<T>? oldParam) {
    return oldParam?.value != value;
  }
}
