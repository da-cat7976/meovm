import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';

class RiverpodViewModelOwnerFeature implements ViewModelOwnerFeature {
  final WidgetRef Function() ref;

  const RiverpodViewModelOwnerFeature({required this.ref});

  @override
  void init() {
    // Intentionally left blank
  }

  @override
  void didUpdateWidget() {
    // Intentionally left blank
  }

  @override
  void dispose() {
    // Intentionally left blank
  }
}

extension VmOwnerWidgetRef<Param extends ViewModelParameter?>
    on ViewModelOwner<Param> {
  WidgetRef get ref {
    final feature = getFeature<RiverpodViewModelOwnerFeature>();
    return feature.ref();
  }
}
