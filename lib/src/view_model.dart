import 'package:flutter/foundation.dart';
import 'package:graphs/graphs.dart';
import 'package:meovm/src/api.dart';
import 'package:meovm/src/member_factory.dart';
import 'package:meta/meta.dart';

/// Function for defining dependencies between ViewModel members.
typedef ViewModelDependencySetter =
    void Function(ViewModelMember source, ViewModelMember target);

/// Base class for ViewModel, providing lifecycle implementation,
/// member management, and their dependencies.
///
/// For information on how to integrate ViewModel into the widget tree, see
/// [ViewModelDispatcher].
abstract class ViewModel<Param>
    implements ViewModelLifecycle<Param>, ViewModelMemberFactoryAccess {
  @mustBeOverridden
  @visibleForOverriding
  List<ViewModelMemberBase> get members => [];

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

  final Map<ViewModelMemberBase, Set<ViewModelMemberBase>> _dependencies = {};

  late List<ViewModelMemberBase> _members;

  ViewModelOwner? _owner;

  Param? _param;

  ViewModelState _state = ViewModelState.created;

  @override
  @mustCallSuper
  void init(ViewModelOwner owner) {
    if (_state != ViewModelState.created) {
      throw StateError(
        'ViewModel can only be initialized once from the created state. '
        'Current state is $_state',
      );
    }

    _owner = owner;
    _param = owner.param;
    _members = members;

    _calculateDependencies();

    for (final member in _members) {
      member.init(owner);
    }

    _integrateDependencies();

    _state = ViewModelState.active;
  }

  void _calculateDependencies() {
    for (final member in _members) {
      _dependencies[member] = {};
    }

    bool hasDependencies = false;
    void setter(ViewModelMember source, ViewModelMember target) {
      final dependents = _dependencies[source];
      assert(
        dependents != null,
        'Master member is not owned by this ViewModel. '
        'Make sure it is added to the members list',
      );
      assert(
        _dependencies.keys.contains(target),
        'Slave member is not owned by this ViewModel. '
        'Make sure it is added to the members list',
      );

      dependents!.add(target);
      hasDependencies = true;
    }

    setDependencies(setter);

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
          'Dependency feature is disabled.\n\n'
          'Reason: $error\n\n'
          'Stacktrace: $stacktrace',
        );

        _dependencies.clear();
      }
    }
  }

  void _integrateDependencies() {
    for (final MapEntry(key: source, value: targets) in _dependencies.entries) {
      if (targets.isEmpty) {
        source.addListener(source.notifyUpdateCompleted);
        continue;
      }

      // ignore: cascade_invocations
      source.addListener(() {
        if (_state != ViewModelState.active) return;

        for (final target in targets) {
          target.update();
        }

        source.notifyUpdateCompleted();
      });
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
  void update(ViewModelOwner owner) {
    if (_state != ViewModelState.active) {
      throw StateError(
        'ViewModel can be updated only from ready state. '
        'Current state is $_state',
      );
    }

    _state = ViewModelState.updating;
    _param = param;

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

    for (final member in _members) {
      member.dispose();
    }

    _owner = null;
    _param = null;
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
  }

  @override
  @visibleForOverriding
  DiagnosticsNode toDiagnosticsNode() =>
      StringProperty(debugName, '<unknown>', quoted: false);
}

abstract class ViewModelDelegate<VM extends ViewModel<Param>, Param>
    implements ViewModelMemberFactoryAccess {
  const ViewModelDelegate({required this.owner});

  @protected
  final VM owner;

  List<ViewModelMemberBase> get members;

  void setDependencies(ViewModelDependencySetter depend) {
    // Intentionally left blank
  }
}