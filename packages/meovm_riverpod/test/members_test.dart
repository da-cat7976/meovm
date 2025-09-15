import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/src/core/dispatcher.dart';
import 'package:meovm_riverpod/src/members/riverpod.dart';

void main() {
  RiverpodMembersTests().run();
}

class RiverpodMembersTests {
  void run() {
    group('Riverpod members', () {
      _riverpodDataMember();
      _riverpodActionGroup();
    });
  }

  void _riverpodDataMember() {
    testWidgets('RiverpodDataMember reflects provider and updates dependents',
            (tester) async {
          final vm = _RiverpodVm();

          await tester.pumpWidget(
            ProviderScope(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: RiverpodVmDispatcher<_RiverpodVm, _Param>(
                  factory: () => vm,
                  param: const _Param(),
                  child: Builder(
                    builder: (context) {
                      final vm = context.useVM<_RiverpodVm>();
                      final data = vm.data;
                      final dataPlusOne = vm.dataPlusOne;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // shows provider value
                          data.build(
                            builder: (_, _) => Text(
                              data.data.toString(),
                              key: const ValueKey('data'),
                            ),
                          ),
                          // shows dependent value
                          dataPlusOne.build(
                            builder: (_, _) => Text(
                              dataPlusOne.data.toString(),
                              key: const ValueKey('data_plus_one'),
                            ),
                          ),

                          // button that updates the underlying provider via ref
                          Consumer(
                            builder: (context, ref, _) {
                              return ElevatedButton(
                                key: const ValueKey('inc_provider'),
                                onPressed: () {
                                  final notifier =
                                  ref.read(_counterProvider.notifier);
                                  notifier.state++;
                                },
                                child: const Text('inc provider'),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          // initial values: counter=1, plus one = 2
          expect(find.byKey(const ValueKey('data')), findsOneWidget);
          expect(find.text('1'), findsOneWidget);
          expect(find.byKey(const ValueKey('data_plus_one')), findsOneWidget);
          expect(find.text('2'), findsOneWidget);

          // increment the provider
          await tester.tap(find.byKey(const ValueKey('inc_provider')));
          await tester.pump();

          // updated values: counter=2, plus one = 3
          expect(find.text('2'), findsOneWidget);
          expect(find.text('3'), findsOneWidget);
        });
  }

  void _riverpodActionGroup() {
    testWidgets('RiverpodActionGroup exposes notifier and state', (tester) async {
      final vm = _RiverpodVm();

      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RiverpodVmDispatcher<_RiverpodVm, _Param>(
              factory: () => vm,
              param: const _Param(),
              child: Builder(
                builder: (context) {
                  final vm = context.useVM<_RiverpodVm>();
                  final group = vm.group;

                  String groupText() {
                    return group.data.when(
                      data: (value) => value.toString(),
                      error: (e, s) => 'error',
                      loading: () => 'loading',
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      group.build(
                        builder: (_, _) => Text(
                          groupText(),
                          key: const ValueKey('group'),
                        ),
                      ),
                      ElevatedButton(
                        key: const ValueKey('inc_group'),
                        onPressed: vm.incGroup,
                        child: const Text('inc group'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // The AsyncNotifier initializes to 1 (synchronously), so we expect '1'
      await tester.pump();
      expect(find.byKey(const ValueKey('group')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Trigger an action; it sets loading, then increments to 2
      await tester.tap(find.byKey(const ValueKey('inc_group')));
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);

      // Wait for async work to complete
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('2'), findsOneWidget);
    });
  }
}

// ----- Test fixtures -----

// A simple state provider used by RiverpodDataMember
final _counterProvider = StateProvider<int>((ref) => 1);

// A simple AsyncNotifier "action group"
class _CounterGroup extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() {
    // Start with a value of 1 synchronously
    return 1;
  }

  Future<void> increment() async {
    state = const AsyncLoading();
    // simulate async work
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final current = state.valueOrNull ?? 0;
    state = AsyncData(current + 1);
  }
}

final _counterGroupProvider =
AsyncNotifierProvider<_CounterGroup, int>(_CounterGroup.new);

// Minimal param to satisfy RiverpodVmDispatcher generic constraints
final class _Param extends ViewModelParameter {
  const _Param();

  @override
  bool shouldUpdateDependencies(ViewModelParameter? oldParam) => false;
}

// ViewModel under test
class _RiverpodVm extends ViewModel<_Param> {
  // Provides data from a Riverpod provider
  late final data = RiverpodDataMember<int>(
        (ref, _) => ref.watch(_counterProvider),
    debugName: 'data',
  );

  // A dependent member to verify dependency updates (like in value_test)
  late final dataPlusOne = ValueMember<int>(
    resolver: (_) => data.data + 1,
    debugName: 'dataPlusOne',
  );

  // Action group: exposes notifier and state
  late final group = RiverpodActionGroup<_CounterGroup, AsyncValue<int>>(
        (ref, _) => (
    group: ref.watch(_counterGroupProvider.notifier),
    state: ref.watch(_counterGroupProvider),
    ),
    debugName: 'group',
  );

  @override
  List<ViewModelMember> get members => [data, dataPlusOne, group];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(data, dataPlusOne);
  }

  // Convenience method for the test button to call the notifier
  void incGroup() {
    group.notifier.increment();
  }
}