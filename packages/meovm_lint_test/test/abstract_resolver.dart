import 'package:meovm/meovm.dart';

abstract class TestVm extends ViewModel {
  // expect_lint: meovm_abstract_resolver
  late final abs = ValueMember<int>(resolver: _absResolver);

  int _absResolver(int? data);

  late final nonAbs = ValueMember<int>(resolver: _nonAbsResolver);

  int _nonAbsResolver(int? data) {
    return 1;
  }
}
