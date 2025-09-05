import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Block;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';
import 'package:source_gen/source_gen.dart';

class VmMixinGeneratorHelperOld {
  final ClassElement element;

  final ConstantReader annotation;

  final BuildStep buildStep;

  final DartFormatter formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  VmMixinGeneratorHelperOld({
    required this.element,
    required this.annotation,
    required this.buildStep,
  });

  Future<String> generate() async {
    final memberElements = _getMembers().toList();
    final dependencies = await _getDependencies(memberElements).toList();
    print(dependencies);

    final definitions = _buildMemberDefinitions(memberElements);
    final members = _buildMembersMethod(memberElements);
    // final setDependencies = _buildSetDependencies(dependencies);

    final mixin = Mixin(
      (b) => b
        ..name = '_\$${element.name}'
        ..on = refer('ViewModel')
        ..methods.addAll(
          [...definitions, members], // fmt
        ),
    );

    final emitter = DartEmitter();

    return formatter.format('${mixin.accept(emitter)}');
  }

  Iterable<FieldElement> _getMembers() sync* {
    for (final field in element.fields) {
      final type = field.type.element;
      if (type is! ClassElement) continue;
      final supertypes = type.allSupertypes;
      if (!supertypes.any((t) => t.name == _memberType)) continue;

      yield field;
    }
  }

  Stream<_MemberDependency> _getDependencies(
    List<FieldElement> members,
  ) async* {
    for (final member in members) {
      yield* _dependenciesOf(member, members);
    }
  }

  Stream<_MemberDependency> _dependenciesOf(FieldElement member, List<FieldElement> members) async* {
    print('Checking $member');
    if (!member.hasInitializer) return;

    final library = await member.session?.getResolvedLibraryByElement(member.library);
    if (library is! ResolvedLibraryResult) return;

    final declaration = library.getElementDeclaration(member);
    final node = declaration?.node;

    if (node is! VariableDeclaration) return;
    final initializer = node.initializer;
    if (initializer == null) return;

    final referenced = <Element?>{};
    final collector = _MemberDependencyCollector(current: member, members: members);
    initializer.visitChildren(collector);
  }

  Iterable<Method> _buildMemberDefinitions(
    Iterable<FieldElement> members,
  ) sync* {
    for (final member in members) {
      yield Method(
        (b) => b
          ..name = member.name
          ..returns = refer(member.type.getDisplayString())
          ..type = MethodType.getter,
      );
    }
  }

  Method _buildMembersMethod(Iterable<FieldElement> members) {
    final names = members.map((e) => e.name);

    return Method(
      (b) => b
        ..name = 'members'
        ..returns = refer('List<ViewModelMember>')
        ..type = MethodType.getter
        ..annotations.add(refer('override'))
        ..body = Block(
          (b) => b.addExpression(literalList(names.map(refer)).returned),
        ),
    );
  }

  Method _buildSetDependencies(
    Map<FieldElement, Set<FieldElement>> dependencies,
  ) {
    throw UnimplementedError();
  }

  static const _memberType = 'ViewModelMember';

  static const acceptedType = 'ViewModel';
}

typedef _MemberDependency = (FieldElement source, FieldElement target);

class _MemberDependencyCollector extends RecursiveAstVisitor {
  const _MemberDependencyCollector({
    required this.current,
    required this.members,
  });

  final FieldElement current;

  final List<FieldElement> members;

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.staticElement;
    if(element is! PropertyAccessorElement) return super.visitSimpleIdentifier(node);

    final type = element.type.returnType;
    if(type is InterfaceType) {
      final supertypes = type.allSupertypes;
      if (!supertypes.any((t) => t.name == VmMixinGeneratorHelperOld._memberType)) return super.visitSimpleIdentifier(node);

      print('gotcha');
    }

    return super.visitSimpleIdentifier(node);
  }
}
