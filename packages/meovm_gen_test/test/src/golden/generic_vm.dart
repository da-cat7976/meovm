part of '../generics.dart';

mixin _$GenericVm<T extends models.Entity, P extends GenericParam<T>>
    on ViewModel<P> {
  ValueMember<T> get value;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.value, value);
  }
}
