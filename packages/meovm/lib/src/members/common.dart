import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/view_model.dart';
import 'package:meovm/src/members/freeze.dart';

/// Base class for all ViewModel members, on which it is allowed to build widgets.
///
/// See also: [ViewModelMemberBuilder].
abstract class BuildableViewModelMember extends ViewModelMember {
  BuildableViewModelMember({super.debugName});
}

/// The base class useful for all ViewModel members, the state of which is formed
/// based on data obtained from business state or other members.
///
/// This class implements the freezing update function, which allows you to
/// temporarily ignore data changes, while still preserving them for later use.
abstract class UpdateNotifierMember<T> extends BuildableViewModelMember
    with ChangeNotifier, FreezableDataMixin<T> {
  UpdateNotifierMember({super.debugName, bool frozen = false}) {
    this.frozen = frozen;
  }

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

  bool _wasChanged = false;

  @override
  @mustCallSuper
  void update() {
    final current = dataOrNull;
    final updated = updateData(resolve(current));
    if (updated == current) return;

    _wasChanged = true;
    notifyListeners();
  }

  @override
  set frozen(bool value) {
    final current = dataOrNull;
    super.frozen = value;

    if (value) return;
    final maybeSkipped = dataOrNull;
    if (maybeSkipped == current) return;

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

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
    debugName,
    dataOrNull?.toString() ?? '<non ready>',
    quoted: false,
  );
}
