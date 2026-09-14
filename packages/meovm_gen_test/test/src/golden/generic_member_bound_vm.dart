part of '../generics.dart';

mixin _$GenericMemberBoundVm<
  M extends ViewModelMember,
  P extends InstantiatedGenericParam<M>
>
    on ViewModel<P> {
  ValueMember<M> get value;
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
