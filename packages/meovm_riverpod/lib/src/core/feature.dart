import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/meovm_riverpod.dart';

class RiverpodViewModelOwnerFeature
    extends
        StateDependentVmOwnerFeature<
          RiverpodVmDispatcherState<
            ViewModel<ViewModelParameter?>,
            ViewModelParameter?
          >,
          ViewModel,
          ViewModelParameter?
        > {
  WidgetRef get ref => state.ref;

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
}

extension VmOwnerWidgetRef<Param extends ViewModelParameter?>
    on ViewModelOwner<Param> {
  WidgetRef get ref {
    final feature = getFeature<RiverpodViewModelOwnerFeature>();
    return feature.ref;
  }
}
