import 'package:flutter/foundation.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';

class TestMember extends ViewModelMember with ChangeNotifier {
  @override
  void update() {
    // Intentionally left blank
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

  @meovmInternal
  void operator []=(int index, int value) {
    // Intentionally left blank
  }
}

class TestVm extends ViewModel {
  late final test = TestMember();

  void testInternally() {
    test.field;
    test.getter;
    test.setter = 1;
    test.method();
    test[1] = 1;
  }
}

// ignore: unused_element
mixin _$TestVm on ViewModel {
  TestMember get test;

  void testInMixin() {
    test.field;
    test.getter;
    test.setter = 1;
    test.method();
    test[1] = 1;
  }
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
  // expect_lint: meovm_external_modification
  vm.test[1] = 1;
}