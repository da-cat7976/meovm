import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meovm/src/members/common.dart';
import 'package:meovm/src/members/freeze.dart';

typedef StreamMemberResolver<T> = Stream<T> Function();

typedef StreamMemberErrorListener =
    void Function(Object error, StackTrace stacktrace);

typedef StreamMemberDoneListener = void Function();

abstract class StreamMemberBase<T> extends BuildableViewModelMember
    with ChangeNotifier, FreezableDataMixin<T> {
  @visibleForOverriding
  StreamMemberResolver<T> get resolve;

  @visibleForOverriding
  StreamMemberErrorListener? get onError => null;

  @visibleForOverriding
  StreamMemberDoneListener? get onDone => null;

  @visibleForOverriding
  bool get cancelOnError => true;

  Stream<T>? _stream;

  StreamSubscription<T>? _subscription;

  @nonVirtual
  bool get wasChanged => _wasChanged;

  bool _wasChanged = false;

  @override
  @mustCallSuper
  void update() {
    final updated = resolve();
    if (updated != _stream) {
      _subscription?.cancel();
      _subscription = updated.listen(
        onEvent,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }
  }

  @mustCallSuper
  void onEvent(T event) {
    final current = dataOrNull;
    final updated = updateData(event);
    if (updated == current) return;

    _wasChanged = true;
    notifyListeners();
  }

  @override
  @mustCallSuper
  void notifyUpdateCompleted() {
    _wasChanged = false;
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
    required this.resolve,
    this.onError,
    this.onDone,
    required this.cancelOnError,
  });

  @override
  final StreamMemberResolver<T> resolve;

  @override
  final StreamMemberErrorListener? onError;

  @override
  final StreamMemberDoneListener? onDone;

  @override
  final bool cancelOnError;
}
