import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExternalModificationRule extends DartLintRule {
  ExternalModificationRule() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry
      ..addMethodInvocation((node) {
        final element = node.methodName.element;
        final shouldWarn = _checkElement(element, node);
        if (!shouldWarn) return;

        reporter.atNode(node.methodName, _code);
      })
      ..addPropertyAccess((node) {
        final element = node.propertyName.element;
        final shouldWarn = switch (element) {
          GetterElement(isSynthetic: false) => _checkElement(element, node),
          GetterElement(variable3: final PropertyInducingElement2 variable) =>
            _checkElement(variable, node),
          _ => false,
        };
        if (!shouldWarn) return;

        reporter.atNode(node.propertyName, _code);
      })
      ..addPrefixedIdentifier((node) {
        final element = node.element;
        final shouldWarn = _checkElement(element, node);
        if (!shouldWarn) return;

        reporter.atNode(node, _code);
      })
      ..addAssignmentExpression((node) {
        // Handle setters and compound assignments, e.g.:
        //   obj.prop = value;           => use writeElement2 (setter)
        //   obj.prop += value;          => use element (operator method)
        final isSimpleEq = node.operator.type == TokenType.EQ;
        final element = isSimpleEq ? node.writeElement2 : node.element;

        final shouldWarn = _checkElement(element, node);
        if (!shouldWarn) return;

        // Report on the identifier being assigned to, when available.
        final lhs = node.leftHandSide;
        SimpleIdentifier? id;
        if (lhs is PropertyAccess) {
          id = lhs.propertyName;
        } else if (lhs is PrefixedIdentifier) {
          id = lhs.identifier;
        } else if (lhs is SimpleIdentifier) {
          id = lhs;
        }

        reporter.atNode(id ?? node, _code);
      });
  }

  bool _checkElement(Element2? element, AstNode node) {
    if (element is! Annotatable) return false;

    if (!_annotationChecker.hasAnnotationOf(element as Annotatable)) {
      return false;
    }

    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    final classElement = enclosingClass?.declaredFragment?.element;
    if (classElement != null && _classChecker.isAssignableFrom(classElement)) {
      return false;
    }

    return true;
  }

  static const _code = LintCode(
    name: 'meovm_external_modification',
    problemMessage:
        'ViewModel member should not be modified outside ViewModel.\n'
        'Add corresponding method to ViewModel to modify this member.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static final _annotationChecker = TypeChecker.fromName(
    '_MeovmInternal',
    packageName: 'meovm_api',
  );

  static final _classChecker = TypeChecker.fromName(
    'MeovmAutoVm',
    packageName: 'meovm_api',
  );
}
