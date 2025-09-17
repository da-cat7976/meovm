import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/meovm_riverpod.dart';

import 'vm.dart';

void main() {
  runApp(ProviderScope(child: MeovmExample()));
}

class MeovmExample extends StatelessWidget {
  const MeovmExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return RiverpodVmDispatcher(
      factory: CounterVm.new,
      param: CounterParam(step: 1),
      child: Builder(
        builder: (context) {
          final vm = context.useVM<CounterVm>();

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Positive'),
                  vm.positive.build(
                    builder: (context, _) => Text(vm.positive.data.toString()),
                  ),
                  SizedBox(height: 32),
                  Text('Negative'),
                  vm.negative.build(
                    builder: (context, _) => Text(vm.negative.data.toString()),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(onPressed: vm.increment),
          );
        },
      ),
    );
  }
}
