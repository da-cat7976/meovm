import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';

void main() {
  ScopeRetrievalTests().run();
}

class ScopeRetrievalTests {
  void run() {
    group('ViewModel scope retrieval', () {
      _supertypeRetrievalWithScope();
      _supertypeRetrievalWithoutDispatcherScope();
      _concreteRetrievalWithoutScope();
      _paramSupertypeRetrievalWithScope();
      _paramSupertypeRetrievalWithoutDispatcherScope();
      _nestedScopesRetrieval();
      _sameTypeNearestScopedRetrieval();
    });
  }

  void _supertypeRetrievalWithScope() {
    testWidgets('Retrieves VM by supertype when dispatcher has scope: true', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _ScopedHostWidget(scopeOnDispatcher: true),
        ),
      );

      expect(find.byKey(const ValueKey('no_scope_result')), findsOneWidget);
      expect(find.text('null'), findsOneWidget);

      expect(find.byKey(const ValueKey('with_scope_result')), findsOneWidget);
      expect(find.text('not null'), findsOneWidget);
    });
  }

  void _supertypeRetrievalWithoutDispatcherScope() {
    testWidgets('Does not retrieve VM by supertype when dispatcher has scope: false', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _ScopedHostWidget(scopeOnDispatcher: false),
        ),
      );

      // Without ViewModelScope provided by dispatcher, supertype lookup should fail
      expect(find.byKey(const ValueKey('with_scope_result')), findsOneWidget);
      expect(find.text('null'), findsNWidgets(2)); // both no-scope and with-scope paths are null
    });
  }

  void _concreteRetrievalWithoutScope() {
    testWidgets('Direct retrieval by concrete type works without scope', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher<_ConcreteVm, _BaseParam?>(
            factory: _ConcreteVm.new,
            param: null,
            scope: false,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_ConcreteVm>();
                return Text(
                  vm.runtimeType.toString(),
                  key: const ValueKey('concrete_type_result'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('concrete_type_result')), findsOneWidget);
      expect(find.text('_ConcreteVm'), findsOneWidget);
    });
  }

  void _paramSupertypeRetrievalWithScope() {
    testWidgets('Retrieves Param by supertype when dispatcher has scope: true', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher<_ConcreteVm, _BaseParam?>(
            factory: _ConcreteVm.new,
            param: _ConcreteParam(),
            scope: true,
            child: Builder(
              builder: (context) {
                final noScope = context.useParamOrNull<_BaseParam>(scope: false);
                final withScope = context.useParamOrNull<_BaseParam>(scope: true);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      noScope == null ? 'null' : 'not null',
                      key: const ValueKey('param_no_scope_result'),
                    ),
                    Text(
                      withScope == null ? 'null' : 'not null',
                      key: const ValueKey('param_with_scope_result'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('param_no_scope_result')), findsOneWidget);
      expect(find.text('null'), findsOneWidget);

      expect(find.byKey(const ValueKey('param_with_scope_result')), findsOneWidget);
      expect(find.text('not null'), findsOneWidget);
    });
  }

  void _paramSupertypeRetrievalWithoutDispatcherScope() {
    testWidgets('Does not retrieve Param by supertype when dispatcher has scope: false', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher<_ConcreteVm, _BaseParam?>(
            factory: _ConcreteVm.new,
            param: _ConcreteParam(),
            scope: false,
            child: Builder(
              builder: (context) {
                final noScope = context.useParamOrNull<_BaseParam>(scope: false);
                final withScope = context.useParamOrNull<_BaseParam>(scope: true);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      noScope == null ? 'null' : 'not null',
                      key: const ValueKey('param_no_scope_result'),
                    ),
                    Text(
                      withScope == null ? 'null' : 'not null',
                      key: const ValueKey('param_with_scope_result'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('param_with_scope_result')), findsOneWidget);
      expect(find.text('null'), findsNWidgets(2));
    });
  }

  void _nestedScopesRetrieval() {
    testWidgets('Nested scopes retrieve correct VMs and Params from nearest scope', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher<_ConcreteVmA, _BaseParamA?>(
            factory: _ConcreteVmA.new,
            param: _ConcreteParamA(),
            scope: true,
            child: ViewModelDispatcher<_ConcreteVmB, _BaseParamB?>(
              factory: _ConcreteVmB.new,
              param: _ConcreteParamB(),
              scope: true,
              child: Builder(
                builder: (context) {
                  final vmA = context.useVmOrNull<_BaseVmA>(scope: true);
                  final vmB = context.useVmOrNull<_BaseVmB>(scope: true);
                  final paramA = context.useParamOrNull<_BaseParamA>(scope: true);
                  final paramB = context.useParamOrNull<_BaseParamB>(scope: true);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vmA.runtimeType.toString(), key: const ValueKey('nested_vm_a')),
                      Text(vmB.runtimeType.toString(), key: const ValueKey('nested_vm_b')),
                      Text(paramA.runtimeType.toString(), key: const ValueKey('nested_param_a')),
                      Text(paramB.runtimeType.toString(), key: const ValueKey('nested_param_b')),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('nested_vm_a')), findsOneWidget);
      expect(find.text('_ConcreteVmA'), findsOneWidget);
      expect(find.byKey(const ValueKey('nested_vm_b')), findsOneWidget);
      expect(find.text('_ConcreteVmB'), findsOneWidget);
      expect(find.byKey(const ValueKey('nested_param_a')), findsOneWidget);
      expect(find.text('_ConcreteParamA'), findsOneWidget);
      expect(find.byKey(const ValueKey('nested_param_b')), findsOneWidget);
      expect(find.text('_ConcreteParamB'), findsOneWidget);
    });
  }

  void _sameTypeNearestScopedRetrieval() {
    testWidgets('Nearest scoped VM is used when same VM type is nested', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher<SomeVm, SomeParam>(
            factory: SomeVm.new,
            param: const SomeParam(1),
            scope: true,
            child: ViewModelDispatcher<SomeVm, SomeParam>(
              factory: SomeVm.new,
              param: const SomeParam(2),
              scope: true,
              child: Builder(
                builder: (context) {
                  final vm = context.useVM<SomeVm>(scope: true);
                  return Text(
                    '${vm.value.data}',
                    key: const ValueKey('scoped_value_result'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('scoped_value_result')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  }
}

class _ScopedHostWidget extends StatelessWidget {
  const _ScopedHostWidget({required this.scopeOnDispatcher});

  final bool scopeOnDispatcher;

  @override
  Widget build(BuildContext context) {
    return ViewModelDispatcher<_ConcreteVm, _BaseParam?>(
      factory: _ConcreteVm.new,
      param: null,
      scope: scopeOnDispatcher,
      child: Builder(
        builder: (context) {
          final noScope = context.useVmOrNull<_BaseVm>(scope: false);
          final withScope = context.useVmOrNull<_BaseVm>(scope: true);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                noScope == null ? 'null' : 'not null',
                key: const ValueKey('no_scope_result'),
              ),
              Text(
                withScope == null ? 'null' : 'not null',
                key: const ValueKey('with_scope_result'),
              ),
            ],
          );
        },
      ),
    );
  }
}

abstract class _BaseVm extends ViewModel<_BaseParam?> {}

class _ConcreteVm extends _BaseVm {
  @override
  List<ViewModelMember> get members => [];

  @override
  void setDependencies(ViewModelDependencySetter depend) {}
}

// Parameters hierarchy for tests
abstract base class _BaseParam extends ViewModelParameter {
  const _BaseParam();

  @override
  bool shouldUpdateDependencies(ViewModelParameter? oldParam) => false;
}

final class _ConcreteParam extends _BaseParam {
  const _ConcreteParam();
}

// Nested scopes test classes
abstract class _BaseVmA extends ViewModel<_BaseParamA?> {}

class _ConcreteVmA extends _BaseVmA {
  @override
  List<ViewModelMember> get members => [];

  @override
  void setDependencies(ViewModelDependencySetter depend) {}
}

abstract class _BaseVmB extends ViewModel<_BaseParamB?> {}

class _ConcreteVmB extends _BaseVmB {
  @override
  List<ViewModelMember> get members => [];

  @override
  void setDependencies(ViewModelDependencySetter depend) {}
}

abstract base class _BaseParamA extends ViewModelParameter {
  const _BaseParamA();

  @override
  bool shouldUpdateDependencies(ViewModelParameter? oldParam) => false;
}

final class _ConcreteParamA extends _BaseParamA {
  const _ConcreteParamA();
}

abstract base class _BaseParamB extends ViewModelParameter {
  const _BaseParamB();

  @override
  bool shouldUpdateDependencies(ViewModelParameter? oldParam) => false;
}

final class _ConcreteParamB extends _BaseParamB {
  const _ConcreteParamB();
}

// --- Same-type nested scope test helpers ---

final class SomeParam extends ViewModelParameter {
  const SomeParam(this.v);

  final int v;

  @override
  bool shouldUpdateDependencies(ViewModelParameter? oldParam) => true;
}

class SomeVm extends ViewModel<SomeParam> {
  late final value = member.value<int>(resolver: (_) => param.v);

  @override
  List<ViewModelMember> get members => [value];

  @override
  void setDependencies(ViewModelDependencySetter depend) {}
}
