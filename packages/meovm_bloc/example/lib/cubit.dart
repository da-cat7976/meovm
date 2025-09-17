import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meovm_bloc/meovm_bloc.dart';

class CounterCubit extends Cubit<int> with MeovmErrorHandler {
  CounterCubit() : super(0);

  void increment() {
    emit(state + 1);
  }
}
