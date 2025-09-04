import 'package:flutter/foundation.dart';
import 'package:graphs/graphs.dart';
import 'package:meovm/src/core/api.dart';
import 'package:meovm/src/core/member_factory.dart';
import 'package:meta/meta.dart';

/// Function for defining dependencies between ViewModel members.
typedef ViewModelDependencySetter =
    void Function(ViewModelMember source, ViewModelMember target);

typedef _DisposeListener = void Function(ViewModelMember disposed);

/// Base class for ViewModel, providing lifecycle implementation,
/// member management, and their dependencies.
///
/// For information on how to integrate ViewModel into the widget tree, see
/// [ViewModelDispatcher].
abstract class ViewModel<Param extends ViewModelParameter?>
    implements ViewModelLifecycle<Param>, ViewModelMemberFactoryAccess {
  @mustBeOverridden
  @visibleForOverriding
  List<ViewModelMember> get members;

  /// Current state of the ViewModel.
  ///
  /// See [ViewModelState].
  @override
  @nonVirtual
  ViewModelState get state => _state;

  /// State owner of the ViewModel.
  ///
  /// This getter must not be used outside of the ViewModel and
  /// within the [dispose] method.
  @protected
  @nonVirtual
  ViewModelOwner get owner {
    if (_state == ViewModelState.disposed) {
      throw StateError('ViewModel is already disposed');
    }

    return _owner!;
  }

  /// Current parameter of the ViewModel.
  ///
  /// This getter must not be used outside of the ViewModel and
  /// within the [dispose] method.
  @protected
  @nonVirtual
  Param get param {
    if (_state == ViewModelState.disposed) {
      throw StateError('ViewModel is already disposed');
    }

    return _param as Param;
  }

  final Map<ViewModelMember, Set<ViewModelMember>> _dependencies = {};

  final Map<ViewModelMember, VoidCallback> _dependencyListeners = {};

  late List<ViewModelMember> _members;

  ViewModelOwner<Param>? _owner;

  Param? _param;

  ViewModelState _state = ViewModelState.created;

  @override
  @mustCallSuper
  void init(ViewModelOwner<Param> owner) {
    if (_state != ViewModelState.created) {
      throw StateError(
        'ViewModel can only be initialized once from the created state. '
        'Current state is $_state',
      );
    }

    _owner = owner;
    _param = owner.param;
    _members = members;

    for (final member in _members) {
      member.init(owner);
    }

    updateDependencies();

    _state = ViewModelState.active;
  }

  @override
  void updateDependencies() {
    final Set<ViewModelMember> invalidatedSources = Set.of(_dependencies.keys);
    for (final member in _members) {
      _dependencies[member] ??= {};
    }

    bool hasDependencies = false;
    void setter(ViewModelMember source, ViewModelMember target) {
      Set<ViewModelMemberBase>? dependents = _dependencies[source] ??= {};
      if (dependents.contains(target)) return;

      assert(
        _dependencies.containsKey(target),
        'Target member is not owned by this ViewModel.\n'
        'If you are setting dependencies manually, make sure it is added to the '
        'members list.\n'
        'If you are using code generation, make sure it is annotated with '
        '@VmMember and re-run the build_runner.',
      );

      dependents.add(target);
      invalidatedSources.remove(source);

      hasDependencies = true;
    }

    setDependencies(setter);

    for (final invalidated in invalidatedSources) {
      final listener = _dependencyListeners[invalidated];
      if (listener == null) continue;

      invalidated._lifecycleAwareRemoveListener(listener);
      _dependencyListeners.remove(invalidated);
    }

    if (hasDependencies) {
      try {
        _members = topologicalSort(
          _dependencies.keys,
          (node) => _dependencies[node]!,
        );
      } on CycleException<ViewModelMember> catch (error, stacktrace) {
        assert(
          false,
          'ViewModel can not have circular dependencies between members. '
          'Dependency feature will be disabled in production mode.\n\n'
          'Reason: $error\n\n'
          'Stacktrace: $stacktrace',
        );

        _dependencies.clear();
      }
    }

    for (final source in _dependencies.keys) {
      if (_dependencyListeners.containsKey(source)) continue;
      // ? Dispose listeners is designed to ensure there are no memory leaks
      // ? with external dependencies. However, internal members is also
      // ? listened for disposal, but this should have no effect since
      // ? dispose listener is removed before calling .dispose() on internal
      // ? members.
      source._addDisposeListener(_memberDisposeListener);

      // ? In some cases this mechanism can call targets twice due to
      // ? complexity of dependencies. It's not a big deal since member's
      // ? architecture prevents unnecessary UI updates, but it's still
      // ? a problem that sometimes should be fixed.
      void listener() {
        if (_state != ViewModelState.active) return;

        final targets = _dependencies[source]!;
        for (final target in targets) {
          target.update();
        }

        source.notifyUpdateCompleted();
      }

      source.addListener(listener);
      _dependencyListeners[source] = listener;
    }
  }

  /// {@template view_model.setDependencies}
  ///
  /// Sets dependencies between members.
  ///
  /// If [depend] is called at least once within this method,
  /// the order of initialization, updates, and disposal of members will change
  /// to a topological order.
  ///
  /// The presence of dependencies between two members allows for optimizing
  /// updates of any of their subscribers, since when the parent member's state
  /// changes, all dependent members will be updated, and independent ones will not.
  ///
  /// {@endtemplate}
  @visibleForOverriding
  void setDependencies(ViewModelDependencySetter depend) {
    // Intentionally left blank
  }

  @override
  @mustCallSuper
  void update() {
    if (_state != ViewModelState.active) {
      throw StateError(
        'ViewModel can be updated only from ready state. '
        'Current state is $_state',
      );
    }

    _state = ViewModelState.updating;
    _param = _owner!.param;

    for (final member in _members) {
      member.update();
    }

    for (final member in _members) {
      member.notifyUpdateCompleted();
    }

    _state = ViewModelState.active;
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_state != ViewModelState.active) {
      throw StateError(
        'ViewModel can be disposed only from ready state and only once. '
        'Current state is $_state',
      );
    }
    _state = ViewModelState.disposed;

    for (final member in _dependencyListeners.keys) {
      member.removeListener(_dependencyListeners[member]!);
      member._removeDisposeListener(_memberDisposeListener);
    }

    for (final member in _members) {
      member.dispose();
    }

    _owner = null;
    _param = null;
    _dependencyListeners.clear();
    _dependencies.clear();
    _members.clear();
  }

  void _memberDisposeListener(ViewModelMember disposed) {
    _dependencyListeners.remove(disposed);
    _dependencies.remove(disposed);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(EnumProperty('State', _state))
      ..add(
        IterableProperty(
          'Members',
          _members.map((e) => '$e -> ${_dependencies[e] ?? {}}'),
        ),
      );

    for (final member in _members) {
      properties.add(member.toDiagnosticsNode());
    }
  }
}

/// Base class for a ViewModel member implementing integration with
/// the State owner.
abstract class ViewModelMember implements ViewModelMemberBase {
  ViewModelMember({String? debugName}) : _debugName = debugName;

  final String? _debugName;

  String get debugName => _debugName ?? runtimeType.toString();

  /// State owner of the ViewModel member, providing direct access to
  /// Riverpod and Flutter.
  ///
  /// This is convenient for implementing members that rely solely on constant
  /// parameters.
  @protected
  @nonVirtual
  ViewModelOwner get owner {
    assert(
      _owner is ViewModelOwner,
      'Member in not mounted to ViewModel.\n'
      'Make sure you added it into ViewModel.members',
    );

    return _owner!;
  }

  ViewModelOwner? _owner;

  final List<_DisposeListener> _disposeListeners = [];

  @override
  @mustCallSuper
  @visibleForOverriding
  void init(ViewModelOwner owner) {
    assert(_owner == null, 'Member is already initialized');

    _owner = owner;
  }

  @override
  @visibleForOverriding
  void update();

  @override
  @mustCallSuper
  @visibleForOverriding
  void dispose() {
    assert(_owner != null, 'Member is not initialized');

    _owner = null;
    for (final listener in _disposeListeners) {
      listener(this);
    }

    _disposeListeners.clear();
  }

  void _addDisposeListener(_DisposeListener listener) {
    _disposeListeners.add(listener);
  }

  void _removeDisposeListener(_DisposeListener listener) {
    _disposeListeners.remove(listener);
  }

  void _lifecycleAwareRemoveListener(VoidCallback listener) {
    if (_owner == null) return;
    removeListener(listener);
  }

  @override
  @visibleForOverriding
  DiagnosticsNode toDiagnosticsNode() =>
      StringProperty(debugName, '<unknown>', quoted: false);
}

abstract class ViewModelDelegate<
  VM extends ViewModel<Param>,
  Param extends ViewModelParameter
>
    implements ViewModelMemberFactoryAccess {
  const ViewModelDelegate({required this.owner});

  @protected
  final VM owner;

  List<ViewModelMemberBase> get members;

  void setDependencies(ViewModelDependencySetter depend) {
    // Intentionally left blank
  }
}
