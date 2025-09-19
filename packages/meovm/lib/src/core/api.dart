import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meovm_api/meovm_api.dart';

/// An interface for the owner of the ViewModel, through which the ViewModel
/// and its members can interact with Flutter.
abstract interface class ViewModelOwner<Param extends ViewModelParameter?>
    implements TickerProvider, MeovmAutoVmOwner<Param> {
  Param get param;

  /// Requests a feature from the owner.
  ///
  /// Throws [ArgumentError] if the feature is not found.
  F getFeature<F extends ViewModelOwnerFeature>();
}

/// Base interface for external ViewModel features such as state manager
/// integration.
abstract interface class ViewModelOwnerFeature implements MeovmAutoVmFeature {
  /// Represents [State.initState].
  void init();

  /// Represents [State.didChangeDependencies].
  void didChangeDependencies();

  /// Represents [State.didUpdateWidget].
  void didUpdateWidget();

  /// Represents [State.dispose].
  void dispose();
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
abstract interface class ViewModelLifecycle<Param extends ViewModelParameter?>
    implements MeovmAutoVm<Param> {
  /// The current state of the ViewModel.
  ViewModelState get state;

  /// Initializes the ViewModel and its members.
  ///
  /// Should correspond to [State.initState].
  void init(ViewModelOwner<Param> owner);

  /// Completely updates the ViewModel and its members when the parameters or
  /// owner widget rebuilds for other reason.
  ///
  /// Should correspond to [State.didUpdateWidget] and [State.build].
  void update();

  /// Updates dependency graph of the ViewModel's members.
  ///
  /// Should be called when necessary only, as it is somewhat expensive due to
  /// topological sort.
  void updateDependencies();

  /// Deinitializes the ViewModel.
  ///
  /// Should correspond to [State.dispose].
  void dispose();

  /// Passes information about itself and its members to devtools.
  void debugFillProperties(DiagnosticPropertiesBuilder properties);
}

/// An interface for the lifecycle of a ViewModel member, enabling its
/// integration with the ViewModel and the State owner.
abstract interface class ViewModelMemberBase
    implements Listenable, MeovmAutoVmMember {
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

/// Base class for ViewModel configuration, that is passed to the ViewModel.
///
/// Other ViewModels and their members can be passed through this parameter.
/// The ViewModel configured with this parameter can use them.
/// The lifecycle of external members, as well as their replacement with others,
/// is handled by the configured ViewModel.
@immutable
abstract base mixin class ViewModelParameter implements MeovmAutoVmParameter {
  const ViewModelParameter();

  /// Compares this with [oldParam] and returns `true` if this has changes
  /// in its fields that should trigger a dependency update.
  bool shouldUpdateDependencies(ViewModelParameter? oldParam);
}
