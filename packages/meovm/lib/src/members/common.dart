import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/view_model.dart';

/// Base class for all ViewModel members, on which it is allowed to build widgets.
///
/// See also: [ViewModelMemberBuilder].
abstract class BuildableViewModelMember extends ViewModelMember {
  BuildableViewModelMember({
    super.debugName,
  });
}

/// The base class for all ViewModel members, the state of which is formed
/// based on data obtained from riverpod providers or other members.
///
/// This class implements the freezing update function, which allows you to
/// temporarily ignore data changes, while still preserving them for later use.
abstract class UpdateNotifierMember<T> extends BuildableViewModelMember
    with ChangeNotifier {
  UpdateNotifierMember({
    super.debugName,
    bool frozen = false,
  }) : _frozen = frozen;

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

  /// Включена ли сейчас функция заморозки.
  bool get frozen => _frozen;

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
  @nonVirtual
  bool get wasChanged => _wasChanged;

  T? _data;

  T? _skippedData;

  bool _frozen = false;

  bool _wasChanged = false;

  @override
  @mustCallSuper
  void update() {
    final data = resolve(_data);
    final frozen = _frozen && _data != null;
    if (_data == data) {
      if (frozen) _skippedData = data;
      return;
    }

    _data = data;
    _wasChanged = true;
    notifyListeners();
  }

  @override
  @mustCallSuper
  void notifyUpdateCompleted() {
    _wasChanged = false;
  }

  /// Updates the data stored by the member.
  ///
  /// Called on every [update] call.
  @visibleForOverriding
  T resolve(T? data);

  /// Freezes the current state of the member.
  ///
  /// All updates that occurred since the call of this method are
  /// saved within this member, and notifications to subscribers are not updated.
  ///
  /// Repeated calls to this method are safe and do not result in any
  /// changes.
  void freeze() => _frozen = true;

  /// Unfreezes the current state of the member.
  ///
  /// All updates that occurred since the call of this method are
  /// saved within this member, and notifications to subscribers are not updated.
  ///
  /// Repeated calls to this method are safe and do not result in any
  /// changes.
  void unfreeze() {
    _frozen = false;
    final data = _skippedData ?? _data;
    _skippedData = null;
    if (_data == data) return;

    _data = data;
    _wasChanged = true;
    notifyListeners();
  }

  /// Executes the passed function, freezing the state during its execution.
  ///
  /// Equivalent to:
  /// ```dart
  /// someMember.freeze();
  /// // code from action body
  /// someMember.unfreeze();
  /// ```
  Future<R> doFrozen<R>(FutureOr<R> Function() action) async {
    freeze();
    final result = await action();
    unfreeze();

    return result;
  }

  @override
  @mustCallSuper
  void dispose() {
    _data = null;
    super.dispose();
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
        debugName,
        _data?.toString() ?? '<non ready>',
        quoted: false,
      );
}
