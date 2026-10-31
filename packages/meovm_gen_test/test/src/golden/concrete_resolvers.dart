part of '../members.dart';

mixin _$ConcreteResolversVm on ViewModel<ViewModelParameter?> {
  EditableTextMember get input;
  ValueMember<String> get cleaned;
  ValueMember<Uri> get uri;
  ValueMember<String> get formatted;
  @override
  List<ViewModelMember> get members {
    return [...super.members, input, cleaned, uri, formatted];
  }

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    super.setDependencies(depend);
    depend(input, cleaned);
    depend(uri, formatted);
  }
}
