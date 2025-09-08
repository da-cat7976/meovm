import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<ViewModel>()])
import 'dispatcher_test.mocks.dart';

void main() {
  VmDispatcherTests().run();
}

class VmDispatcherTests {
  void run() {
    group('ViewModel dispatcher lifecycle', () {
      normalLifecycle();
      paramHandling();
    });
  }

  void normalLifecycle() {
    testWidgets('Normal lifecycle', (tester) async {
      final vm = MockViewModel<Null>();
      final dispatcher = _TestVmDispatcher<MockViewModel<Null>, Null>(
        factory: () => vm,
        param: null,
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
        _TestVmDispatcher<MockViewModel<_TestParam>, _TestParam>(
          key: key,
          factory: () => vm,
          param: param1,
        ),
      );

      _TestVmDispatcherState<MockViewModel<_TestParam>, _TestParam> state =
          tester.firstState(find.byKey(key));

      expect(state.param, equals(param1));

      final param2 = _TestParam();

      await tester.pumpWidget(
        _TestVmDispatcher<MockViewModel<_TestParam>, _TestParam>(
          key: key,
          factory: () => vm,
          param: param2,
        ),
      );

      expect(state.param, equals(param2));
      verify(vm.updateDependencies()).called(1);
    });
  }
}

class _TestVmDispatcher<
  VM extends ViewModel<Param>,
  Param extends ViewModelParameter?
>
    extends StatefulWidget
    with ViewModelDispatcherBase<VM, Param> {
  const _TestVmDispatcher({
    required this.factory,
    required this.param,
    super.key,
  });

  @override
  final Widget child = const SizedBox();

  @override
  final ViewModelFactory<VM, Param> factory;

  @override
  final Param param;

  @override
  State<StatefulWidget> createState() => _TestVmDispatcherState<VM, Param>();
}

class _TestVmDispatcherState<
  VM extends ViewModel<Param>,
  Param extends ViewModelParameter?
>
    extends State<_TestVmDispatcher<VM, Param>>
    with
        ViewModelDispatcherStateBase<_TestVmDispatcher<VM, Param>, VM, Param>,
        TickerProviderStateMixin {}

final class _TestParam extends ViewModelParameter {
  @override
  bool shouldUpdateDependencies(covariant _TestParam? oldParam) {
    return true;
  }
}
