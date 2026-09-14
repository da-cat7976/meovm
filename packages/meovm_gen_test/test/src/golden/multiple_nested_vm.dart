part of '../external.dart';

mixin _$MultipleNestedVm on ViewModel<MultipleNestedParam> {
  ValueMember<int> get value;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.second.value, value);
  }
}
