import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:meovm_lint/src/rules/common/member.dart';
import 'package:source_gen/source_gen.dart';

class LifecycleAccessRule extends MemberAccessRule {
  LifecycleAccessRule()
    : super(
        code: _code,
        description: 'Restricts access to ViewModel lifecycle methods.',
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
      final isInClassDeclaration =
          classElement != null && checker.isAssignableFrom(classElement);
      final isInMixinDeclaration =
          mixinElement != null && checker.isAssignableFrom(mixinElement);

      if (isInClassDeclaration || isInMixinDeclaration) return false;
    }

    return true;
  }

  static const _annotationChecker = TypeChecker.typeNamedLiterally(
    '_MeovmLifecycle',
    inPackage: 'meovm_api',
  );

  static const _memberChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVmMember',
    inPackage: 'meovm_api',
  );

  static const _vmChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVm',
    inPackage: 'meovm_api',
  );

  static const _ownerChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVmOwner',
    inPackage: 'meovm_api',
  );

  static const _featureChecker = TypeChecker.typeNamedLiterally(
    'MeovmAutoVmFeature',
    inPackage: 'meovm_api',
  );

  static final _classCheckers = [
    _memberChecker,
    _vmChecker,
    _ownerChecker,
    _featureChecker,
  ];

  static const _code = LintCode(
    'meovm_invalid_lifecycle_access',
    'Do not access ViewModelMember\'s and ViewModel\'s lifecycle methods '
        'outside ViewModelMember, ViewModel, or ViewModelDispatcher.',
    severity: DiagnosticSeverity.WARNING,
  );
}
