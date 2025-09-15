import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/external_param.dart';
part 'golden/external_vm.dart';

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
  late final fromMember = ValueMember(resolver: (_) => param.value.data + 1);

  late final fromVm = ValueMember(resolver: (_) => param.vm.value.data - 1);
}
