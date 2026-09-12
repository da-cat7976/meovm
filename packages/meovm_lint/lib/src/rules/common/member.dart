import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

abstract class MemberAccessRule extends AnalysisRule {
  MemberAccessRule({required LintCode code, required super.description})
    : _code = code,
      super(name: code.lowerCaseName);

  final LintCode _code;

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _MemberAccessVisitor(this);
    registry
      ..addMethodInvocation(this, visitor)
      ..addPropertyAccess(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addAssignmentExpression(this, visitor);
  }

  bool checkElement(Element? element, AstNode node);
}

class _MemberAccessVisitor extends SimpleAstVisitor<void> {
  _MemberAccessVisitor(this.rule);

  final MemberAccessRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (rule.checkElement(node.methodName.element, node)) {
      rule.reportAtNode(node.methodName);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final element = node.propertyName.element;
    final shouldWarn = switch (element) {
      GetterElement(isOriginDeclaration: true) => rule.checkElement(
        element,
        node,
      ),
      GetterElement(variable: final PropertyInducingElement variable) =>
        rule.checkElement(variable, node),
      _ => false,
    };
    if (shouldWarn) rule.reportAtNode(node.propertyName);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (rule.checkElement(node.element, node)) rule.reportAtNode(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final element = node.operator.type == TokenType.EQ
        ? node.writeElement
        : node.element;
    if (!rule.checkElement(element, node)) return;

    final lhs = node.leftHandSide;
    final identifier = switch (lhs) {
      PropertyAccess(:final propertyName) => propertyName,
      PrefixedIdentifier(:final identifier) => identifier,
      SimpleIdentifier() => lhs,
      _ => null,
    };
    rule.reportAtNode(identifier ?? node);
  }
}
