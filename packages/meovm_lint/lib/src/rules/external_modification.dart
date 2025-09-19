import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meovm_lint/src/rules/common/member.dart';

class ExternalModificationRule extends MemberAccessRule {
  ExternalModificationRule() : super(code: _code);

  @override
  bool checkElement(Element2? element, AstNode node) {
    if (element is! Annotatable) return false;

    if (!_annotationChecker.hasAnnotationOf(element as Annotatable)) {
      return false;
    }

    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    final classElement = enclosingClass?.declaredFragment?.element;

    final enclosingMixin = node.thisOrAncestorOfType<MixinDeclaration>();
    final mixinElement = enclosingMixin?.declaredFragment?.element;

    for (final checker in _classCheckers) {
      final inViewModelClass =
          classElement != null && checker.isAssignableFrom(classElement);
      final inViewModelMixin =
          mixinElement != null && checker.isAssignableFrom(mixinElement);

      if (inViewModelClass || inViewModelMixin) return false;
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

  static final _vmChecker = TypeChecker.fromName(
    'MeovmAutoVm',
    packageName: 'meovm_api',
  );

  static final _memberChecker = TypeChecker.fromName(
    'MeovmAutoVmMember',
    packageName: 'meovm_api',
  );

  static final _classCheckers = [_vmChecker, _memberChecker];
}
