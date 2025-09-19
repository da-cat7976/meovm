import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';

class TestVm extends ViewModel {
  @meovmLifecycle
  void lifecycleMethod() {
    // Intentionally left blank
  }

  void nonLifecycleMethod() {
    // Intentionally left blank
  }

  void test() {
    lifecycleMethod();
    nonLifecycleMethod();
  }
}

void fun() {
  final vm = TestVm();
  // expect_lint: meovm_invalid_lifecycle_access
  vm.lifecycleMethod();
  vm.nonLifecycleMethod();
}