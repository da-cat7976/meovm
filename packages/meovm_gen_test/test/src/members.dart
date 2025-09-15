import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/members.dart';

@ShouldGenerateFile('golden/members.dart', partOfCurrent: true)
@Meovm()
class MembersVm extends ViewModel with _$MembersVm {
  @override
  late final value = ValueMember<int>(
    resolver: (_) => list.data.length,
  );

  @override
  late final list = ListMember();
}