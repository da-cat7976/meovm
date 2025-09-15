import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen_test/annotations.dart';

part 'golden/empty_param.dart';
part 'golden/empty_vm.dart';

@ShouldGenerateFile('golden/empty_vm.dart', partOfCurrent: true)
@Meovm()
class EmptyVm extends ViewModel with _$EmptyVm {}

@ShouldGenerateFile('golden/empty_param.dart', partOfCurrent: true)
@Meovm()
final class EmptyParam extends ViewModelParameter with _$EmptyParam {}
