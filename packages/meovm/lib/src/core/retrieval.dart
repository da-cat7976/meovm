import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'dispatcher.dart';

class ViewModelProvider<VM extends ViewModelLifecycle> extends InheritedWidget {
  ViewModelProvider({required super.child, required this.viewModel})
    : super(key: ValueKey(viewModel));

  final VM viewModel;

  @override
  bool updateShouldNotify(covariant ViewModelProvider<VM> oldWidget) =>
      oldWidget.viewModel != viewModel;
}

class ViewModelParamProvider<Param> extends InheritedWidget {
  ViewModelParamProvider({required super.child, required this.param})
    : super(key: ValueKey(param));

  final Param param;

  @override
  bool updateShouldNotify(covariant ViewModelParamProvider<Param> oldWidget) =>
      oldWidget.param != param;
}

// ? Since this is an extension providing access to VMs and params using
// ? InheritedWidget mechanism, testing this code is not necessary.
// coverage:ignore-start
extension ViewModelContext on BuildContext {
  // ignore: strict_raw_type
  /// {@template vm_context.use_vm}
  ///
  /// Retrieves a ViewModel of type [VM] from the widget tree.
  ///
  /// If [scope] is `true`, also looks for scope and allows you to retrieve
  /// a ViewModel by its super-type. Note:
  /// 1. It is a relative expensive operation.
  /// 2. It works only if `scope: true` is passed to [ViewModelDispatcherBase].
  ///
  /// If [listen] is `true`, subscribes current element to the replacements
  /// of the ViewModel.
  ///
  /// {@endtemplate}
  VM useVM<VM extends ViewModelLifecycle>({
    bool listen = true,
    bool scope = false,
  }) {
    final vm = useVmOrNull<VM>(listen: listen, scope: scope);

    assert(vm is VM, 'No ViewModel with type $VM found in the widget tree');
    return vm!;
  }

  // ignore: strict_raw_type
  /// {@macro vm_context.use_vm}
  VM? useVmOrNull<VM extends ViewModelLifecycle>({
    bool listen = true,
    bool scope = false,
  }) {
    final inherited = _listenAwareRetrieveInherited<ViewModelProvider<VM>>(
      listen,
    );

    VM? vm = inherited?.viewModel;

    if (scope && vm == null) {
      final scope = _listenAwareRetrieveInherited<ViewModelScope>(listen);

      vm = scope?.getVm<VM>();
    }

    return vm;
  }

  /// {@template vm_context.use_param}
  ///
  /// Retrieves a ViewModel parameter of type [Param] from the widget tree.
  ///
  /// If [scope] is `true`, also looks for scope and allows you to retrieve
  /// a ViewModel parameter by its super-type. Note:
  /// 1. It is a relative expensive operation.
  /// 2. It works only if `scope: true` is passed to [ViewModelDispatcherBase].
  ///
  /// If [listen] is `true`, subscribes current element to the replacements
  /// of the ViewModel parameter.
  ///
  /// {@endtemplate}
  Param useParam<Param extends ViewModelParameter>({
    bool listen = true,
    bool scope = false,
  }) {
    final param = useParamOrNull<Param>(listen: listen, scope: scope);

    assert(
      param is Param,
      'No ViewModel param with type $Param found in the widget tree',
    );

    return param!;
  }

  /// {@macro vm_context.use_param}
  Param? useParamOrNull<Param extends ViewModelParameter>({
    bool listen = true,
    bool scope = false,
  }) {
    final provider =
        _listenAwareRetrieveInherited<ViewModelParamProvider<Param>>(listen);

    Param? param = provider?.param;

    if (scope && param == null) {
      final scope = _listenAwareRetrieveInherited<ViewModelScope>(listen);
      param = scope?.getParam();
    }

    return param;
  }

  T? _listenAwareRetrieveInherited<T extends InheritedWidget>(bool listen) {
    return listen
        ? dependOnInheritedWidgetOfExactType<T>()
        : getInheritedWidgetOfExactType<T>();
  }
}
// coverage:ignore-end

class ViewModelScope extends InheritedWidget {
  const ViewModelScope._({
    required super.child,
    required Map<ViewModelLifecycle, ViewModelParameter?> vms,
  }) : _vms = vms;

  factory ViewModelScope({
    required BuildContext context,
    required ViewModelLifecycle vm,
    required ViewModelParameter? param,
    required Widget child,
  }) {
    final parent = context.dependOnInheritedWidgetOfExactType<ViewModelScope>();

    return ViewModelScope._(
      vms: {...?parent?._vms, vm: param},
      child: child, // fmt
    );
  }

  final Map<ViewModelLifecycle, ViewModelParameter?> _vms;

  @override
  bool updateShouldNotify(covariant ViewModelScope oldWidget) {
    const eq = MapEquality();

    return eq.equals(_vms, oldWidget._vms);
  }

  VM? getVm<VM extends ViewModelLifecycle>() {
    for (final vm in _vms.keys) {
      if (vm is VM) return vm;
    }

    return null;
  }

  Param? getParam<Param extends ViewModelParameter>() {
    for (final param in _vms.values) {
      if (param is Param) return param;
    }

    return null;
  }
}
