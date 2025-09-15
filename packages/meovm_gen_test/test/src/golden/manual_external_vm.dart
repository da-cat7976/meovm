part of '../external.dart';

mixin _$ManualExternalDepsVm on ViewModel<ExternalDepsParam> {
  ValueMember<int> get enabled;
  ValueMember<int> get enabledAnonymous;
  ValueMember<int> get disabled;
  ValueMember<int> get disabledAnonymous;
  @override
  List<ViewModelMember> get members {
    return [
      ...super.members,
      enabled,
      enabledAnonymous,
      disabled,
      disabledAnonymous,
    ];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(param.vm.value, enabled);
    depend(param.value, enabledAnonymous);
  }
}
