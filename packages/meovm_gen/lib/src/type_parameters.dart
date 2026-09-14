import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

Iterable<Reference> buildTypeParameters(
  ClassElement element,
  ResolvedLibraryResult library,
) {
  final declaration = library.getFragmentDeclaration(element.firstFragment);
  final node = declaration?.node;
  if (node is! ClassDeclaration) return const [];

  return node.namePart.typeParameters?.typeParameters.map((parameter) {
        return TypeReference(
          (b) => b
            ..symbol = parameter.name.lexeme
            ..bound = parameter.bound == null
                ? null
                : refer(parameter.bound!.toSource()),
        );
      }) ??
      const [];
}

String typeParameterUsage(ClassElement element) {
  if (element.typeParameters.isEmpty) return '';

  return '<${element.typeParameters.map((parameter) => parameter.name).join(', ')}>';
}
