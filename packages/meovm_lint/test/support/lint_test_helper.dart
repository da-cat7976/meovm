// The analyzer's rule dispatcher is also used by analysis_server_plugin.
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:test/test.dart';

/// Resolves real Dart source before dispatching the rule's registered visitors.
/// Uses the workspace package configuration, including actual meovm annotations.
Future<List<Diagnostic>> lintDiagnostics(
  String source,
  AnalysisRule rule,
) async {
  final provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
  final path = provider.pathContext.join(
    Directory.current.path,
    'test',
    'lint_probe.dart',
  );
  provider.setOverlay(path, content: source, modificationStamp: 0);

  final collection = AnalysisContextCollection(
    includedPaths: [path],
    resourceProvider: provider,
  );

  try {
    final analysisContext = collection.contextFor(path);
    final result = await analysisContext.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      fail('Could not resolve lint fixture: $result');
    }

    expect(
      result.diagnostics.where(
        (diagnostic) =>
            diagnostic.diagnosticCode.severity == DiagnosticSeverity.ERROR,
      ),
      isEmpty,
      reason: 'Lint fixtures must resolve without compilation errors.',
    );

    final listener = RecordingDiagnosticListener();
    final reporter = DiagnosticReporter(
      listener,
      result.libraryElement.firstFragment.source,
    );
    final unit = RuleContextUnit(
      file: result.file,
      content: source,
      diagnosticReporter: reporter,
      unit: result.unit,
    );
    final context = RuleContextWithResolvedResults(
      [unit],
      unit,
      result.typeProvider,
      result.typeSystem,
      null,
    )..currentUnit = unit;
    final registry = RuleVisitorRegistryImpl(enableTiming: false);
    rule.reporter = reporter;
    rule.registerNodeProcessors(registry, context);

    result.unit.accept(
      AnalysisRuleVisitor(registry, shouldPropagateExceptions: true),
    );
    AnalysisRuleVisitor(registry).afterLibrary();

    return listener.diagnostics;
  } finally {
    await collection.dispose();
  }
}
