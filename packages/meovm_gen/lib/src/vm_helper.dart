import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Block, Expression;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:source_gen/source_gen.dart';

class VmMixinGeneratorHelper {
  final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  final _memberChecker = TypeChecker.fromRuntime(MeovmAutoVmMember);

  Future<String> generate(
    ClassElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final library = await element.session?.getResolvedLibraryByElement(
      element.library,
    );
    if (library is! ResolvedLibraryResult) return '';

    final members = _getMembers(element).toList();
    final dependencies = _getDependencies(library, members).toList();

    final definitions = _buildDefinitions(members);
    final memberList = _buildMembersList(members);
    final setDependencies = _buildSetDependencies(dependencies);

    final mixin = Mixin(
      (b) => b
        ..name = '_\$${element.name}'
        ..on = refer('ViewModel')
        ..methods.addAll(
          [...definitions, memberList, setDependencies], // fmt
        ),
    );

    final emitter = DartEmitter();

    return _formatter.format('${mixin.accept(emitter)}');
  }

  Iterable<FieldElement> _getMembers(ClassElement element) sync* {
    for (final field in element.fields) {
      if (_memberChecker.isAssignableFromType(field.type)) yield field;
    }
  }

  Iterable<_DependencyPair> _getDependencies(
    ResolvedLibraryResult library,
    List<FieldElement> members,
  ) sync* {
    for (final member in members) {
      final declaration = library.getElementDeclaration(member);
      final node = declaration?.node;

      if (node is! VariableDeclaration) return;
      final initializer = node.initializer;
      if (initializer == null) return;

      final collector = _MemberDependenciesCollector(
        library: library,
        current: member,
        members: members,
      );
      initializer.visitChildren(collector);

      for (final internal in collector.internalDependencies) {
        yield (source: internal, target: member, isExternal: false);
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

  Method _buildMembersList(Iterable<FieldElement> members) {
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

  Method _buildSetDependencies(Iterable<_DependencyPair> dependencies) {
    return Method.returnsVoid(
      (b) => b
        ..name = 'setDependencies'
        ..annotations.add(refer('override'))
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'depend'
              ..type = refer('ViewModelDependencySetter'),
          ),
        )
        ..body = Block((b) => _addDependExpressions(b, dependencies)),
    );
  }

  BlockBuilder _addDependExpressions(
    BlockBuilder b,
    Iterable<_DependencyPair> dependencies,
  ) {
    for (final dependency in dependencies) {
      final source = dependency.source.name;
      final target = dependency.target.name;
      final isExternal = dependency.isExternal;

      final sourceRef = refer(isExternal ? 'param.$source' : source);
      final targetRef = refer(target);

      b.addExpression(refer('depend').call([sourceRef, targetRef]));
    }

    return b;
  }
}

typedef _DependencyPair = ({
  FieldElement source,
  FieldElement target,
  bool isExternal,
});

class _MemberDependenciesCollector extends RecursiveAstVisitor<void> {
  final ResolvedLibraryResult library;

  final FieldElement current;

  final List<FieldElement> members;

  final Set<FieldElement> _internal = {};

  _MemberDependenciesCollector({
    required this.library,
    required this.current,
    required this.members,
  });

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.staticElement;

    if (element is MethodElement) {
      return _checkMethodImplementation(element);
    }

    if (element is! PropertyAccessorElement) {
      return super.visitSimpleIdentifier(node);
    }

    final type = element.returnType;
    if (!_memberChecker.isAssignableFromType(type)) {
      return super.visitSimpleIdentifier(node);
    }

    final internal = members.firstWhereOrNull((e) => e.name == element.name);
    if (internal != null) {
      _internal.add(internal);
      return;
    }

    // TODO: Handle external dependencies

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.methodName.staticElement;
    print('method $element');

    return super.visitMethodInvocation(node);
  }

  void _checkMethodImplementation(MethodElement element) {
    final declaration = library.getElementDeclaration(element);
    final node = declaration?.node;

    if (node is! MethodDeclaration) return;

    final body = node.body;
    if (body is! BlockFunctionBody) return;

    final subCollector = _MemberDependenciesCollector(
      library: library,
      current: current,
      members: members,
    );

    body.visitChildren(subCollector);
    _internal.addAll(subCollector.internalDependencies);
  }

  Set<FieldElement> get internalDependencies => Set.unmodifiable(_internal);

  static final _memberChecker = TypeChecker.fromRuntime(MeovmAutoVmMember);
}
