import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/api.dart';

typedef ViewModelFactory<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
> = VM Function();

mixin ViewModelDispatcherBase<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
>
    on StatefulWidget {
  ViewModelFactory<VM, Param> get factory;

  Param get param;

  Widget get child;
}

mixin ViewModelDispatcherStateBase<
  W extends ViewModelDispatcherBase<VM, Param>,
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter
>
    on State<W>
    implements ViewModelOwner<Param> {
  VM get viewModel => _viewModel;

  @override
  Param get param => _param;

  late VM _viewModel;

  late Param _param;

  @visibleForOverriding
  List<ViewModelOwnerFeature> get features => [];

  late List<ViewModelOwnerFeature> _features;

  @override
  @nonVirtual
  F getFeature<F extends ViewModelOwnerFeature>() {
    for (final feature in _features) {
      if (feature is F) return feature;
    }

    throw ArgumentError('Feature $F not found');
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    _features = features;
    for(final feature in _features) {
      feature.init();
    }

    _viewModel = widget.factory();
    _param = widget.param;
    _viewModel.init(this);
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);

    for(final feature in _features) {
      feature.didUpdateWidget();
    }

    final param = _param = widget.param;
    if (param.shouldUpdateDependencies(oldWidget.param)) {
      _viewModel.updateDependencies();
    }

    if (param != oldWidget.param) {
      _viewModel.update();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    for(final feature in _features) {
      feature.dispose();
    }

    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _viewModel.update();

    return ViewModelParamProvider(
      param: _param,
      child: ViewModelProvider<VM>(viewModel: _viewModel, child: widget.child),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _viewModel.debugFillProperties(properties);
  }
}

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
