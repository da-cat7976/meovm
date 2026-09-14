part of '../external.dart';

mixin _$GetterExternalVm on ViewModel<GetterExternalParam> {
  ValueMember<int> get fromDirect;
  ValueMember<int> get fromNested;
  @override
  List<ViewModelMember> get members {
    return [...super.members, fromDirect, fromNested];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.direct, fromDirect);
    depend(param.nested.value, fromNested);
  }
}
