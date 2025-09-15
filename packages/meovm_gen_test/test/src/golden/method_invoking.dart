part of '../members.dart';

mixin _$MethodInvokingVm on ViewModel<ViewModelParameter?> {
  ValueMember<int> get valueA;
  ValueMember<int> get valueB;
  ValueMember<int> get valueC;
  @override
  List<ViewModelMember> get members {
    return [...super.members, valueA, valueB, valueC];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(valueA, valueC);
    depend(valueB, valueC);
  }
}
