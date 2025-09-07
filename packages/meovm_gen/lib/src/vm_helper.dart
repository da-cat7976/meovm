// ignore_for_file: deprecated_member_use

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
    return _vmChecker.isAssignableFrom(element);
  }

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
    final inheritedMembers = _getInheritedMembers(element).toList();
    final externalMembers = _getExternalMembers(element).toList();

    print('${element.name}: $externalMembers');
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
      final declaration = library.getElementDeclaration(member);
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
          (a) => a.dependOn == Symbol(internal.name),
        );
        if (isDisabled) continue;

        yield _InternalDependency(source: internal, target: member);
      }

      for (final external in collector.externalDependencies) {
        final isDisabled = disabledExternal.any(
          (a) =>
              a.dependOn == Symbol(external.member.name) && external.isAnonymous
              ? true
              : a.from == Symbol(external.vm!.name),
        );
        if (isDisabled) continue;

        yield _ExternalDependency(source: external, target: member);
      }

      final enabled = dependAnnotations.where((a) => !a.disabled);

      for (final depend in enabled) {
        if (depend.external) {
          final source = externalMembers.firstWhereOrNull(
            (e) => depend.dependOn == Symbol(e.member.name) && e.isAnonymous
                ? true
                : depend.from == Symbol(e.vm!.name),
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
            (e) => Symbol(e.name) == depend.dependOn,
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
    final names = members.map((e) => e.name);

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

  static final _vmChecker = TypeChecker.fromRuntime(MeovmAutoVm);

  static final _memberChecker = TypeChecker.fromRuntime(MeovmAutoVmMember);

  static final _dependAnnotationChecker = TypeChecker.fromRuntime(MeovmDepend);
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
  Expression get sourceRef => refer(source.name);

  @override
  Expression get targetRef => refer(target.name);
}

final class _ExternalDependency extends _DependencyPair {
  const _ExternalDependency({required this.source, required this.target});

  final _ExternalMemberInfo source;

  final FieldElement target;

  @override
  Expression get sourceRef {
    final param = refer('param');
    if (source.isAnonymous) {
      return param.property(source.member.name);
    }

    return param.property(source.vm!.name).property(source.member.name);
  }

  @override
  Expression get targetRef => refer(target.name);
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

  final FieldElement current;

  final List<FieldElement> members;

  final List<_ExternalMemberInfo> externalMembers;

  final Set<FieldElement> _internal = {};

  final Set<_ExternalMemberInfo> _external = {};

  _MemberDependenciesCollector({
    required this.library,
    required this.current,
    required this.members,
    required this.externalMembers,
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

    final internal = members.firstWhereOrNull((e) => e == element.variable2);
    if (internal != null) {
      _internal.add(internal);
      return;
    }

    if (current.name == 'vmValue' && node.name == 'value') {
      print('gotcha');
    }

    final external = externalMembers.firstWhereOrNull(
      (e) => e.isSame(element.variable2),
    );
    if (external != null) {
      _external.add(external);
      return;
    }

    super.visitSimpleIdentifier(node);
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
      externalMembers: externalMembers,
    );

    body.visitChildren(subCollector);
    _internal.addAll(subCollector.internalDependencies);
  }

  Set<FieldElement> get internalDependencies => Set.unmodifiable(_internal);

  Set<_ExternalMemberInfo> get externalDependencies =>
      Set.unmodifiable(_external);

  static final _memberChecker = TypeChecker.fromRuntime(MeovmAutoVmMember);
}
