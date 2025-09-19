// ignore_for_file: meovm_external_modification
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';

void main() {
  NavigationMembersTests().run();
}

class NavigationMembersTests {
  void run() {
    group('Navigation & Modal members', () {
      _navigationMemberUseNavigation();
      _modalFlowMemberRequestAndComplete();
      _modalFlowMemberDoubleRequestReturnsSameFuture();
      _modalFlowMemberResetShouldClose();
    });
  }

  void _navigationMemberUseNavigation() {
    testWidgets('NavigationMember.useNavigation triggers callback on data change', (tester) async {
      final vm = _NavigationVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: HookBuilder(
              builder: (context) {
                final vm = context.useVM<_NavigationVm>();
                final last = useState<String?>('<none>');

                vm.navigation.useNavigation((_, data) {
                  last.value = data;
                });

                return Text(
                  last.value ?? '<null>',
                  key: const ValueKey('last_nav'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('last_nav')), findsOneWidget);
      expect(find.text('<none>'), findsOneWidget);

      vm.navigation.data = 'go:/details';
      // Listener runs in a microtask, then Hook's state update requires another frame
      await tester.pumpAndSettle();

      expect(find.text('go:/details'), findsOneWidget);
      expect(find.text('<none>'), findsNothing);
    });
  }

  void _modalFlowMemberRequestAndComplete() {
    testWidgets('ModalFlowMember request -> callback -> notifyCompleted updates listeners', (tester) async {
      final vm = _ModalVm();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewModelDispatcher(
              factory: () => vm,
              param: null,
              child: HookBuilder(
                builder: (context) {
                  final vm = context.useVM<_ModalVm>();

                  // Wire modal listener that completes immediately with a value
                  vm.modal.useModal((_) async => 'OK');

                  // Rebuild UI when modal member notifies
                  useListenable(vm.modal);

                  final text = vm.modal.isModalRequested
                      ? '<requested>'
                      : (vm.modal.result?.toString() ?? '<not requested>');

                  return Center(
                    child: Text(text, key: const ValueKey('modal_state')),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('modal_state')), findsOneWidget);
      expect(find.text('<not requested>'), findsOneWidget);

      // Request modal; listener will run and then complete with 'OK'
      final future = vm.modal.requestModal();
      await tester.pump();
      // While processing, it may show requested; settle to finish completion
      await tester.pumpAndSettle();

      expect(await future, equals('OK'));
      expect(vm.modal.result, equals('OK'));
      expect(find.text('OK'), findsOneWidget);
    });
  }

  void _modalFlowMemberDoubleRequestReturnsSameFuture() {
    testWidgets('ModalFlowMember reuses the same pending request (single callback invocation)', (tester) async {
      final vm = _ModalVm();

      // Build widget with a modal listener that completes after a small microtask
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: HookBuilder(
              builder: (context) {
                final vm = context.useVM<_ModalVm>();

                final calls = useState<int>(0);
                vm.modal.useModal((_) async {
                  // Count how many times the modal callback is invoked
                  calls.value++;
                  // Delay to keep the modal open momentarily
                  await Future<void>.delayed(Duration.zero);
                  return 'X';
                });

                // Still need to listen to the member so the hook attaches
                useListenable(vm.modal);

                return Text('calls=${calls.value}', key: const ValueKey('modal_calls'));
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('modal_calls')), findsOneWidget);

      final f1 = vm.modal.requestModal();
      final f2 = vm.modal.requestModal();

      await tester.pumpAndSettle();
      // Both futures should complete with the same result
      expect(await f1, equals('X'));
      expect(vm.modal.result, equals('X'));
      expect(await f2, equals('X'));
      // Ensure the modal callback was invoked only once
      expect(find.text('calls=1'), findsOneWidget);
    });
  }

  void _modalFlowMemberResetShouldClose() {
    testWidgets('ModalFlowMember.reset completes pending request with null and clears state', (tester) async {
      final vm = _ModalVm();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewModelDispatcher(
              factory: () => vm,
              param: null,
              child: HookBuilder(
                builder: (context) {
                  final vm = context.useVM<_ModalVm>();

                  // Provide onClose just to ensure no Navigator.pop is attempted
                  vm.modal.useModal((_) async => null, onClose: (_) {});

                  useListenable(vm.modal);

                  final text = 'requested=${vm.modal.isModalRequested}; result=${vm.modal.result}';
                  return Text(text, key: const ValueKey('modal_info'));
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('modal_info')), findsOneWidget);
      expect(find.textContaining('requested=false'), findsOneWidget);

      final future = vm.modal.requestModal();
      await tester.pump();

      expect(vm.modal.isModalRequested, isTrue);

      // Reset should trigger onClose and complete the future with null
      vm.modal.reset();
      // Allow the scheduled listener (onClose) to run and the widget to rebuild
      await tester.pumpAndSettle();

      expect(await future, isNull);
      expect(vm.modal.isModalRequested, isFalse);
      expect(find.textContaining('requested=false'), findsOneWidget);
      expect(find.textContaining('result=null'), findsOneWidget);
    });
  }
}

class _NavigationVm extends ViewModel {
  // Use nullable type to allow initial null safely
  late final navigation = NavigationMember<String?>();

  @override
  List<ViewModelMember> get members => [navigation];
}

class _ModalVm extends ViewModel {
  late final modal = ModalFlowMember<String>();

  @override
  List<ViewModelMember> get members => [modal];
}
