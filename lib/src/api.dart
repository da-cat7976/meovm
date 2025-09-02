import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// An interface for the owner of the ViewModel, through which the ViewModel
/// and its members can interact with Riverpod and Flutter.
abstract interface class ViewModelOwner<Param> implements TickerProvider {
  Param get param;

  F getFeature<F extends ViewModelOwnerFeature>();
}

/// Base interface for external ViewModel features such as state manager
/// integration.
abstract interface class ViewModelOwnerFeature {
  // Intentionally left blank
}

/// Possible states of the ViewModel.
enum ViewModelState {
  /// ViewModel created but not yet initialized.
  created,

  /// ViewModel created, initialized and ready to work.
  active,

  /// ViewModel is being updated as a result of parameter update
  /// or other external changes.
  updating,

  /// ViewModel deinitialized and can no longer be used.
  disposed,
}

/// An interface for the lifecycle of the ViewModel, enabling its integration
/// with the State owner.
abstract interface class ViewModelLifecycle<Param> {
  /// The current state of the ViewModel.
  ViewModelState get state;

  /// Initializes the ViewModel and its members.
  ///
  /// Should correspond to [State.initState].
  void init(ViewModelOwner owner);

  /// Completely updates the ViewModel and its members when the parameters or
  /// Riverpod provider state changes.
  ///
  /// Should correspond to [State.didUpdateWidget] and [State.build].
  void update(ViewModelOwner owner);

  /// Deinitializes the ViewModel.
  ///
  /// Should correspond to [State.dispose].
  void dispose();

  /// Passes information about itself and its members to devtools.
  void debugFillProperties(DiagnosticPropertiesBuilder properties);
}

/// An interface for the lifecycle of a ViewModel member, enabling its
/// integration with the ViewModel and the State owner.
abstract interface class ViewModelMemberBase implements Listenable {
  /// Initializes the ViewModel member, binding it to the provided [owner].
  void init(ViewModelOwner owner);

  /// Updates the ViewModel member.
  ///
  /// If during this method the state of any member is changed, it should
  /// notify its subscribers.
  void update();

  /// Notifies the ViewModel member about the completion of the update.
  void notifyUpdateCompleted();

  /// Deinitializes the ViewModel member.
  ///
  /// When deinitializing the member, it should cancel all its subscriptions.
  void dispose();

  /// Converts the ViewModel member to a [DiagnosticsNode] for display in
  /// devtools.
  DiagnosticsNode toDiagnosticsNode();
}
