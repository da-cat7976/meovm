import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/external_param.dart';
part 'golden/external_vm.dart';
part 'golden/getter_external_vm.dart';
part 'golden/manual_external_vm.dart';
part 'golden/multiple_nested_vm.dart';

class SomeVm extends ViewModel {
  late final value = ValueMember<int>();
  late final other = ValueMember<int>();
}

class GetterMemberVm extends ViewModel {
  late final _value = ValueMember<int>();

  ValueMember<int> get value => _value;

  @override
  List<ViewModelMember> get members => [...super.members, _value];
}

@ShouldGenerateFile('golden/external_param.dart', partOfCurrent: true)
@Meovm()
final class ExternalDepsParam extends ViewModelParameter
    with _$ExternalDepsParam {
  @override
  final SomeVm vm;

  @override
  final ValueMember<int> value;

  const ExternalDepsParam({required this.vm, required this.value});
}

@ShouldGenerateFile('golden/external_vm.dart', partOfCurrent: true)
@Meovm()
class ExternalDepsVm extends ViewModel<ExternalDepsParam>
    with _$ExternalDepsVm {
  @override
  late final fromMember = ValueMember(resolver: (_) => param.value.data + 1);

  @override
  late final fromVm = ValueMember(resolver: (_) => param.vm.value.data - 1);
}

final class GetterExternalParam extends ViewModelParameter {
  const GetterExternalParam(this.vm, this.getterVm);

  final SomeVm vm;
  final GetterMemberVm getterVm;

  ValueMember<int> get direct => vm.value;

  SomeVm get nested => vm;

  @override
  bool shouldUpdateDependencies(covariant GetterExternalParam? oldParam) =>
      oldParam?.vm != vm || oldParam?.getterVm != getterVm;
}

@ShouldGenerateFile('golden/getter_external_vm.dart', partOfCurrent: true)
@Meovm()
class GetterExternalVm extends ViewModel<GetterExternalParam>
    with _$GetterExternalVm {
  @override
  late final fromDirect = ValueMember<int>(resolver: (_) => param.direct.data);

  @override
  late final fromNested = ValueMember<int>(
    resolver: (_) => param.nested.value.data,
  );

  @override
  late final fromGetterMember = ValueMember<int>(
    resolver: (_) => param.getterVm.value.data,
  );
}

final class MultipleNestedParam extends ViewModelParameter {
  const MultipleNestedParam(this.first, this.second);

  final SomeVm first;
  final SomeVm second;

  @override
  bool shouldUpdateDependencies(covariant MultipleNestedParam? oldParam) =>
      oldParam?.first != first || oldParam?.second != second;
}

@ShouldGenerateFile('golden/multiple_nested_vm.dart', partOfCurrent: true)
@Meovm()
class MultipleNestedVm extends ViewModel<MultipleNestedParam>
    with _$MultipleNestedVm {
  @override
  late final value = ValueMember<int>(resolver: (_) => param.second.value.data);
}

@ShouldGenerateFile('golden/manual_external_vm.dart', partOfCurrent: true)
@Meovm()
class ManualExternalDepsVm extends ViewModel<ExternalDepsParam>
    with _$ManualExternalDepsVm {
  @override
  @MeovmDepend(#value, from: #vm, external: true)
  late final enabled = ValueMember<int>();

  @override
  @MeovmDepend(#other, from: #vm, external: true)
  late final enabledOther = ValueMember<int>();

  @override
  @MeovmDepend(#value, external: true)
  late final enabledAnonymous = ValueMember<int>();

  @override
  @MeovmDepend(#value, from: #vm, external: true, disabled: true)
  late final disabled = ValueMember(resolver: (_) => param.vm.value.data);

  @override
  @MeovmDepend(#value, external: true, disabled: true)
  late final disabledAnonymous = ValueMember(resolver: (_) => param.value.data);
}
