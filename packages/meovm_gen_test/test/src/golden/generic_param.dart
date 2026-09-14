part of '../generics.dart';

base mixin _$GenericParam<T extends num> on ViewModelParameter {
  ValueMember<T> get value;
  @override
  bool shouldUpdateDependencies(covariant GenericParam<T>? oldParam) {
    return oldParam?.value != value;
  }
}
