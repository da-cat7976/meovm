part of '../generics.dart';

mixin _$GenericVm<
  T extends models.Entity,
  V extends ChildVm,
  P extends GenericParam<T, V>
>
    on GenericBaseVm<T, P> {
  ValueMember<T> get value;
  ValueMember<int> get nested;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value, nested];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.value, value);
    depend(source, nested);
    depend(param.child.childValue, nested);
  }
}
