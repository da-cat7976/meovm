import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class MemberAccessRule extends DartLintRule {
  MemberAccessRule({required super.code});

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) {
    context.registry
      ..addMethodInvocation((node) {
        final element = node.methodName.element;
        final shouldWarn = checkElement(element, node);
        if (!shouldWarn) return;

        reporter.atNode(node.methodName, code);
      })
      ..addPropertyAccess((node) {
        final element = node.propertyName.element;
        final shouldWarn = switch (element) {
          GetterElement(isSynthetic: false) => checkElement(element, node),
          GetterElement(variable3: final PropertyInducingElement2 variable) =>
              checkElement(variable, node),
          _ => false,
        };
        if (!shouldWarn) return;

        reporter.atNode(node.propertyName, code);
      })
      ..addPrefixedIdentifier((node) {
        final element = node.element;
        final shouldWarn = checkElement(element, node);
        if (!shouldWarn) return;

        reporter.atNode(node, code);
      })
      ..addAssignmentExpression((node) {
        // Handle setters and compound assignments, e.g.:
        //   obj.prop = value;           => use writeElement2 (setter)
        //   obj.prop += value;          => use element (operator method)
        final isSimpleEq = node.operator.type == TokenType.EQ;
        final element = isSimpleEq ? node.writeElement2 : node.element;

        final shouldWarn = checkElement(element, node);
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

        reporter.atNode(id ?? node, code);
      });
  }

  bool checkElement(Element2? element, AstNode node);
}