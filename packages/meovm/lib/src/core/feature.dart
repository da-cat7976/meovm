import 'package:meta/meta.dart';

import 'api.dart';
import 'dispatcher.dart';

abstract class StateDependentVmOwnerFeature<
  S extends ViewModelDispatcherStateBase<
    ViewModelDispatcherBase<VM, Param>,
    VM,
    Param
  >,
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter?
>
    implements ViewModelOwnerFeature {
  @protected
  S get state {
    final state = _state;
    if (state == null) {
      throw StateError('Feature is not bound to state');
    }

    return state;
  }

  S? _state;

  @internal
  @nonVirtual
  void bind(ViewModelDispatcherStateBase state) {
    if (state is! S) {
      throw StateError(
        'This feature can\'t be bound to state of type ${state.runtimeType}',
      );
    }

    _state = state;
  }

  @override
  @mustCallSuper
  void dispose() {
    _state = null;
  }
}
