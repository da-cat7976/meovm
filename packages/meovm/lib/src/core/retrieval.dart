import 'package:flutter/material.dart';

import 'api.dart';

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
  VM useVM<VM extends ViewModelLifecycle>({bool listen = true}) {
    final inherited = listen
        ? dependOnInheritedWidgetOfExactType<ViewModelProvider<VM>>()
        : getInheritedWidgetOfExactType<ViewModelProvider<VM>>();

    assert(
    inherited is ViewModelProvider<VM>,
    'No ViewModel with type $VM found in the widget tree',
    );

    return inherited!.viewModel;
  }

  // ignore: strict_raw_type
  VM? useVmOrNull<VM extends ViewModelLifecycle>({bool listen = true}) {
    final inherited = listen
        ? dependOnInheritedWidgetOfExactType<ViewModelProvider<VM>>()
        : getInheritedWidgetOfExactType<ViewModelProvider<VM>>();

    return inherited?.viewModel;
  }

  Param useParam<Param>({bool listen = true}) {
    final inherited = listen
        ? dependOnInheritedWidgetOfExactType<ViewModelParamProvider<Param>>()
        : getInheritedWidgetOfExactType<ViewModelParamProvider<Param>>();

    assert(
    inherited is ViewModelParamProvider<Param>,
    'No ViewModel param with type $Param found in the widget tree',
    );

    return inherited!.param;
  }

  Param? useParamOrNull<Param>({bool listen = true}) {
    final inherited = listen
        ? dependOnInheritedWidgetOfExactType<ViewModelParamProvider<Param>>()
        : getInheritedWidgetOfExactType<ViewModelParamProvider<Param>>();

    return inherited?.param;
  }
}
// coverage:ignore-end