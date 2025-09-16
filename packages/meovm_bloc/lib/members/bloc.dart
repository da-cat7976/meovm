import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_bloc/core/feature.dart';
import 'package:meta/meta.dart';

typedef BlocExtractor = B Function<B extends StateStreamable<S>, S>();

typedef BlocResolver<B, S> = B Function(BlocExtractor extractor);

class BlocMember<B extends StateStreamable<S>, S> extends StreamMemberBase<S> {
  BlocMember({
    required this.resolver,
    StreamMemberErrorListener? onError,
    this.cancelOnError = false,
  }) : _onError = onError;

  final BlocResolver<B, S> resolver;

  final StreamMemberErrorListener? _onError;

  @override
  final bool cancelOnError;

  B? _bloc;

  BlocMemberError? _error;

  B get bloc {
    assert(_bloc != null, 'Member should be initialized first!');
    return _bloc!;
  }

  @override
  S? get dataOrNull => super.dataOrNull;

  bool get hasError => _error != null;

  bool get isLoading => dataOrNull == null && dataOrNull is! S || !isActive;

  BlocMemberError? get error => _error;

  @override
  Stream<S> resolve() {
    final bloc = _bloc = resolver(owner.getBloc);
    if (bloc != _bloc) {
      onEvent(bloc.state);
    }

    return bloc.stream;
  }

  @override
  late StreamMemberErrorListener? onError = _onErrorInternal;

  void _onErrorInternal(Object error, StackTrace stacktrace) {
    _onError?.call(error, stacktrace);

    _error = BlocMemberError(error: error, stackTrace: stacktrace);
    notifyChanged();
  }
}

@immutable
final class BlocMemberError {
  final Object error;

  final StackTrace stackTrace;

  const BlocMemberError({required this.error, required this.stackTrace});
}
