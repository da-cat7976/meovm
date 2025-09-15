part of '../external.dart';

mixin _$ExternalDepsVm on ViewModel<ExternalDepsParam> {
  ValueMember<int> get fromMember;
  ValueMember<int> get fromVm;
  @override
  List<ViewModelMember> get members {
    return [...super.members, fromMember, fromVm];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.value, fromMember);
    depend(param.vm.value, fromVm);
  }
}
