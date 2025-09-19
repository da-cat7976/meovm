import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meovm_lint/src/rules/common/member.dart';

class LifecycleAccessRule extends MemberAccessRule {
  LifecycleAccessRule() : super(code: _code);

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
      final isInClassDeclaration =
          classElement != null && checker.isAssignableFrom(classElement);
      final isInMixinDeclaration =
          mixinElement != null && checker.isAssignableFrom(mixinElement);

      if (isInClassDeclaration || isInMixinDeclaration) return false;
    }

    return true;
  }

  static final _annotationChecker = TypeChecker.fromName(
    '_MeovmLifecycle',
    packageName: 'meovm_api',
  );

  static final _memberChecker = TypeChecker.fromName(
    'MeovmAutoVmMember',
    packageName: 'meovm_api',
  );

  static final _vmChecker = TypeChecker.fromName(
    'MeovmAutoVm',
    packageName: 'meovm_api',
  );

  static final _ownerChecker = TypeChecker.fromName(
    'MeovmAutoVmOwner',
    packageName: 'meovm_api',
  );

  static final _featureChecker = TypeChecker.fromName(
    'MeovmAutoVmFeature',
    packageName: 'meovm_api',
  );

  static final _classCheckers = [
    _memberChecker,
    _vmChecker,
    _ownerChecker,
    _featureChecker,
  ];

  static const _code = LintCode(
    name: 'meovm_invalid_lifecycle_access',
    problemMessage:
        'Do not access ViewModelMember\'s and ViewModel\'s lifecycle methods '
        'outside of ViewModelMember, ViewModel & ViewModelDispatcher',
    errorSeverity: ErrorSeverity.WARNING,
  );
}
