import 'package:flutter_bloc/flutter_bloc.dart';

typedef MeovmErrorHandlerListener =
    void Function(Object error, StackTrace stackTrace);

mixin MeovmErrorHandler<State> on BlocBase<State> {
  final List<MeovmErrorHandlerListener> _errorListeners = [];

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);

    for (final listener in _errorListeners) {
      listener(error, stackTrace);
    }
  }

  void addErrorHandler(MeovmErrorHandlerListener listener) {
    _errorListeners.add(listener);
  }

  void removeErrorHandler(MeovmErrorHandlerListener listener) {
    _errorListeners.remove(listener);
  }

  @override
  Future<void> close() {
    _errorListeners.clear();
    return super.close();
  }
}
