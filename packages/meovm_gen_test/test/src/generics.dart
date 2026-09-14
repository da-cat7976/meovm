import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

import 'models.dart' as models;

part 'golden/generic_param.dart';
part 'golden/generic_vm.dart';
part 'golden/instantiated_generic_vm.dart';
part 'golden/nullable_generic_param_vm.dart';
part 'golden/nullable_generic_vm.dart';

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

final class InstantiatedGenericParam<M extends ViewModelMember>
    extends ViewModelParameter {
  const InstantiatedGenericParam(this.member);

  final M member;

  @override
  bool shouldUpdateDependencies(
    covariant InstantiatedGenericParam<M>? oldParam,
  ) => oldParam?.member != member;
}

@ShouldGenerateFile('golden/instantiated_generic_vm.dart', partOfCurrent: true)
@Meovm()
class InstantiatedGenericVm<
  P extends InstantiatedGenericParam<ValueMember<int>>
>
    extends ViewModel<P>
    with _$InstantiatedGenericVm<P> {
  @override
  late final value = ValueMember<int>(resolver: (_) => param.member.data);
}

final class NullableParam extends ViewModelParameter {
  const NullableParam(this.value);

  final ValueMember<int> value;

  @override
  bool shouldUpdateDependencies(covariant NullableParam? oldParam) =>
      oldParam?.value != value;
}

@ShouldGenerateFile(
  'golden/nullable_generic_param_vm.dart',
  partOfCurrent: true,
)
@Meovm()
class NullableGenericParamVm<P extends NullableParam?> extends ViewModel<P>
    with _$NullableGenericParamVm<P> {
  @override
  late final value = ValueMember<int?>(resolver: (_) => param?.value.data);
}

final class NullableGenericParam<V extends ChildVm?>
    extends ViewModelParameter {
  const NullableGenericParam(this.child);

  final V child;

  @override
  bool shouldUpdateDependencies(covariant NullableGenericParam<V>? oldParam) =>
      oldParam?.child != child;
}

@ShouldGenerateFile('golden/nullable_generic_vm.dart', partOfCurrent: true)
@Meovm()
class NullableGenericVm<V extends ChildVm?, P extends NullableGenericParam<V>>
    extends ViewModel<P>
    with _$NullableGenericVm<V, P> {
  @override
  late final nested = ValueMember<int?>(
    resolver: (_) => param.child?.childValue.data,
  );
}
