part of '../generics.dart';

mixin _$GenericMemberGetterVm<M extends ViewModelMember>
    on ViewModel<ViewModelParameter?> {
  ValueMember<int> get source;
  ValueMember<int> get value;
  @override
  List<ViewModelMember> get members {
    return [...super.members, source, value];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(source, value);
  }
}
