import 'package:meovm_lint/src/rules/external_modification.dart';
import 'package:test/test.dart';

import 'support/lint_test_helper.dart';

const _declarations = '''
import 'package:meovm_api/meovm_api.dart';

class Vm implements MeovmAutoVm<MeovmAutoVmParameter?> {
  int _value = 0;

  int get value => _value;

  @meovmInternal
  set value(int next) => _value = next;

  @meovmInternal
  int field = 0;
}
''';

void main() {
  group('external writes', () {
    for (final target in ['vm.value', '(vm).value', 'vm..value']) {
      for (final operator in ['= 1', '+= 1', '-= 1', '*= 2', '++', '--']) {
        if (target == 'vm..value' && ['++', '--'].contains(operator)) {
          continue;
        }

        test('$target $operator reports exactly once', () async {
          final source =
              '''
$_declarations
void update(Vm vm) {
  $target $operator;
}
''';

          final diagnostics = await lintDiagnostics(
            source,
            ExternalModificationRule(),
          );

          expect(diagnostics, hasLength(1));
          expect(
            diagnostics.single.diagnosticCode.lowerCaseName,
            'meovm_external_modification',
          );
          expect(diagnostics.single.offset, source.lastIndexOf('value'));
          expect(diagnostics.single.length, 'value'.length);
        });
      }
    }

    for (final target in ['vm.value', '(vm).value']) {
      for (final operator in ['++', '--']) {
        test('$operator$target reports exactly once', () async {
          final source =
              '''
$_declarations
void update(Vm vm) {
  $operator$target;
}
''';

          final diagnostics = await lintDiagnostics(
            source,
            ExternalModificationRule(),
          );

          expect(diagnostics, hasLength(1));
          expect(diagnostics.single.offset, source.lastIndexOf('value'));
          expect(diagnostics.single.length, 'value'.length);
        });
      }
    }

    test('annotated fields report once for each write', () async {
      final diagnostics = await lintDiagnostics('''
$_declarations
void update(Vm vm) {
  vm.field = 1;
  vm.field += 1;
  vm.field -= 1;
  vm.field++;
  vm.field--;
  ++vm.field;
  --vm.field;
}
''', ExternalModificationRule());

      expect(diagnostics, hasLength(7));
      expect(
        diagnostics.map((diagnostic) => diagnostic.offset).toSet(),
        hasLength(7),
      );
    });

    test('compound writes still check an internal getter', () async {
      final diagnostics = await lintDiagnostics('''
import 'package:meovm_api/meovm_api.dart';

class Vm {
  int _value = 0;

  @meovmInternal
  int get value => _value;

  set value(int next) => _value = next;
}

void update(Vm vm) {
  vm.value += 1;
  vm.value++;
  --vm.value;
}
''', ExternalModificationRule());

      expect(diagnostics, hasLength(3));
      expect(
        diagnostics.map((diagnostic) => diagnostic.offset).toSet(),
        hasLength(3),
      );
    });

    test(
      'ordinary reads and non-mutating unary expressions are allowed',
      () async {
        final diagnostics = await lintDiagnostics('''
$_declarations
int read(Vm vm) {
  final first = vm.value;
  final second = (vm).value;
  return first + second + -vm.value + ~vm.value;
}
''', ExternalModificationRule());

        expect(diagnostics, isEmpty);
      },
    );

    test(
      'internal writes in VM classes and member mixins are allowed',
      () async {
        final diagnostics = await lintDiagnostics('''
$_declarations
class InternalVm extends Vm {
  void update() {
    value = 1;
    value += 1;
    this.value -= 1;
    value++;
    --value;
    field++;
  }
}

mixin InternalMember implements MeovmAutoVmMember {
  void update(Vm vm) {
    vm.value += 1;
    ++vm.value;
    vm.field--;
  }
}
''', ExternalModificationRule());

        expect(diagnostics, isEmpty);
      },
    );
  });
}
