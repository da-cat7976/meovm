import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/manual_dependencies.dart';
part 'golden/members.dart';
part 'golden/method_invoking.dart';
part 'golden/getter_invoking.dart';
part 'golden/concrete_resolvers.dart';

@ShouldGenerateFile('golden/members.dart', partOfCurrent: true)
@Meovm()
class MembersVm extends ViewModel with _$MembersVm {
  @override
  late final value = ValueMember<int>(resolver: (_) => list.data.length);

  @override
  late final list = ListMember();
}

@ShouldGenerateFile('golden/method_invoking.dart', partOfCurrent: true)
@Meovm()
class MethodInvokingVm extends ViewModel with _$MethodInvokingVm {
  @override
  late final valueA = ValueMember<int>();

  @override
  late final valueB = ValueMember<int>();

  @override
  late final valueC = ValueMember<int>(resolver: _resolver);

  int _resolver(int? data) {
    return valueA.data + valueB.data;
  }
}

@ShouldGenerateFile('golden/getter_invoking.dart', partOfCurrent: true)
@Meovm()
class GetterInvokingVm extends ViewModel with _$GetterInvokingVm {
  @override
  late final valueA = ValueMember<int>();

  bool get isOdd => valueA.data.isOdd;

  String describeValue() => isOdd ? 'Odd' : 'Even';

  @override
  late final valueB = ValueMember<String>(resolver: (_) => describeValue());
}

@ShouldGenerateFile('golden/concrete_resolvers.dart', partOfCurrent: true)
@Meovm()
class ConcreteResolversVm extends ViewModel with _$ConcreteResolversVm {
  @override
  late final input = member.editableText();

  @override
  late final cleaned = member.value(
    resolver: (_) => input.controller.text.trim(),
  );

  @override
  late final uri = member.value<Uri>(initial: Uri.parse('https://example.com'));

  @override
  late final formatted = member.value(resolver: (_) => uri.data.toString());
}

@ShouldGenerateFile('golden/manual_dependencies.dart', partOfCurrent: true)
@Meovm()
class ManualDependenciesVm extends ViewModel with _$ManualDependenciesVm {
  @override
  @MeovmDepend(#valueB)
  late final valueA = ValueMember<int>();

  @override
  @MeovmDepend(#valueA, disabled: true)
  late final valueB = ValueMember<int>(resolver: (_) => valueA.data + 1);
}
