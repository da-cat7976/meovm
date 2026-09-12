import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:meovm_lint/src/rules/common/member.dart';
import 'package:source_gen/source_gen.dart';

class ExternalModificationRule extends MemberAccessRule {
  ExternalModificationRule()
    : super(
        code: _code,
        description: 'Prevents modification of internal ViewModel members.',
      );

  @override
  bool checkElement(Element? element, AstNode node) {
    if (element == null || !_annotationChecker.hasAnnotationOf(element)) {
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
    'meovm_external_modification',
    'ViewModel members should not be modified outside the ViewModel. Add a '
        'corresponding method to the ViewModel to modify this member.',
    severity: DiagnosticSeverity.WARNING,
  );

  static const _annotationChecker = TypeChecker.typeNamedLiterally(
    '_MeovmInternal',
    inPackage: 'meovm_api',
  );

  static const _vmChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVm',
    inPackage: 'meovm_api',
  );

  static const _memberChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVmMember',
    inPackage: 'meovm_api',
  );

  static final _classCheckers = [_vmChecker, _memberChecker];
}
