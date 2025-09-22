import 'package:flutter/material.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_bloc/src/core/feature.dart';

class BlocVmDispatcher<
  VM extends ViewModel<Param>,
  Param extends ViewModelParameter?
>
    extends StatefulWidget
    with ViewModelDispatcherBase<VM, Param> {
  const BlocVmDispatcher({
    super.key,
    required this.factory,
    required this.param,
    this.scope = false,
    required this.child,
  });

  @override
  final ViewModelFactory<VM, Param> factory;

  @override
  final Widget child;

  @override
  final Param param;

  @override
  final bool scope;

  @override
  BlocVmDispatcherState<VM, Param> createState() {
    return BlocVmDispatcherState<VM, Param>();
  }
}

class BlocVmDispatcherState<
  VM extends ViewModel<Param>,
  Param extends ViewModelParameter?
>
    extends State<BlocVmDispatcher<VM, Param>>
    with
        ViewModelDispatcherStateBase<BlocVmDispatcher<VM, Param>, VM, Param>,
        TickerProviderStateMixin {
  @override
  List<ViewModelOwnerFeature> get features => [BlocViewModelOwnerFeature()];
}
