import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_bloc/core/dispatcher.dart';
import 'package:meovm_bloc/members/bloc.dart';
import 'package:meovm_bloc/utils/error_handling.dart';

class _CounterCubit extends Cubit<int> with MeovmErrorHandler<int> {
  _CounterCubit() : super(0);

  void fail() {
    addError(Exception('boom'));
  }
}

class _BlocMemberVm extends ViewModel {
  _BlocMemberVm({required this.cubit});

  final _CounterCubit cubit;

  late final member = BlocMember<_CounterCubit, int>(
    resolver: (extract) => extract<_CounterCubit, int>(),
  );

  @override
  List<ViewModelMember> get members => [member];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    // No dependencies
  }
}

void main() {
  group('BlocMember', () {
    testWidgets('updates UI when Cubit emits values', (tester) async {
      final cubit = _CounterCubit();
      final vm = _BlocMemberVm(cubit: cubit);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlocProvider<_CounterCubit>.value(
            value: cubit,
            child: BlocVmDispatcher<_BlocMemberVm, ViewModelParameter?>(
              factory: () => vm,
              param: null,
              child: Builder(
                builder: (context) {
                  final vm = context.useVM<_BlocMemberVm>();
                  final member = vm.member;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      member.build(
                        builder: (_, _) => Text(
                          member.dataOrNull?.toString() ?? 'loading',
                          key: const ValueKey('value'),
                        ),
                      ),
                      Builder(
                        builder: (_) => Text(
                          member.isLoading ? 'loading' : 'ready',
                          key: const ValueKey('status'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially, BlocMember should expose the current cubit state immediately
      expect(find.byKey(const ValueKey('value')), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('ready'), findsOneWidget);

      cubit.emit(1);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('ready'), findsOneWidget);

      cubit.emit(2);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('captures errors and exposes hasError and error', (tester) async {
      final cubit = _CounterCubit();
      final vm = _BlocMemberVm(cubit: cubit);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlocProvider<_CounterCubit>.value(
            value: cubit,
            child: BlocVmDispatcher<_BlocMemberVm, ViewModelParameter?>(
              factory: () => vm,
              param: null,
              child: Builder(
                builder: (context) {
                  final vm = context.useVM<_BlocMemberVm>();
                  final member = vm.member;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      member.build(
                        builder: (_, _) => Text(
                          member.hasError ? 'error' : 'ok',
                          key: const ValueKey('error_state'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially no error
      expect(find.text('ok'), findsOneWidget);

      // Emit an error via BlocBase.addError, which invokes MeovmErrorHandler.onError
      cubit.fail();
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
    });
  });
}
