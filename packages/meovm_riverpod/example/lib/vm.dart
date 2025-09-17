import 'package:meovm/meovm.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:meovm_riverpod/meovm_riverpod.dart';
import 'package:riverpod_example/riverpod.dart';

part 'vm.g.dart';

@Meovm()
final class CounterParam extends ViewModelParameter with _$CounterParam {
  final int step;

  const CounterParam({required this.step});
}

@Meovm()
class CounterVm extends ViewModel<CounterParam> with _$CounterVm {
  @override
  late final _counter = member.actionGroup<Counter, int>((ref, data) {
    return (
      state: ref.watch(counterProvider),
      group: ref.watch(counterProvider.notifier),
    );
  });

  @override
  late final positive = member.value(
    resolver: (_) => _counter.data * param.step,
  );

  @override
  late final negative = member.value(
    resolver: (_) => _counter.data * -param.step,
  );

  void increment() {
    _counter.notifier.increment();
  }
}
