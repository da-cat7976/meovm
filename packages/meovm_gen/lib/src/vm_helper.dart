import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Block, Expression;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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

  bool canAccept(ClassElement element) {
    return _vmChecker.isAssignableFromType(element.thisType);
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

    final members = _getMembers(element).toList();
    final inheritedMembers = _getInheritedMembers(element).toList();
    final externalMembers = _getExternalMembers(element).toList();

    final dependencies = _getDependencies(
      library,
      members,
      inheritedMembers,
      externalMembers,
    ).toList();

    final definitions = _buildDefinitions(members);
    final memberList = _buildMembersList(members);
    final setDependencies = _buildSetDependencies(dependencies);

    final mixin = Mixin(
      (b) => b
        ..name = '_\$${element.name}'
        ..on = refer(element.supertype!.getDisplayString())
        ..methods.addAll(
          [...definitions, ?memberList, ?setDependencies], // fmt
        ),
    );

    final emitter = DartEmitter();

    return _formatter.format('${mixin.accept(emitter)}');
  }

  Iterable<FieldElement> _getMembers(InterfaceElement element) sync* {
    for (final field in element.fields) {
      if (_memberChecker.isAssignableFromType(field.type)) yield field;
    }
  }

  Iterable<FieldElement> _getInheritedMembers(InterfaceElement element) sync* {
    for (final type in element.allSupertypes) {
      for (final field in type.element.fields) {
        if (_memberChecker.isAssignableFromType(field.type)) yield field;
      }
    }
  }

  Iterable<_ExternalMemberInfo> _getExternalMembers(
    InterfaceElement element,
  ) sync* {
    final supertype = element.allSupertypes.firstWhereOrNull(
      (e) => _vmChecker.isExactlyType(e),
    );
    if (supertype is! InterfaceType) return;

    final paramType = supertype.typeArguments.firstOrNull?.element;
    if (paramType is! InterfaceElement) return;

    yield* _getExternalMembersFromExactly(paramType);
    for (final type in paramType.allSupertypes) {
      yield* _getExternalMembersFromExactly(type.element);
    }
  }

  Iterable<_ExternalMemberInfo> _getExternalMembersFromExactly(
    InterfaceElement element,
  ) sync* {
    for (final field in element.fields) {
      final type = field.type;

      if (_memberChecker.isAssignableFromType(type)) {
        yield _ExternalMemberInfo(field);
      }

      if (_vmChecker.isAssignableFromType(type)) {
        final vmClass = type.element;
        if (vmClass is! InterfaceElement) continue;

        final members = [
          ..._getMembers(vmClass),
          ..._getInheritedMembers(vmClass),
        ];

        for (final member in members) {
          yield _ExternalMemberInfo(member, vm: field);
        }
      }
    }
  }

  Iterable<_DependencyPair> _getDependencies(
    ResolvedLibraryResult library,
    List<FieldElement> members,
    List<FieldElement> inheritedMembers,
    List<_ExternalMemberInfo> externalMembers,
  ) sync* {
    final allMembers = [...members, ...inheritedMembers];

    for (final member in members) {
      final initializer = _initializerOf(library, member);
      if (initializer == null) return;

      final discovered = _collectDependencies(
        library: library,
        initializer: initializer,
        members: allMembers,
        externalMembers: externalMembers,
      );
      final annotations = _dependAnnotationsOf(member).toList();

      yield* _discoveredDependenciesOf(member, discovered, annotations);
      yield* _annotatedDependenciesOf(
        member,
        annotations,
        allMembers,
        externalMembers,
      );
    }
  }

  AstNode? _initializerOf(ResolvedLibraryResult library, FieldElement member) {
    final declaration = library.getFragmentDeclaration(member.firstFragment);
    final node = declaration?.node;
    return node is VariableDeclaration ? node.initializer : null;
  }

  _MemberDependenciesCollector _collectDependencies({
    required ResolvedLibraryResult library,
    required AstNode initializer,
    required List<FieldElement> members,
    required List<_ExternalMemberInfo> externalMembers,
  }) {
    final collector = _MemberDependenciesCollector(
      library: library,
      members: members,
      externalMembers: externalMembers,
    );
    initializer.visitChildren(collector);
    return collector;
  }

  Iterable<_DependencyPair> _discoveredDependenciesOf(
    FieldElement target,
    _MemberDependenciesCollector discovered,
    List<MeovmDepend> annotations,
  ) sync* {
    final disabled = annotations.where((annotation) => annotation.disabled);
    final disabledInternal = disabled.where(
      (annotation) => !annotation.external,
    );
    final disabledExternal = disabled.where(
      (annotation) => annotation.external,
    );

    for (final source in discovered.internalDependencies) {
      final isDisabled = disabledInternal.any(
        (annotation) => annotation.dependOn == Symbol(source.name!),
      );
      if (!isDisabled) {
        yield _InternalDependency(source: source, target: target);
      }
    }

    for (final source in discovered.externalDependencies) {
      final isDisabled = disabledExternal.any(
        (annotation) => _matchesExternal(annotation, source),
      );
      if (!isDisabled) {
        yield _ExternalDependency(source: source, target: target);
      }
    }
  }

  Iterable<_DependencyPair> _annotatedDependenciesOf(
    FieldElement target,
    List<MeovmDepend> annotations,
    List<FieldElement> members,
    List<_ExternalMemberInfo> externalMembers,
  ) sync* {
    for (final annotation in annotations.where((item) => !item.disabled)) {
      yield annotation.external
          ? _resolveExternalDependency(annotation, target, externalMembers)
          : _resolveInternalDependency(annotation, target, members);
    }
  }

  _InternalDependency _resolveInternalDependency(
    MeovmDepend annotation,
    FieldElement target,
    List<FieldElement> members,
  ) {
    final source = members.firstWhereOrNull(
      (member) => Symbol(member.name!) == annotation.dependOn,
    );
    if (source == null) _throwSourceNotFound(annotation, target);
    return _InternalDependency(source: source, target: target);
  }

  _ExternalDependency _resolveExternalDependency(
    MeovmDepend annotation,
    FieldElement target,
    List<_ExternalMemberInfo> externalMembers,
  ) {
    final source = externalMembers.firstWhereOrNull(
      (member) => _matchesExternal(annotation, member),
    );
    if (source == null) _throwSourceNotFound(annotation, target);
    return _ExternalDependency(source: source, target: target);
  }

  bool _matchesExternal(MeovmDepend annotation, _ExternalMemberInfo member) {
    if (member.isAnonymous) {
      return annotation.dependOn == Symbol(member.member.name!);
    }
    return annotation.from == Symbol(member.vm!.name!);
  }

  Never _throwSourceNotFound(MeovmDepend annotation, FieldElement target) {
    throw InvalidGenerationSourceError(
      'Could not find source dependency ${annotation.dependOn}',
      element: target,
    );
  }

  Iterable<MeovmDepend> _dependAnnotationsOf(FieldElement element) sync* {
    final annotations = _dependAnnotationChecker.annotationsOf(element);
    for (final annotation in annotations) {
      final from = annotation.getField('from')?.toSymbolValue();

      yield MeovmDepend(
        Symbol(annotation.getField('dependOn')!.toSymbolValue()!),
        from: from is String ? Symbol(from) : null,
        external: annotation.getField('external')!.toBoolValue()!,
        disabled: annotation.getField('disabled')!.toBoolValue()!,
      );
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

  Method? _buildMembersList(Iterable<FieldElement> members) {
    if (members.isEmpty) return null;
    final names = members.map((e) => e.name!);

    return Method(
      (b) => b
        ..name = 'members'
        ..returns = refer('List<ViewModelMember>')
        ..type = MethodType.getter
        ..annotations.add(refer('override'))
        ..body = Block(
          (b) => b.addExpression(
            literalList([
              refer('super').property('members').spread,
              ...names.map(refer),
            ]).returned,
          ),
        ),
    );
  }

  Method? _buildSetDependencies(Iterable<_DependencyPair> dependencies) {
    if (dependencies.isEmpty) return null;

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
        ..body = Block.of([
          refer('super')
              .property('setDependencies')
              .call([refer('depend')])
              .statement,
          ..._buildDependStatements(dependencies),
        ]),
    );
  }

  Iterable<Code> _buildDependStatements(
    Iterable<_DependencyPair> dependencies,
  ) sync* {
    for (final dependency in dependencies) {
      yield refer('depend')
          .call([dependency.sourceRef, dependency.targetRef])
          .statement;
    }
  }

  static final _vmChecker = TypeChecker.typeNamed(
    MeovmAutoVm,
    inPackage: 'meovm_api',
  );

  static final _memberChecker = TypeChecker.typeNamed(
    MeovmAutoVmMember,
    inPackage: 'meovm_api',
  );

  static final _dependAnnotationChecker = TypeChecker.typeNamed(
    MeovmDepend,
    inPackage: 'meovm_api',
  );
}

sealed class _DependencyPair {
  const _DependencyPair();

  Expression get sourceRef;

  Expression get targetRef;
}

final class _InternalDependency extends _DependencyPair {
  const _InternalDependency({required this.source, required this.target});

  final FieldElement source;

  final FieldElement target;

  @override
  Expression get sourceRef => refer(source.name!);

  @override
  Expression get targetRef => refer(target.name!);
}

final class _ExternalDependency extends _DependencyPair {
  const _ExternalDependency({required this.source, required this.target});

  final _ExternalMemberInfo source;

  final FieldElement target;

  @override
  Expression get sourceRef {
    final param = refer('param');
    if (source.isAnonymous) {
      return param.property(source.member.name!);
    }

    return param.property(source.vm!.name!).property(source.member.name!);
  }

  @override
  Expression get targetRef => refer(target.name!);
}

class _ExternalMemberInfo {
  final FieldElement member;

  final FieldElement? vm;

  _ExternalMemberInfo(this.member, {this.vm});

  bool get isAnonymous => vm == null;

  bool isSame(Element? other) {
    return member == other;
  }

  @override
  String toString() {
    final vmName = vm?.name ?? 'anonymous';
    return '$vmName -> ${member.name}';
  }
}

class _MemberDependenciesCollector extends RecursiveAstVisitor<void> {
  final ResolvedLibraryResult library;

  final List<FieldElement> members;

  final List<_ExternalMemberInfo> externalMembers;

  final Set<FieldElement> _internal = {};

  final Set<_ExternalMemberInfo> _external = {};

  final Set<ExecutableElement> _visitedExecutables;

  _MemberDependenciesCollector({
    required this.library,
    required this.members,
    required this.externalMembers,
    Set<ExecutableElement>? visitedExecutables,
  }) : _visitedExecutables = visitedExecutables ?? {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;

    if (element is MethodElement) {
      _checkExecutableImplementation(element);
      return;
    }

    if (element is! PropertyAccessorElement) {
      return super.visitSimpleIdentifier(node);
    }

    final type = element.returnType;
    if (!_memberChecker.isAssignableFromType(type)) {
      _checkExecutableImplementation(element);
      return;
    }

    final internal = members.firstWhereOrNull((e) => e == element.variable);
    if (internal != null) {
      _internal.add(internal);
      return;
    }

    final external = externalMembers.firstWhereOrNull(
      (e) => e.isSame(element.variable),
    );
    if (external != null) {
      _external.add(external);
      return;
    }

    super.visitSimpleIdentifier(node);
  }

  void _checkExecutableImplementation(ExecutableElement element) {
    if (!_visitedExecutables.add(element)) return;

    final declaration = _getLibrarySafeDeclaration(element);
    final node = declaration?.node;

    if (node is! MethodDeclaration) return;

    final subCollector = _MemberDependenciesCollector(
      library: library,
      members: members,
      externalMembers: externalMembers,
      visitedExecutables: _visitedExecutables,
    );

    node.body.visitChildren(subCollector);
    _internal.addAll(subCollector.internalDependencies);
    _external.addAll(subCollector.externalDependencies);
  }

  FragmentDeclarationResult? _getLibrarySafeDeclaration(Element element) {
    try {
      return library.getFragmentDeclaration(element.firstFragment);
    } on ArgumentError {
      return null;
    }
  }

  Set<FieldElement> get internalDependencies => Set.unmodifiable(_internal);

  Set<_ExternalMemberInfo> get externalDependencies =>
      Set.unmodifiable(_external);

  static final _memberChecker = TypeChecker.typeNamed(
    MeovmAutoVmMember,
    inPackage: 'meovm_api',
  );
}
