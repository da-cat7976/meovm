part of '../generics.dart';

mixin _$GenericVm<T extends num, P extends GenericParam<T>> on ViewModel<P> {
  ValueMember<T> get value;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value];
  }
}
