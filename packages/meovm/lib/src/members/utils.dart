import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:meovm/src/core/view_model.dart';
import 'package:meta/meta.dart';

/// A mixin that provides a way to freeze the current state of the member.
///
/// When frozen, the member will not update its state, but store updates
/// for future use. On unfreeze, the member will update its state with the last
/// skipped data.
mixin FreezableDataMixin<T> on ViewModelMember {
  /// The current state of the member.
  ///
  /// If frozen is active, it returns the last value returned by [resolve]
  /// before the call to [freeze].
  ///
  /// If [T] is not nullable, then accessing this getter before
  /// initialization and the first update will result in a throw of
  /// [TypeError].
  T get data {
    final data = _data;
    assert(data is T, 'ViewModel should be initialized first');

    return data as T;
  }

  @protected
  T? get dataOrNull {
    return _data;
  }

  /// Updates data or stores it for future if frozen.
  @protected
  T updateData(T data) {
    final $data = _data;
    final frozen = _frozen && $data is T;
    if (frozen) {
      _skippedData = data;
      return $data;
    }

    return _data = data;
  }

  /// Is freezing enabled.
  ///
  /// If was set to `true`, all updates that occurred since setting are
  /// saved within this member.
  ///
  /// Repeated setting with same value are safe and do not result in any
  /// changes.
  bool get frozen => _frozen;

  set frozen(bool value) {
    if (!_frozen) {
      _data = _skippedData ?? _data;
      _skippedData = null;
    }

    _frozen = value;
  }

  T? _data;

  T? _skippedData;

  bool _frozen = false;

  /// Executes the passed function, freezing the state during its execution.
  ///
  /// Equivalent to:
  /// ```dart
  /// someMember.freeze();
  /// // code from action body
  /// someMember.unfreeze();
  /// ```
  @nonVirtual
  Future<R> doFrozen<R>(FutureOr<R> Function() action) async {
    frozen = true;
    final result = await action();
    frozen = false;

    return result;
  }

  @override
  @mustCallSuper
  void dispose() {
    _data = _skippedData = null;
    super.dispose();
  }
}

mixin ChangeTracker on ViewModelMember {
  /// {@macro view_model_member.wasChanged}
  bool get wasChanged => _wasChanged;

  bool _wasChanged = false;

  @mustCallSuper
  void notifyChanged() {
    _wasChanged = true;
  }

  @override
  @mustCallSuper
  void notifyUpdateCompleted() {
    _wasChanged = false;
    super.notifyUpdateCompleted();
  }
}

mixin NotifierChangeTracker on ViewModelMember, ChangeNotifier {
  /// {@template view_model_member.wasChanged}
  ///
  /// Were the member's data changed during the ViewModel update process.
  ///
  /// Can be `true` only during the entire ViewModel update, to which the member
  /// belongs, or the partial update according to dependencies.
  ///
  /// Not intended for use outside ViewModel.
  ///
  /// {@endtemplate}
  bool get wasChanged => _wasChanged;

  bool _wasChanged = false;

  @mustCallSuper
  void notifyChanged() {
    _wasChanged = true;
    notifyListeners();
  }

  @override
  @mustCallSuper
  void notifyUpdateCompleted() {
    _wasChanged = false;
    super.notifyUpdateCompleted();
  }
}
