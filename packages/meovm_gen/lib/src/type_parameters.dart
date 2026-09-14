import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

Iterable<Reference> buildTypeParameters(ClassElement element) {
  return element.typeParameters.map((parameter) {
    final bound = parameter.bound;

    return TypeReference(
      (b) => b
        ..symbol = parameter.name
        ..bound = bound == null ? null : refer(bound.getDisplayString()),
    );
  });
}

String typeParameterUsage(ClassElement element) {
  if (element.typeParameters.isEmpty) return '';

  return '<${element.typeParameters.map((parameter) => parameter.name).join(', ')}>';
}
