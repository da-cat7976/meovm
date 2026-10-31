import 'package:meovm_lint/src/rules/lifecycle_use.dart';
import 'package:test/test.dart';

import 'support/lint_test_helper.dart';

const _hierarchy = '''
import 'package:meovm_api/meovm_api.dart';

class BaseVm implements MeovmAutoVm<MeovmAutoVmParameter?> {
  @meovmLifecycle
  void update() {}
}

class ChildVm extends BaseVm {
  @override
  void update() { super.update(); }
}

class GrandchildVm extends ChildVm {
  @override
  void update() { super.update(); }
}
''';

void main() {
  test(
    'protects original and overridden lifecycle calls at every level',
    () async {
      const source =
          '''
$_hierarchy
void invoke(BaseVm base, ChildVm child, GrandchildVm grandchild) {
  base.update();
  child.update();
  grandchild.update();
}
''';
      final diagnostics = await lintDiagnostics(source, LifecycleAccessRule());

      expect(diagnostics, hasLength(3));
      expect(diagnostics.map((diagnostic) => diagnostic.offset), [
        source.indexOf('base.update') + 'base.'.length,
        source.indexOf('child.update') + 'child.'.length,
        source.indexOf('grandchild.update') + 'grandchild.'.length,
      ]);
      expect(
        diagnostics.map((diagnostic) => diagnostic.length),
        everyElement(6),
      );
    },
  );

  test('protects prefixed and parenthesized method tear-offs', () async {
    const source =
        '''
$_hierarchy
void capture(GrandchildVm vm) {
  final prefixed = vm.update;
  final parenthesized = (vm).update;
}
''';
    final diagnostics = await lintDiagnostics(source, LifecycleAccessRule());

    expect(diagnostics, hasLength(2));
    expect(
      diagnostics.map(
        (diagnostic) => source.substring(
          diagnostic.offset,
          diagnostic.offset + diagnostic.length,
        ),
      ),
      ['vm.update', 'update'],
    );
  });

  test(
    'allows super calls and lifecycle tear-offs within the view model',
    () async {
      const source =
          '''
$_hierarchy
class FinalVm extends GrandchildVm {
  @override
  void update() {
    super.update();
    final inherited = super.update;
    final own = this.update;
    final implicit = update;
  }
}
''';
      final diagnostics = await lintDiagnostics(source, LifecycleAccessRule());

      expect(diagnostics, isEmpty);
    },
  );

  test('does not restrict unrelated methods with the same name', () async {
    const source =
        '''
$_hierarchy
class Unrelated {
  void update() {}
}

void invoke(Unrelated value) {
  value.update();
  final callback = (value).update;
}
''';
    final diagnostics = await lintDiagnostics(source, LifecycleAccessRule());

    expect(diagnostics, isEmpty);
  });

  test('finds lifecycle metadata through implemented interfaces', () async {
    const source =
        '''
$_hierarchy
class Implementation implements ChildVm {
  @override
  void update() {}
}

void invoke(Implementation vm) {
  vm.update();
}
''';
    final diagnostics = await lintDiagnostics(source, LifecycleAccessRule());

    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.offset, source.indexOf('vm.update') + 3);
    expect(diagnostics.single.length, 6);
  });

  test('does not inherit lifecycle protection from static methods', () async {
    const source = '''
import 'package:meovm_api/meovm_api.dart';

class Base {
  @meovmLifecycle
  static void update() {}
}

class Child extends Base {
  void update() {}
}

void invoke(Child vm) {
  vm.update();
}
''';
    final diagnostics = await lintDiagnostics(source, LifecycleAccessRule());

    expect(diagnostics, isEmpty);
  });
}
