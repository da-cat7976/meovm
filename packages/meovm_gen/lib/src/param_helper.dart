import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen/source_gen.dart';

class ParamMixinGeneratorHelper {
  final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  final _vmChecker = TypeChecker.fromRuntime(MeovmAutoVm);

  final _memberChecker = TypeChecker.fromRuntime(MeovmAutoVmMember);

  bool canAccept(ClassElement element) {
    return _acceptedType.isAssignableFrom(element);
  }

  Future<String> generate(
    ClassElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final checked = _getChecked(element).toList();

    final shouldUpdate = _buildShouldUpdate(element, checked);

    final mixin = Mixin(
      (b) => b
        ..name = '_\$${element.name}'
        ..on = refer('ViewModelParameter')
        ..methods.addAll([..._buildDefinitions(checked), shouldUpdate])
        ..base = true,
    );

    return _formatter.format('${mixin.accept(DartEmitter())}');
  }

  Iterable<FieldElement> _getChecked(ClassElement element) sync* {
    for (final field in element.fields) {
      if (_vmChecker.isAssignableFromType(field.type)) {
        yield field;
      }

      if (_memberChecker.isAssignableFromType(field.type)) {
        yield field;
      }
    }
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
      Expression exp = refer(
        'oldParam.${first.name}',
      ).notEqualTo(refer(first.name));
      for (final field in checked.skip(1)) {
        exp = exp.or(
          refer('oldParam.${field.name}').notEqualTo(refer(field.name)),
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
              ..type = refer(element.name)
              ..covariant = true,
          ),
        )
        ..body = body,
    );
  }

  static final _acceptedType = TypeChecker.fromRuntime(MeovmAutoVmParameter);
}
