import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';

class RiverpodVmDispatcher<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter
>
    extends ConsumerStatefulWidget
    with ViewModelDispatcherBase<VM, Param> {
  @override
  final ViewModelFactory<VM, Param> factory;

  @override
  final Param param;

  @override
  final Widget child;

  @override
  RiverpodVmDispatcherState<VM, Param> createState() {
    return RiverpodVmDispatcherState<VM, Param>();
  }

  const RiverpodVmDispatcher({
    super.key,
    required this.child,
    required this.factory,
    required this.param,
  });
}

class RiverpodVmDispatcherState<
  VM extends ViewModelLifecycle<Param>,
  Param extends ViewModelParameter
>
    extends ConsumerState<RiverpodVmDispatcher<VM, Param>>
    with
        ViewModelDispatcherStateBase<
          RiverpodVmDispatcher<VM, Param>,
          VM,
          Param
        >,
        TickerProviderStateMixin {
  @override
  F getFeature<F extends ViewModelOwnerFeature>() {
    // TODO: implement getFeature
    throw UnimplementedError();
  }
}
