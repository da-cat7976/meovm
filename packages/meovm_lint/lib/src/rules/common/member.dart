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
      ..addAssignmentExpression(this, visitor)
      ..addPrefixExpression(this, visitor)
      ..addPostfixExpression(this, visitor);
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
    if (_isWriteTarget(node)) return;

    final element = node.propertyName.element;
    final shouldWarn = switch (element) {
      MethodElement() => rule.checkElement(element, node),
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
    if (_isWriteTarget(node)) return;

    if (rule.checkElement(node.element, node)) rule.reportAtNode(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _checkWrite(node.writeElement, node.readElement, node.leftHandSide, node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (!_isIncrementOrDecrement(node.operator)) return;

    _checkWrite(node.writeElement, node.readElement, node.operand, node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkWrite(node.writeElement, node.readElement, node.operand, node);
  }

  bool _isWriteTarget(Expression node) {
    final parent = node.parent;

    return switch (parent) {
      AssignmentExpression(:final leftHandSide) => identical(
        leftHandSide,
        node,
      ),
      PrefixExpression(:final operand, :final operator) =>
        identical(operand, node) && _isIncrementOrDecrement(operator),
      PostfixExpression(:final operand) => identical(operand, node),
      _ => false,
    };
  }

  bool _isIncrementOrDecrement(Token operator) =>
      operator.type == TokenType.PLUS_PLUS ||
      operator.type == TokenType.MINUS_MINUS;

  void _checkWrite(
    Element? element,
    Element? readElement,
    Expression target,
    AstNode node,
  ) {
    if (element case SetterElement(
      isOriginDeclaration: false,
      variable: final PropertyInducingElement variable,
    )) {
      element = variable;
    }

    if (!rule.checkElement(element, node) &&
        !rule.checkElement(readElement, node)) {
      return;
    }

    final identifier = switch (target) {
      PropertyAccess(:final propertyName) => propertyName,
      PrefixedIdentifier(:final identifier) => identifier,
      SimpleIdentifier() => target,
      _ => null,
    };
    rule.reportAtNode(identifier ?? node);
  }
}
