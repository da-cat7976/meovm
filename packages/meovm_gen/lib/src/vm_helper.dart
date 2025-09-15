import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Block, Expression;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
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

  bool canAccept(ClassElement2 element) {
    return _vmChecker.isAssignableFromType(element.thisType);
  }

  Future<String> generate(
    ClassElement2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final libElement = element.library2;
    final library = await libElement.session.getResolvedLibraryByElement2(
      libElement,
    );
    if (library is! ResolvedLibraryResult) return '';

    final members = _getMembers(element).toList();
    final inheritedMembers = _getInheritedMembers(element).toList();
    final externalMembers = _getExternalMembers(element).toList();

    print('${element.name3}: $externalMembers');
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
        ..name = '_\$${element.name3}'
        ..on = refer(element.supertype!.getDisplayString())
        ..methods.addAll(
          [...definitions, ?memberList, ?setDependencies], // fmt
        ),
    );

    final emitter = DartEmitter();

    return _formatter.format('${mixin.accept(emitter)}');
  }

  Iterable<FieldElement2> _getMembers(InterfaceElement2 element) sync* {
    for (final field in element.fields2) {
      if (_memberChecker.isAssignableFromType(field.type)) yield field;
    }
  }

  Iterable<FieldElement2> _getInheritedMembers(
    InterfaceElement2 element,
  ) sync* {
    for (final type in element.allSupertypes) {
      for (final field in type.element3.fields2) {
        if (_memberChecker.isAssignableFromType(field.type)) yield field;
      }
    }
  }

  Iterable<_ExternalMemberInfo> _getExternalMembers(
    InterfaceElement2 element,
  ) sync* {
    final supertype = element.allSupertypes.firstWhereOrNull(
      (e) => _vmChecker.isExactlyType(e),
    );
    if (supertype is! InterfaceType) return;

    final paramType = supertype.typeArguments.firstOrNull?.element3;
    if (paramType is! InterfaceElement2) return;

    yield* _getExternalMembersFromExactly(paramType);
    for (final type in paramType.allSupertypes) {
      yield* _getExternalMembersFromExactly(type.element3);
    }
  }

  Iterable<_ExternalMemberInfo> _getExternalMembersFromExactly(
    InterfaceElement2 element,
  ) sync* {
    for (final field in element.fields2) {
      final type = field.type;

      if (_memberChecker.isAssignableFromType(type)) {
        yield _ExternalMemberInfo(field);
      }

      if (_vmChecker.isAssignableFromType(type)) {
        final vmClass = type.element3;
        if (vmClass is! InterfaceElement2) continue;

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
    List<FieldElement2> members,
    List<FieldElement2> inheritedMembers,
    List<_ExternalMemberInfo> externalMembers,
  ) sync* {
    final allMembers = [...members, ...inheritedMembers];

    for (final member in members) {
      final declaration = library.getFragmentDeclaration(member.firstFragment);
      final node = declaration?.node;

      if (node is! VariableDeclaration) return;
      final initializer = node.initializer;
      if (initializer == null) return;

      final collector = _MemberDependenciesCollector(
        library: library,
        current: member,
        members: allMembers,
        externalMembers: externalMembers,
      );
      initializer.visitChildren(collector);

      final dependAnnotations = _dependAnnotationsOf(member);
      final disabled = dependAnnotations.where((a) => a.disabled);
      final disabledInternal = disabled.where((a) => !a.external).toSet();
      final disabledExternal = disabled.where((a) => a.external).toSet();

      for (final internal in collector.internalDependencies) {
        final isDisabled = disabledInternal.any(
          (a) => a.dependOn == Symbol(internal.name3!),
        );
        if (isDisabled) continue;

        yield _InternalDependency(source: internal, target: member);
      }

      for (final external in collector.externalDependencies) {
        final isDisabled = disabledExternal.any(
          (a) =>
              a.dependOn == Symbol(external.member.name3!) &&
                  external.isAnonymous
              ? true
              : a.from == Symbol(external.vm!.name3!),
        );
        if (isDisabled) continue;

        yield _ExternalDependency(source: external, target: member);
      }

      final enabled = dependAnnotations.where((a) => !a.disabled);

      for (final depend in enabled) {
        if (depend.external) {
          final source = externalMembers.firstWhereOrNull(
            (e) => depend.dependOn == Symbol(e.member.name3!) && e.isAnonymous
                ? true
                : depend.from == Symbol(e.vm!.name3!),
          );
          if (source == null) {
            throw InvalidGenerationSourceError(
              'Could not find source dependency ${depend.dependOn}',
              element: member,
            );
          }

          yield _ExternalDependency(source: source, target: member);
        } else {
          final source = allMembers.firstWhereOrNull(
            (e) => Symbol(e.name3!) == depend.dependOn,
          );
          if (source == null) {
            throw InvalidGenerationSourceError(
              'Could not find source dependency ${depend.dependOn}',
              element: member,
            );
          }

          yield _InternalDependency(source: source, target: member);
        }
      }
    }
  }

  Iterable<MeovmDepend> _dependAnnotationsOf(FieldElement2 element) sync* {
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

  Method? _buildMembersList(Iterable<FieldElement2> members) {
    if (members.isEmpty) return null;
    final names = members.map((e) => e.name3!);

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
          refer(
            'super',
          ).property('setDependencies').call([refer('depend')]).statement,
          ..._buildDependStatements(dependencies),
        ]),
    );
  }

  Iterable<Code> _buildDependStatements(
    Iterable<_DependencyPair> dependencies,
  ) sync* {
    for (final dependency in dependencies) {
      yield refer(
        'depend',
      ).call([dependency.sourceRef, dependency.targetRef]).statement;
    }
  }

  static final _vmChecker = TypeChecker.typeNamed(MeovmAutoVm, inPackage: 'meovm_api');

  static final _memberChecker = TypeChecker.typeNamed(MeovmAutoVmMember, inPackage: 'meovm_api');

  static final _dependAnnotationChecker = TypeChecker.typeNamed(MeovmDepend, inPackage: 'meovm_api');
}

sealed class _DependencyPair {
  const _DependencyPair();

  Expression get sourceRef;

  Expression get targetRef;
}

final class _InternalDependency extends _DependencyPair {
  const _InternalDependency({required this.source, required this.target});

  final FieldElement2 source;

  final FieldElement2 target;

  @override
  Expression get sourceRef => refer(source.name3!);

  @override
  Expression get targetRef => refer(target.name3!);
}

final class _ExternalDependency extends _DependencyPair {
  const _ExternalDependency({required this.source, required this.target});

  final _ExternalMemberInfo source;

  final FieldElement2 target;

  @override
  Expression get sourceRef {
    final param = refer('param');
    if (source.isAnonymous) {
      return param.property(source.member.name3!);
    }

    return param.property(source.vm!.name3!).property(source.member.name3!);
  }

  @override
  Expression get targetRef => refer(target.name3!);
}

class _ExternalMemberInfo {
  final FieldElement2 member;

  final FieldElement2? vm;

  _ExternalMemberInfo(this.member, {this.vm});

  bool get isAnonymous => vm == null;

  bool isSame(Element2? other) {
    return member == other;
  }

  @override
  String toString() {
    final vmName = vm?.name3 ?? 'anonymous';
    return '$vmName -> ${member.name3}';
  }
}

class _MemberDependenciesCollector extends RecursiveAstVisitor<void> {
  final ResolvedLibraryResult library;

  final FieldElement2 current;

  final List<FieldElement2> members;

  final List<_ExternalMemberInfo> externalMembers;

  final Set<FieldElement2> _internal = {};

  final Set<_ExternalMemberInfo> _external = {};

  _MemberDependenciesCollector({
    required this.library,
    required this.current,
    required this.members,
    required this.externalMembers,
  });

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;

    if (element is MethodElement2) {
      return _checkMethodImplementation(element);
    }

    if (element is! PropertyAccessorElement2) {
      return super.visitSimpleIdentifier(node);
    }

    final type = element.returnType;
    if (!_memberChecker.isAssignableFromType(type)) {
      return super.visitSimpleIdentifier(node);
    }

    final internal = members.firstWhereOrNull((e) => e == element.variable3);
    if (internal != null) {
      _internal.add(internal);
      return;
    }

    if (current.name3 == 'vmValue' && node.name == 'value') {
      print('gotcha');
    }

    final external = externalMembers.firstWhereOrNull(
      (e) => e.isSame(element.variable3),
    );
    if (external != null) {
      _external.add(external);
      return;
    }

    super.visitSimpleIdentifier(node);
  }

  void _checkMethodImplementation(MethodElement2 element) {
    final declaration = library.getFragmentDeclaration(element.firstFragment);
    final node = declaration?.node;

    if (node is! MethodDeclaration) return;

    final body = node.body;
    if (body is! BlockFunctionBody) return;

    final subCollector = _MemberDependenciesCollector(
      library: library,
      current: current,
      members: members,
      externalMembers: externalMembers,
    );

    body.visitChildren(subCollector);
    _internal.addAll(subCollector.internalDependencies);
  }

  Set<FieldElement2> get internalDependencies => Set.unmodifiable(_internal);

  Set<_ExternalMemberInfo> get externalDependencies =>
      Set.unmodifiable(_external);

  static final _memberChecker = TypeChecker.typeNamed(
    MeovmAutoVmMember,
    inPackage: 'meovm_api',
  );
}
