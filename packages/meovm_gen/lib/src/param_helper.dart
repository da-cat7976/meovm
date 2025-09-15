import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meovm_api/meovm_api.dart';
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

  bool canAccept(ClassElement2 element) {
    return _acceptedType.isAssignableFromType(element.thisType);
  }

  Future<String> generate(
    ClassElement2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final checked = _getChecked(element).toList();

    final shouldUpdate = _buildShouldUpdate(element, checked);

    final mixin = Mixin(
      (b) => b
        ..name = '_\$${element.name3}'
        ..on = refer('ViewModelParameter')
        ..methods.addAll([..._buildDefinitions(checked), shouldUpdate])
        ..base = true,
    );

    return _formatter.format('${mixin.accept(DartEmitter())}');
  }

  Iterable<FieldElement2> _getChecked(ClassElement2 element) sync* {
    for (final field in element.fields2) {
      if (_vmChecker.isAssignableFromType(field.type)) {
        yield field;
      }

      if (_memberChecker.isAssignableFromType(field.type)) {
        yield field;
      }
    }
  }

  Iterable<Method> _buildDefinitions(Iterable<FieldElement2> members) sync* {
    for (final member in members) {
      yield Method(
        (b) => b
          ..name = member.name3
          ..returns = refer(member.type.getDisplayString())
          ..type = MethodType.getter,
      );
    }
  }

  Method _buildShouldUpdate(
    ClassElement2 element,
    List<FieldElement2> checked,
  ) {
    final body = Block((b) {
      if (checked.isEmpty) {
        b.addExpression(literalFalse.returned);
        return;
      }

      final first = checked.first;
      Expression exp = refer(
        'oldParam',
      ).nullSafeProperty(first.name3!).notEqualTo(refer(first.name3!));
      for (final field in checked.skip(1)) {
        exp = exp.or(
          refer(
            'oldParam',
          ).nullSafeProperty(field.name3!).notEqualTo(refer(field.name3!)),
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
              ..type = refer('${element.name3}?')
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
