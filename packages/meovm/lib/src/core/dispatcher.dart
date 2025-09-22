import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/api.dart';
import 'package:meovm/src/core/feature.dart';

import 'retrieval.dart';

/// Factory function that creates ViewModel instance. Typically, constructors
/// of VMs itself.
typedef ViewModelFactory<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
> = VM Function();

/// Widget mixin for dispatcher implementing. Use it when you need to implement
/// your own dispatcher widget.
mixin ViewModelDispatcherBase<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
>
    on StatefulWidget {
  ViewModelFactory<VM, Param> get factory;

  Param get param;

  Widget get child;
}

/// State mixin for dispatcher implementing. Use it when you need to implement
/// your own dispatcher.
mixin ViewModelDispatcherStateBase<
  W extends ViewModelDispatcherBase<VM, Param>,
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
>
    on State<W>
    implements ViewModelOwner<Param> {
  /// VM that this dispatcher holds.
  VM get viewModel => _viewModel;

  /// Current parameter passed to VM.
  @override
  Param get param => _param;

  late VM _viewModel;

  late Param _param;

  /// Additional features of dispatcher that can be used to implement
  /// members. See [ViewModelOwnerFeature].
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
      if(feature is StateDependentVmOwnerFeature) {
        feature.bind(this);
      }

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
