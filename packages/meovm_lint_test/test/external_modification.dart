import 'package:flutter/foundation.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';

class TestMember extends ViewModelMember with ChangeNotifier {
  @override
  void update() {
    // TODO: implement update
  }

  @meovmInternal
  int field = 0;

  @meovmInternal
  int get getter => field;

  int get setter => 0;

  @meovmInternal
  set setter(int value) {
    // Intentionally left blank
  }

  @meovmInternal
  void method() {
    // Intentionally left blank
  }
}

class TestVm extends ViewModel {
  late final test = TestMember();
}

void fun() {
  final vm = TestVm();
  // expect_lint: meovm_external_modification
  vm.test.field;
  // expect_lint: meovm_external_modification
  vm.test.getter;
  // expect_lint: meovm_external_modification
  vm.test.setter = 1;
  // expect_lint: meovm_external_modification
  vm.test.method();
}