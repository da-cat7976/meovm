import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/external_param.dart';
part 'golden/external_vm.dart';
part 'golden/manual_external_vm.dart';

class SomeVm extends ViewModel {
  late final value = ValueMember<int>();
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

@ShouldGenerateFile('golden/manual_external_vm.dart', partOfCurrent: true)
@Meovm()
class ManualExternalDepsVm extends ViewModel<ExternalDepsParam> with _$ManualExternalDepsVm {
  @override
  @MeovmDepend(#value, from: #vm, external: true)
  late final enabled = ValueMember<int>();

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
