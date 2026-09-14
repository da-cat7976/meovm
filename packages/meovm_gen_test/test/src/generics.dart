import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

import 'models.dart' as models;

part 'golden/generic_param.dart';
part 'golden/generic_vm.dart';

class ChildVm extends ViewModel {
  late final childValue = ValueMember<int>();
}

@ShouldGenerateFile('golden/generic_param.dart', partOfCurrent: true)
@Meovm()
final class GenericParam<T extends models.Entity, V extends ChildVm>
    extends ViewModelParameter
    with _$GenericParam<T, V> {
  const GenericParam(this.value, this.child);

  @override
  final ValueMember<T> value;

  @override
  final V child;
}

abstract class GenericBaseVm<T, P extends ViewModelParameter>
    extends ViewModel<P> {
  late final source = ValueMember<int>();

  @override
  List<ViewModelMember> get members => [...super.members, source];
}

@ShouldGenerateFile('golden/generic_vm.dart', partOfCurrent: true)
@Meovm()
class GenericVm<
  T extends models.Entity,
  V extends ChildVm,
  P extends GenericParam<T, V>
>
    extends GenericBaseVm<T, P>
    with _$GenericVm<T, V, P> {
  @override
  late final value = ValueMember<T>(resolver: (_) => param.value.data);

  @override
  late final nested = ValueMember<int>(
    resolver: (_) => source.data + param.child.childValue.data,
  );
}
