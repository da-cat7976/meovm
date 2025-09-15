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
  Param extends ViewModelParameter?
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
    for (final feature in _features) {
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

    for (final feature in _features) {
      feature.didUpdateWidget();
    }

    final param = _param = widget.param;
    final oldParam = oldWidget.param;
    if (param?.shouldUpdateDependencies(oldParam) ?? false) {
      _viewModel.updateDependencies();
    }

    if (param != oldWidget.param) {
      _viewModel.update();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    for (final feature in _features) {
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

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _viewModel.debugFillProperties(properties);
  }
  // coverage:ignore-end
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

class ViewModelDispatcher<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
>
    extends StatefulWidget
    with ViewModelDispatcherBase<VM, Param> {
  const ViewModelDispatcher({
    super.key,
    required this.child,
    required this.factory,
    required this.param,
  }) : _features = const [];

  @visibleForTesting
  const ViewModelDispatcher.test({
    super.key,
    required this.child,
    required this.factory,
    required this.param,
    required List<ViewModelOwnerFeature> features,
  }) : _features = features;

  @override
  final ViewModelFactory<VM, Param> factory;

  @override
  final Param param;

  @override
  final Widget child;

  final List<ViewModelOwnerFeature> _features;

  @override
  ViewModelDispatcherState<VM, Param> createState() {
    return ViewModelDispatcherState<VM, Param>();
  }
}

class ViewModelDispatcherState<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
>
    extends State<ViewModelDispatcher<VM, Param>>
    with
        ViewModelDispatcherStateBase<ViewModelDispatcher<VM, Param>, VM, Param>,
        TickerProviderStateMixin {
  @override
  List<ViewModelOwnerFeature> get features => widget._features;
}
