import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';

part 'vm.g.dart';

@Meovm()
final class CounterParam extends ViewModelParameter with _$CounterParam {
  final int step;

  const CounterParam({required this.step});
}

@Meovm()
class CounterVm extends ViewModel<CounterParam> with _$CounterVm {
  @override
  late final _count = member.value(initial: 0);

  @override
  late final positive = member.value(resolver: (_) => _count.data * param.step);

  @override
  late final negative = member.value(
    resolver: (_) => _count.data * -param.step,
  );

  void increment() {
    _count.data++;
  }
}
