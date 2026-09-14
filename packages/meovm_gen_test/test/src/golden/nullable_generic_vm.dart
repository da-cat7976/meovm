part of '../generics.dart';

mixin _$NullableGenericVm<V extends ChildVm?, P extends NullableGenericParam<V>>
    on ViewModel<P> {
  ValueMember<int?> get nested;
  @override
  List<ViewModelMember> get members {
    return [...super.members, nested];
  }
}
