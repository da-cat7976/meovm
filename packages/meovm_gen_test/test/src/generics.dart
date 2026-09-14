import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

import 'models.dart' as models;

part 'golden/generic_param.dart';
part 'golden/generic_vm.dart';

@ShouldGenerateFile('golden/generic_param.dart', partOfCurrent: true)
@Meovm()
final class GenericParam<T extends models.Entity> extends ViewModelParameter
    with _$GenericParam<T> {
  const GenericParam(this.value);

  @override
  final ValueMember<T> value;
}

@ShouldGenerateFile('golden/generic_vm.dart', partOfCurrent: true)
@Meovm()
class GenericVm<T extends models.Entity, P extends GenericParam<T>>
    extends ViewModel<P>
    with _$GenericVm<T, P> {
  @override
  late final value = ValueMember<T>(resolver: (_) => param.value.data);
}
