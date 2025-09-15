part of '../members.dart';

mixin _$MembersVm on ViewModel<ViewModelParameter?> {
  ValueMember<int> get value;
  ListMember<dynamic> get list;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value, list];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(list, value);
  }
}
