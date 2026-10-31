import 'package:meovm_lint/src/rules/abstract_resolver.dart';
import 'package:test/test.dart';

import 'support/lint_test_helper.dart';

void main() {
  test('concrete closures can call abstract SDK methods', () async {
    final diagnostics = await lintDiagnostics('''
import 'package:meovm/meovm.dart';

abstract class DraftVm extends ViewModel {
  late final input = member.editableText();
  late final cleaned = member.value(
    resolver: (_) => input.controller.text.trim(),
  );
  late final uri = member.value<Uri>(initial: Uri.parse('https://example.com'));
  late final formatted = member.value(
    resolver: (_) => uri.data.toString(),
  );
}
''', AbstractResolverRule());

    expect(diagnostics, isEmpty);
  });

  test('concrete Riverpod closures can call WidgetRef.watch', () async {
    final diagnostics = await lintDiagnostics('''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/meovm_riverpod.dart';

final source = Provider<int>((ref) => 42);

abstract class DraftVm extends ViewModel {
  late final value = member.data((ref, _) => ref.watch(source));
}
''', AbstractResolverRule());

    expect(diagnostics, isEmpty);
  });

  test('concrete resolver tear-offs keep their dependencies', () async {
    final diagnostics = await lintDiagnostics('''
import 'package:meovm/meovm.dart';

abstract class DraftVm extends ViewModel {
  late final input = member.value<int>(initial: 1);
  late final value = member.value<int>(resolver: resolve);

  int resolve(int? previous) => input.data + 1;
}
''', AbstractResolverRule());

    expect(diagnostics, isEmpty);
  });

  for (final resolver in ['resolve', 'this.resolve', '(resolve)']) {
    test('reports the abstract resolver tear-off $resolver', () async {
      final field =
          'late final value = member.value<int>(resolver: $resolver);';
      final source =
          '''
import 'package:meovm/meovm.dart';

abstract class DraftVm extends ViewModel {
  $field

  int resolve(int? previous);
}
''';

      final diagnostics = await lintDiagnostics(source, AbstractResolverRule());

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.diagnosticCode, AbstractResolverRule.code);
      expect(diagnostics.single.offset, source.indexOf(field));
      expect(diagnostics.single.length, field.length);
    });
  }

  test('reports abstract positional Riverpod resolver tear-offs', () async {
    const field = 'late final value = member.data<int>(resolve);';
    const source =
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/meovm_riverpod.dart';

abstract class DraftVm extends ViewModel {
  $field

  int resolve(WidgetRef ref, int? previous);
}
''';

    final diagnostics = await lintDiagnostics(source, AbstractResolverRule());

    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.diagnosticCode, AbstractResolverRule.code);
    expect(diagnostics.single.offset, source.indexOf(field));
    expect(diagnostics.single.length, field.length);
  });

  test(
    'abstract methods outside resolver arguments are not resolvers',
    () async {
      final diagnostics = await lintDiagnostics('''
import 'package:meovm/meovm.dart';

abstract class DraftVm extends ViewModel {
  late final callback = resolve;
  late final value = member.value<int>(resolver: (_) => resolve(null));

  int resolve(int? previous);
}
''', AbstractResolverRule());

      expect(diagnostics, isEmpty);
    },
  );
}
