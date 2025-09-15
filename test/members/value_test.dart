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
      _listMemberMutations();
      _setMemberMutations();
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

  void _listMemberMutations() {
    testWidgets('ListMember add/remove updates UI and dependents', (tester) async {
      final vm = _ListMemberVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_ListMemberVm>();
                final list = vm.list;
                final length = vm.length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    list.build(
                      builder: (_, __) => Text(
                        list.data.join(', '),
                        key: const ValueKey('list'),
                      ),
                    ),
                    length.build(
                      builder: (_, __) => Text(
                        length.data.toString(),
                        key: const ValueKey('list_length'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('list')), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));

      vm.list.add(2);
      await tester.pump();
      expect(find.text('1, 2'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      vm.list.remove(1);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  }

  void _setMemberMutations() {
    testWidgets('SetMember add/remove updates UI and dependents', (tester) async {
      final vm = _SetMemberVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_SetMemberVm>();
                final set = vm.set;
                final length = vm.length;

                String sortedSetString() {
                  final items = set.data.toList()..sort();
                  return items.join(', ');
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    set.build(
                      builder: (_, __) => Text(
                        sortedSetString(),
                        key: const ValueKey('set'),
                      ),
                    ),
                    length.build(
                      builder: (_, __) => Text(
                        length.data.toString(),
                        key: const ValueKey('set_length'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('set')), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));

      vm.set.add(2);
      await tester.pump();
      expect(find.text('1, 2'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      vm.set.remove(1);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
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

class _ListMemberVm extends ViewModel {
  late final list = ListMember<int>(initial: [1]);

  late final length = ValueMember<int>(resolver: (_) => list.data.length);

  @override
  List<ViewModelMember> get members => [list, length];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(list, length);
  }
}

class _SetMemberVm extends ViewModel {
  late final set = SetMember<int>(initial: {1});

  late final length = ValueMember<int>(resolver: (_) => set.data.length);

  @override
  List<ViewModelMember> get members => [set, length];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(set, length);
  }
}
