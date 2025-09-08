import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<ViewModelOwner>(), MockSpec<ViewModelMember>()])
import 'vm_test.mocks.dart';

void main() {
  VmLifecycleTests().run();
}

class VmLifecycleTests {
  void run() {
    group('ViewModel lifecycle tests', () {
      empty();
      withMember();
      withDependencies();
      assertOnCircularDependency();
      paramHandling();
    });
  }

  void empty() {
    test('Empty ViewModel lifecycle', () {
      final owner = MockViewModelOwner();
      when(owner.param).thenReturn(null);

      final vm = _TestVm(members: []);
      expect(vm.state, equals(ViewModelState.created));
      expect(() => vm.init(owner), returnsNormally);
      expect(vm.state, equals(ViewModelState.active));

      expect(() => vm.update(), returnsNormally);
      expect(vm.state, equals(ViewModelState.active));

      expect(() => vm.dispose(), returnsNormally);
      expect(vm.state, equals(ViewModelState.disposed));
    });
  }

  void withMember() {
    test('Member lifecycle handling', () {
      final owner = MockViewModelOwner();
      when(owner.param).thenReturn(null);

      final member = MockViewModelMember();
      final vm = _TestVm(members: [member]);

      expect(() => vm.init(owner), returnsNormally);
      expect(() => vm.update(), returnsNormally);
      expect(() => vm.dispose(), returnsNormally);

      verify(member.init(owner)).called(1);
      verify(member.update()).called(1);
      verify(member.dispose()).called(1);
    });
  }

  void withDependencies() {
    test('Update ordered by dependencies', () {
      final owner = MockViewModelOwner();
      when(owner.param).thenReturn(null);

      final member1 = MockViewModelMember();
      final member2 = MockViewModelMember();
      final member3 = MockViewModelMember();
      final vm = _TestVm(
        members: [member1, member2, member3],
        setDeps: (depend) {
          depend(member3, member2);
          depend(member1, member3);
        },
      );

      expect(() => vm.init(owner), returnsNormally);
      expect(() => vm.update(), returnsNormally);
      expect(() => vm.dispose(), returnsNormally);

      verifyInOrder([member1.update(), member3.update(), member2.update()]);
    });
  }

  void assertOnCircularDependency() {
    test('Circular dependency', () {
      final owner = MockViewModelOwner();
      when(owner.param).thenReturn(null);

      final member1 = MockViewModelMember();
      final member2 = MockViewModelMember();
      final member3 = MockViewModelMember();

      final vm = _TestVm(
        members: [member1, member2, member3],
        setDeps: (depend) {
          depend(member1, member2);
          depend(member2, member3);
          depend(member3, member1);
        },
      );

      expect(() => vm.init(owner), throwsAssertionError);
    });
  }

  void paramHandling() {
    test('Param availability', () {
      final owner = MockViewModelOwner<_TestParam?>();
      final param1 = _TestParam();
      when(owner.param).thenReturn(param1);

      final vm = _TestVm(members: []);
      expect(() => vm.init(owner), returnsNormally);
      // ignore: invalid_use_of_protected_member
      expect(vm.param, equals(param1));

      final param2 = _TestParam();
      when(owner.param).thenReturn(param2);
      expect(() => vm.update(), returnsNormally);
      // ignore: invalid_use_of_protected_member
      expect(vm.param, equals(param2));
    });
  }
}

class _TestVm extends ViewModel {
  @override
  final List<ViewModelMember> members;

  final void Function(ViewModelDependencySetter depend)? setDeps;

  _TestVm({this.members = const [], this.setDeps});

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    setDeps?.call(depend);
  }
}

final class _TestParam extends ViewModelParameter {
  @override
  bool shouldUpdateDependencies(ViewModelParameter oldParam) {
    return false;
  }
}
