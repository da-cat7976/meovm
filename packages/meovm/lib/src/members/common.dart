import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/view_model.dart';
import 'package:meovm/src/members/utils.dart';
import 'package:meovm_api/meovm_api.dart';

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
    with ChangeNotifier, FreezableDataMixin<T>, NotifierChangeTracker {
  UpdateNotifierMember({super.debugName, bool frozen = false}) {
    /// ? Note that this will be unsafe, if data will be set before this
    this.frozen = frozen;
  }

  @override
  @mustCallSuper
  void update() {
    final current = dataOrNull;
    final updated = updateData(resolve(current));
    if (updated == current) return;

    notifyChanged();
  }

  @override
  @meovmInternal
  set frozen(bool value) {
    final current = dataOrNull;
    super.frozen = value;

    if (value) return;
    final maybeSkipped = dataOrNull;
    if (maybeSkipped == current) return;

    notifyChanged();
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
