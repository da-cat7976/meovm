import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';

void main() {
  ValueMembersTests().run();
}

class ValueMembersTests {
  void run() {
    group('Value members', () {
      _valueUpdate();
    });
  }

  void _valueUpdate() {
    testWidgets('Value update', (tester) async {
      final vm = _ValueMemberVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_ValueMemberVm>();
                final value = vm.value;
                final resolved = vm.resolved;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    value.build(
                      builder: (_, _) =>
                          Text(value.data.toString(), key: ValueKey('value')),
                    ),
                    resolved.build(
                      builder: (_, _) => Text(
                        resolved.data.toString(),
                        key: ValueKey('resolved'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      vm.value.data++;

      await tester.pump();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  }
}

class _ValueMemberVm extends ViewModel {
  late final value = ValueMember(initial: 1);

  late final resolved = ValueMember<int>(resolver: (_) => value.data + 1);

  @override
  List<ViewModelMember> get members => [value, resolved];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(value, resolved);
  }
}
