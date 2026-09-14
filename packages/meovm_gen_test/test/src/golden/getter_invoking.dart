part of '../members.dart';

mixin _$GetterInvokingVm on ViewModel<ViewModelParameter?> {
  ValueMember<int> get valueA;
  ValueMember<String> get valueB;
  @override
  List<ViewModelMember> get members {
    return [...super.members, valueA, valueB];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(valueA, valueB);
  }
}
