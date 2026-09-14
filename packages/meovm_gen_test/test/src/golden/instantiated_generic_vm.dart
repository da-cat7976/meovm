part of '../generics.dart';

mixin _$InstantiatedGenericVm<
  P extends InstantiatedGenericParam<ValueMember<int>>
>
    on ViewModel<P> {
  ValueMember<int> get value;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.member, value);
  }
}
