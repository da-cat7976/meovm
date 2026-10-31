import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';

void main() {
  testWidgets('debounces member listeners, dependents and builders', (
    tester,
  ) async {
    final vm = _EditableTextVm(const Duration(milliseconds: 300));
    await _mount(tester, vm);

    final controllerValues = <String>[];
    final memberValues = <String>[];
    final dependentValues = <String>[];
    vm.query.controller.addListener(
      () => controllerValues.add(vm.query.controller.text),
    );
    vm.query.addListener(() => memberValues.add(vm.query.controller.text));
    vm.result.addListener(() => dependentValues.add(vm.result.data));

    vm.query.controller.text = 'a';
    await tester.pump(const Duration(milliseconds: 100));
    vm.query.controller.text = 'ab';
    await tester.pump(const Duration(milliseconds: 100));
    vm.query.controller.text = 'abc';

    expect(controllerValues, ['a', 'ab', 'abc']);
    expect(vm.query.controller.text, 'abc');
    expect(memberValues, isEmpty);
    expect(dependentValues, isEmpty);
    expect(vm.result.data, '');

    await tester.pump(const Duration(milliseconds: 299));

    expect(memberValues, isEmpty);
    expect(dependentValues, isEmpty);
    expect(find.text('abc'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));

    expect(memberValues, ['abc']);
    expect(dependentValues, ['abc']);
    expect(vm.result.data, 'abc');
    expect(find.text('abc'), findsOneWidget);

    vm.query.controller.text = 'next';
    await tester.pump(const Duration(milliseconds: 300));

    expect(memberValues, ['abc', 'next']);
    expect(dependentValues, ['abc', 'next']);
  });

  testWidgets('zero duration notifies members synchronously', (tester) async {
    final vm = _EditableTextVm(Duration.zero);
    await _mount(tester, vm);

    final values = <String>[];
    vm.query.addListener(() => values.add(vm.query.controller.text));

    vm.query.controller.text = 'a';
    expect(values, ['a']);
    expect(vm.result.data, 'a');

    vm.query.controller.text = 'ab';
    expect(values, ['a', 'ab']);
    expect(vm.result.data, 'ab');
  });

  testWidgets('selection and composing changes stay immediate on controller', (
    tester,
  ) async {
    final vm = _EditableTextVm(const Duration(milliseconds: 300));
    await _mount(tester, vm);

    final controllerValues = <TextEditingValue>[];
    final memberValues = <TextEditingValue>[];
    vm.query.controller.addListener(
      () => controllerValues.add(vm.query.controller.value),
    );
    vm.query.addListener(() => memberValues.add(vm.query.controller.value));

    vm.query.controller.text = 'abc';
    await tester.pump(const Duration(milliseconds: 100));
    vm.query.controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump(const Duration(milliseconds: 100));
    final value = vm.query.controller.value.copyWith(
      composing: const TextRange(start: 0, end: 2),
    );
    vm.query.controller.value = value;

    expect(vm.query.controller.value, value);
    expect(controllerValues, hasLength(3));
    expect(controllerValues.last, value);
    expect(memberValues, isEmpty);

    await tester.pump(const Duration(milliseconds: 299));
    expect(memberValues, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(memberValues, [value]);
  });

  testWidgets('removed listener does not receive pending notification', (
    tester,
  ) async {
    final vm = _EditableTextVm(const Duration(milliseconds: 300));
    await _mount(tester, vm);

    var removedCalls = 0;
    final retainedValues = <String>[];
    void listener() => removedCalls++;
    vm.query.addListener(listener);
    vm.query.addListener(() => retainedValues.add(vm.query.controller.text));

    vm.query.controller.text = 'pending';
    await tester.pump(const Duration(milliseconds: 100));
    vm.query.removeListener(listener);
    await tester.pump(const Duration(milliseconds: 200));

    expect(removedCalls, 0);
    expect(retainedValues, ['pending']);
    expect(vm.result.data, 'pending');
  });

  testWidgets('disposal cancels pending notifications', (tester) async {
    final vm = _EditableTextVm(const Duration(milliseconds: 300));
    await _mount(tester, vm);

    var memberCalls = 0;
    var dependentCalls = 0;
    var disposeCalls = 0;
    vm.query.addListener(() => memberCalls++);
    vm.result.addListener(() => dependentCalls++);
    vm.query.addDisposeListener((_) => disposeCalls++);

    vm.query.controller.text = 'pending';
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));

    expect(vm.state, ViewModelState.disposed);
    expect(disposeCalls, 1);
    expect(memberCalls, 0);
    expect(dependentCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(WidgetTester tester, _EditableTextVm vm) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ViewModelDispatcher(
        factory: () => vm,
        param: null,
        child: vm.query.build(
          builder: (_, _) => Text(vm.query.controller.text),
        ),
      ),
    ),
  );
}

class _EditableTextVm extends ViewModel {
  _EditableTextVm(this.debounce);

  final Duration debounce;

  late final query = member.editableText(debounce: debounce);

  late final result = member.value<String>(
    resolver: (_) => query.controller.text,
  );

  @override
  List<ViewModelMember> get members => [query, result];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(query, result);
  }
}
