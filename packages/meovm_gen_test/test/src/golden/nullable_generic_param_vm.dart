part of '../generics.dart';

mixin _$NullableGenericParamVm<P extends NullableParam?> on ViewModel<P> {
  ValueMember<int?> get value;
  @override
  List<ViewModelMember> get members {
    return [...super.members, value];
  }
}
