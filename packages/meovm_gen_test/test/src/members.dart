import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/members.dart';
part 'golden/method_invoking.dart';

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
