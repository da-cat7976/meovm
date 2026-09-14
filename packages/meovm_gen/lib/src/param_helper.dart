import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:meovm_gen/src/type_parameters.dart';
import 'package:source_gen/source_gen.dart';

class ParamMixinGeneratorHelper {
  final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  final _vmChecker = TypeChecker.typeNamed(MeovmAutoVm, inPackage: 'meovm_api');

  final _memberChecker = TypeChecker.typeNamed(
    MeovmAutoVmMember,
    inPackage: 'meovm_api',
  );

  bool canAccept(ClassElement element) {
    return _acceptedType.isAssignableFromType(element.thisType);
  }

  Future<String> generate(
    ClassElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final libElement = element.library;
    final library = await libElement.session.getResolvedLibraryByElement(
      libElement,
    );
    if (library is! ResolvedLibraryResult) return '';

    final checked = _getChecked(element).toList();

    final shouldUpdate = _buildShouldUpdate(element, checked);

    final mixin = Mixin(
      (b) => b
        ..name = '_\$${element.name}'
        ..types.addAll(buildTypeParameters(element, library))
        ..on = refer('ViewModelParameter')
        ..methods.addAll([..._buildDefinitions(checked), shouldUpdate])
        ..base = true,
    );

    return _formatter.format('${mixin.accept(DartEmitter())}');
  }

  Iterable<FieldElement> _getChecked(ClassElement element) sync* {
    final typeSystem = element.library.typeSystem;
    for (final field in element.fields) {
      if (field.isOriginGetterSetter) continue;
      if (_isAssignableFromTypeOrBound(_vmChecker, field.type, typeSystem) ||
          _isAssignableFromTypeOrBound(
            _memberChecker,
            field.type,
            typeSystem,
          )) {
        yield field;
      }
    }
  }

  bool _isAssignableFromTypeOrBound(
    TypeChecker checker,
    DartType type,
    TypeSystem typeSystem,
  ) {
    if (checker.isAssignableFromType(type)) return true;

    final interface = resolveInterfaceType(type, typeSystem);
    return interface != null &&
        checker.isAssignableFromType(typeSystem.promoteToNonNull(interface));
  }

  Iterable<Method> _buildDefinitions(Iterable<FieldElement> members) sync* {
    for (final member in members) {
      yield Method(
        (b) => b
          ..name = member.name
          ..returns = refer(member.type.getDisplayString())
          ..type = MethodType.getter,
      );
    }
  }

  Method _buildShouldUpdate(ClassElement element, List<FieldElement> checked) {
    final body = Block((b) {
      if (checked.isEmpty) {
        b.addExpression(literalFalse.returned);
        return;
      }

      final first = checked.first;
      Expression exp = refer('oldParam')
          .nullSafeProperty(first.name!)
          .notEqualTo(refer(first.name!));
      for (final field in checked.skip(1)) {
        exp = exp.or(
          refer('oldParam')
              .nullSafeProperty(field.name!)
              .notEqualTo(refer(field.name!)),
        );
      }

      b.addExpression(exp.returned);
    });

    return Method(
      (b) => b
        ..name = 'shouldUpdateDependencies'
        ..returns = refer('bool')
        ..annotations.add(refer('override'))
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'oldParam'
              ..type = refer('${element.name}${typeParameterUsage(element)}?')
              ..covariant = true,
          ),
        )
        ..body = body,
    );
  }

  static final _acceptedType = TypeChecker.typeNamed(
    MeovmAutoVmParameter,
    inPackage: 'meovm_api',
  );
}
