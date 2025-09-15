part of '../members.dart';

mixin _$ManualDependenciesVm on ViewModel<ViewModelParameter?> {
  ValueMember<int> get valueA;
  ValueMember<int> get valueB;
  @override
  List<ViewModelMember> get members {
    return [...super.members, valueA, valueB];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(valueB, valueA);
  }
}
