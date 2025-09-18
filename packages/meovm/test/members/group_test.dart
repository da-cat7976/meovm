import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';

void main() {
  MemberGroupTests().run();
}

class MemberGroupTests {
  void run() {
    group('MemberGroup', () {
      _initialValues();
      _updatesPropagateThroughGroup();
    });
  }

  void _initialValues() {
    testWidgets('Initial values reflect main + key', (tester) async {
      final vm = _GroupVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_GroupVm>();
                final m0 = vm.group[0];
                final m1 = vm.group[1];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    m0.build(
                      builder: (_, _) => Text(
                        m0.data.toString(),
                        key: const ValueKey('g0'),
                      ),
                    ),
                    m1.build(
                      builder: (_, _) => Text(
                        m1.data.toString(),
                        key: const ValueKey('g1'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // main = 0; group keys: 0,1 => values should be 0 and 1
      expect(find.byKey(const ValueKey('g0')), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  }

  void _updatesPropagateThroughGroup() {
    testWidgets('Values change after incrementing main (0,1) -> (1,2)', (tester) async {
      final vm = _GroupVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_GroupVm>();
                final m0 = vm.group[0];
                final m1 = vm.group[1];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    m0.build(
                      builder: (_, _) => Text(
                        m0.data.toString(),
                        key: const ValueKey('g0'),
                      ),
                    ),
                    m1.build(
                      builder: (_, _) => Text(
                        m1.data.toString(),
                        key: const ValueKey('g1'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initial assertions
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Act
      vm.increment();
      await tester.pump();

      // After increment: main = 1; values should be 1 and 2
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  }
}

class _GroupVm extends ViewModel {
  late final main = member.value<int>(initial: 0);

  late final group = member.memberGroup<int, ValueMember<int>>(
    keys: const [0, 1],
    builder: (key) => ValueMember<int>(
      resolver: (_) => main.data + key,
    ),
  );

  void increment() {
    main.data++;
  }

  @override
  List<ViewModelMember> get members => [
    main,
    group,
  ];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(main, group);
  }
}
