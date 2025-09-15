part of '../external.dart';

base mixin _$ExternalDepsParam on ViewModelParameter {
  SomeVm get vm;
  ValueMember<int> get value;
  @override
  bool shouldUpdateDependencies(covariant ExternalDepsParam? oldParam) {
    return oldParam?.vm != vm || oldParam?.value != value;
  }
}
