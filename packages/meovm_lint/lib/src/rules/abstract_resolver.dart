import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:source_gen/source_gen.dart';

class AbstractResolverRule extends AnalysisRule {
  AbstractResolverRule()
    : super(
        name: code.lowerCaseName,
        description: 'Avoid abstract resolvers in generated view models.',
      );

  static const code = LintCode(
    'meovm_abstract_resolver',
    'Avoid using abstract resolvers. No dependencies will be generated.',
    severity: DiagnosticSeverity.WARNING,
  );

  static const _classChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVm',
    inPackage: 'meovm_api',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addFieldDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AbstractResolverRule rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    final classElement = enclosingClass?.declaredFragment?.element;
    if (classElement == null ||
        !AbstractResolverRule._classChecker.isAssignableFrom(classElement)) {
      return;
    }

    final visitor = _AbstractResolverVisitor();
    node.visitChildren(visitor);
    if (visitor.visitedAbstractMethod) rule.reportAtNode(node);
  }
}

class _AbstractResolverVisitor extends RecursiveAstVisitor<void> {
  bool visitedAbstractMethod = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element is MethodElement && element.isAbstract) {
      visitedAbstractMethod = true;
    }
    super.visitSimpleIdentifier(node);
  }
}
