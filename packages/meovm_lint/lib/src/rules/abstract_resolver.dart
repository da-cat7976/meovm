import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AbstractResolverRule extends DartLintRule {
  AbstractResolverRule() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFieldDeclaration((node) {
      final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
      final classElement = enclosingClass?.declaredFragment?.element;
      if (classElement == null || !_classChecker.isAssignableFrom(classElement)) {
        return;
      }

      final visitor = _AbstractResolverVisitor();
      node.visitChildren(visitor);

      if (!visitor.visitedAbstractMethod) return;
      reporter.atNode(node, _code);
    });
  }

  static const _code = LintCode(
    name: 'meovm_abstract_resolver',
    problemMessage:
        'Avoid to use abstract resolvers.\n'
        'No dependencies will be generated.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static final _classChecker = TypeChecker.fromName(
    'MeovmAutoVm',
    packageName: 'meovm_api',
  );
}

class _AbstractResolverVisitor extends RecursiveAstVisitor<void> {
  bool _visitedAbstractMethod = false;

  bool get visitedAbstractMethod => _visitedAbstractMethod;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element is! MethodElement2) return super.visitSimpleIdentifier(node);
    _visitedAbstractMethod = _visitedAbstractMethod || element.isAbstract;
  }
}
