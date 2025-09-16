import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_bloc/core/feature.dart';
import 'package:meovm_bloc/utils/error_handling.dart';
import 'package:meta/meta.dart';

typedef BlocExtractor = B Function<B extends StateStreamable<S>, S>();

typedef BlocResolver<B, S> = B Function(BlocExtractor extractor);

/// A member that provides data from the [Bloc] and [Cubit], as well as access
/// to it.
///
/// Integration with blocs should be done through this class in the following way:
/// ```dart
/// class SomeVm extends ViewModel {
///   late final bloc = BlocMember(
///     resolver: (extractor) => extractor<SomeBloc, SomeState>(),
///   );
///
///   void doSomeStuff() {
///     SomeState = bloc.data;
///     bloc.bloc.add(SomeEvent());
///   }
/// }
/// ```
///
/// As [Bloc]s & [Cubit]s don't emit errors via its streams, to handle errors
/// with this member, simply add [MeovmErrorHandler] mixin to corresponding
/// [Bloc]/[Cubit].
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
    final previous = _bloc;
    final bloc = _bloc = resolver(owner.getBloc);
    if (bloc != previous) {
      _reattachErrorHandler(previous, bloc);

      onEvent(bloc.state);
    }

    return bloc.stream;
  }

  // ? The default error handler of StreamMemberBase is not used since blocs
  // ? don't emit errors via stream.
  void _reattachErrorHandler(
    StateStreamable<S>? prev,
    StateStreamable<S> current,
  ) {
    if (prev is MeovmErrorHandler<S>) {
      prev.removeErrorHandler(_onErrorInternal);
    }

    if (current is MeovmErrorHandler<S>) {
      current.addErrorHandler(_onErrorInternal);
    }
  }

  void _onErrorInternal(Object error, StackTrace stacktrace) {
    _onError?.call(error, stacktrace);

    _error = BlocMemberError(error: error, stackTrace: stacktrace);
    notifyChanged();
  }

  @override
  void dispose() {
    final bloc = _bloc;
    if (bloc is MeovmErrorHandler<S>) {
      bloc.removeErrorHandler(_onErrorInternal);
    }

    _bloc = _error = null;
    super.dispose();
  }
}

/// A class-container for errors caught from blocs and cubits.
///
/// Note that this will never work, unless corresponding controller have
/// [MeovmErrorHandler] mixin added to it.
@immutable
final class BlocMemberError {
  final Object error;

  final StackTrace stackTrace;

  const BlocMemberError({required this.error, required this.stackTrace});
}
