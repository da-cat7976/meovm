import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_bloc/core/dispatcher.dart';

class BlocViewModelOwnerFeature
    extends
        StateDependentVmOwnerFeature<
          BlocVmDispatcherState,
          ViewModel,
          ViewModelParameter?
        > {
  @override
  void init() {
    // Intentionally left blank
  }

  @override
  void didChangeDependencies() {
    // Intentionally left blank
  }

  @override
  void didUpdateWidget() {
    // Intentionally left blank
  }

  B getBloc<B extends StateStreamable>() {
    return state.context.read<B>();
  }
}
