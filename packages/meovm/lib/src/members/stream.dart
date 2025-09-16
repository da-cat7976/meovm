import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meovm/src/members/common.dart';
import 'package:meovm/src/members/utils.dart';

typedef StreamMemberResolver<T> = Stream<T> Function();

typedef StreamMemberErrorListener =
    void Function(Object error, StackTrace stacktrace);

typedef StreamMemberDoneListener = void Function();

abstract class StreamMemberBase<T> extends BuildableViewModelMember
    with ChangeNotifier, FreezableDataMixin<T>, NotifierChangeTracker {
  @visibleForOverriding
  StreamMemberErrorListener? get onError => null;

  @visibleForOverriding
  bool get cancelOnError => false;

  @nonVirtual
  bool get isActive => _subscription != null;

  Stream<T>? _stream;

  StreamSubscription<T>? _subscription;

  @protected
  Stream<T> resolve();

  @override
  @mustCallSuper
  void update() {
    final updated = resolve();
    if (updated != _stream) {
      _stream = updated;
      _subscription?.cancel();
      _subscription = updated.listen(
        onEvent,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }
  }

  @protected
  @mustCallSuper
  void onEvent(T event) {
    final current = dataOrNull;
    final updated = updateData(event);
    if (updated == current) return;

    notifyChanged();
  }

  @protected
  @mustCallSuper
  void onDone() {
    _subscription?.cancel();
    _stream = _subscription = null;
  }

  @override
  @mustCallSuper
  void dispose() {
    _subscription?.cancel();
    _stream = _subscription = null;
    super.dispose();
  }
}

class StreamMember<T> extends StreamMemberBase<T> {
  StreamMember({
    required this.resolver,
    this.onError,
    required this.cancelOnError,
  });

  final StreamMemberResolver<T> resolver;

  @override
  final StreamMemberErrorListener? onError;

  @override
  final bool cancelOnError;

  @override
  Stream<T> resolve() {
    return resolver();
  }
}
