import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<ViewModel>(), MockSpec<ViewModelOwnerFeature>()])
import 'dispatcher_test.mocks.dart';

void main() {
  VmDispatcherTests().run();
}

class VmDispatcherTests {
  void run() {
    group('ViewModel dispatcher lifecycle', () {
      normalLifecycle();
      paramHandling();
      features();
    });
  }

  void normalLifecycle() {
    testWidgets('Normal lifecycle', (tester) async {
      final vm = MockViewModel<Null>();
      final dispatcher = ViewModelDispatcher<MockViewModel<Null>, Null>(
        factory: () => vm,
        param: null,
        child: SizedBox(),
      );

      await tester.pumpWidget(dispatcher);
      await tester.pumpWidget(Container());
      verifyInOrder([vm.init(captureAny), vm.update(), vm.dispose()]);
    });
  }

  void paramHandling() {
    testWidgets('Param handling', (tester) async {
      final key = UniqueKey();

      final vm = MockViewModel<_TestParam>();
      final param1 = _TestParam();

      await tester.pumpWidget(
        ViewModelDispatcher<MockViewModel<_TestParam>, _TestParam>(
          key: key,
          factory: () => vm,
          param: param1,
          child: SizedBox(),
        ),
      );

      ViewModelDispatcherState<MockViewModel<_TestParam>, _TestParam> state =
          tester.firstState(find.byKey(key));

      expect(state.param, equals(param1));

      final param2 = _TestParam();

      await tester.pumpWidget(
        ViewModelDispatcher<MockViewModel<_TestParam>, _TestParam>(
          key: key,
          factory: () => vm,
          param: param2,
          child: SizedBox(),
        ),
      );

      expect(state.param, equals(param2));
      verify(vm.updateDependencies()).called(1);
    });
  }

  void features() {
    testWidgets('Feature lifecycle test', (tester) async {
      final key = UniqueKey();
      final vm = MockViewModel<_TestParam>();
      final feature = MockViewModelOwnerFeature();

      final param1 = _TestParam();
      await tester.pumpWidget(
        ViewModelDispatcher.test(
          key: key,
          factory: () => vm,
          param: param1,
          features: [feature],
          child: SizedBox(),
        ),
      );

      ViewModelDispatcherState<MockViewModel<_TestParam>, _TestParam> state =
          tester.firstState(find.byKey(key));
      expect(state.getFeature<MockViewModelOwnerFeature>(), equals(feature));

      final param2 = _TestParam();
      await tester.pumpWidget(
        ViewModelDispatcher.test(
          key: key,
          factory: () => vm,
          param: param2,
          features: [feature],
          child: SizedBox(),
        ),
      );

      await tester.pumpWidget(Container());
      verifyInOrder([
        feature.init(),
        feature.didUpdateWidget(),
        feature.dispose(),
      ]);
    });
  }
}

final class _TestParam extends ViewModelParameter {
  @override
  bool shouldUpdateDependencies(covariant _TestParam? oldParam) {
    return true;
  }
}
