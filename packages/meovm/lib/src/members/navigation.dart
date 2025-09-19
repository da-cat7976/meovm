
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/view_model.dart';
import 'package:meovm/src/members/utils.dart';
import 'package:meovm/src/members/value.dart';
import 'package:meovm_api/meovm_api.dart';

/// Member that allows controlling navigation from the ViewModel.
///
/// It is assumed that navigation is performed at the widget level
/// using [NavigationMemberListener.useNavigation] based on the value
/// stored in this member:
/// ```dart
/// class SomeVm extends ViewModel {
///   late final navigation = member.navigation<String?>();
///
///   @override
///   List<ViewModelMember> get members => [navigation];
///
///   void notify() {
///     navigation.data = 'Hello, world!';
///   }
/// }
///
/// class SomeWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final vm = context.useVM<SomeVm>();
///
///     vm.navigation.useNavigation(
///           (context, data) {
///         if (data == null) return;
///         final messenger = ScaffoldMessenger.of(context);
///
///         messenger.showSnackBar(
///           SnackBar(
///             content: Text(data),
///           ),
///         );
///       },
///     );
///
///     return const SizedBox();
///   }
/// }
/// ```
class NavigationMember<T> extends ValueMember<T> {
  NavigationMember({
    super.initial,
    super.resolver,
    super.debugName,
  })  : _autoReset = false,
        _autoResetValue = null;

  factory NavigationMember.autoReset({
    required T initial,
    String? debugName,
  }) {
    return NavigationMember._autoResetInternal(
      initial: initial,
      debugName: debugName,
      autoReset: true,
    );
  }

  NavigationMember._autoResetInternal({
    required T initial,
    super.debugName,
    bool autoReset = false,
  })  : _autoReset = autoReset,
        _autoResetValue = initial;

  final bool _autoReset;

  final T? _autoResetValue;

  @override
  @meovmInternal
  set data(T value) {
    if (_autoReset) super.data = _autoResetValue as T;
    super.data = value;
  }

  @override
  DiagnosticsNode toDiagnosticsNode() {
    final node = super.toDiagnosticsNode();

    return StringProperty(
      debugName,
      node.value.toString(),
      quoted: false,
      description: 'Member that controls navigation',
    );
  }
}

/// Member that allows controlling modal window from the ViewModel.
///
/// It is assumed that the modal window is opened at the widget level
/// using [ModalFlowMemberListener.useModal] based on the value
/// stored in this member:
///
/// Example usage:
/// ```dart
/// class SomeVm extends ViewModel {
///  late final modal = member.modalFlow<String>();
///
///  @override
///  List<ViewModelMember> get members => [modal];
///
///  Future<void> showModal() async {
///    final text = await modal.requestModal();
///    print(text);
///  }
/// }
///
/// class SomeWidget extends HookWidget {
///  @override
///  Widget build(BuildContext context) {
///    final vm = context.useVM<SomeVm>();
///
///    vm.modal.useModal(
///          (context) => showModalBottomSheet<String>(
///        context: context,
///        builder: (context) => HookBuilder(
///          builder: (context) {
///            final ctr = useTextEditingController();
///
///            return Column(
///              children: [
///                TextField(
///                  controller: ctr,
///                ),
///                ElevatedButton(
///                  onPressed: () => context.pop(ctr.text),
///                  child: const Text('OK'),
///                ),
///              ],
///            );
///          },
///        ),
///      ),
///    );
///
///    return ElevatedButton(
///      onPressed: vm.showModal,
///      child: const Text('Show modal'),
///    );
///  }
/// }
/// ```
class ModalFlowMember<Result> extends ViewModelMember with ChangeNotifier, NotifierChangeTracker {
  ModalFlowMember({
    super.debugName,
  });

  /// The result of the last modal window call.
  ///
  /// If the modal window has never been called or has not returned a result
  /// (e.g., it was closed), then the returned value will be `null`.
  ///
  /// To check if the modal window is open, you should use [isModalRequested].
  @nonVirtual
  Result? get result => _result;

  /// Whether a modal window opening request is currently being processed.
  ///
  /// Returns `true` during the entire time between calls to [requestModal] and
  /// [notifyCompleted].
  @nonVirtual
  bool get isModalRequested => _completer is Completer;

  /// Whether to close the modal window.
  ///
  /// Equals `true` if between calls to [requestModal] and [notifyCompleted]
  /// [reset] was called.
  @nonVirtual
  bool get shouldCloseModal => _shouldCloseModal;

  Result? _result;

  Completer<Result?>? _completer;

  bool _shouldCloseModal = false;

  @override
  void update() {
    // Intentionally left blank
  }

  /// Requests the opening of a modal window. Returns a Future with the result
  /// of the modal window call.
  ///
  /// If a modal window has already been requested, but the notification about
  /// its closure has not yet arrived, reopening will not occur, and the
  /// Future associated with the previous request will be returned.
  @mustCallSuper
  @meovmInternal
  Future<Result?> requestModal() async {
    if (isModalRequested) return _completer!.future;
    _completer = Completer();

    _result = null;
    _shouldCloseModal = false;
    notifyListeners();

    return _completer!.future;
  }

  /// Notifies the member about the closure of the modal window and passes its result.
  ///
  /// If a modal window was not requested, the notification will be ignored.
  @mustCallSuper
  void notifyCompleted(Result? result) {
    if (!isModalRequested) return;

    _completer!.complete(result);
    _result = result;
    _completer = null;
    _shouldCloseModal = false;

    notifyChanged();
  }

  /// Resets the member's state, closing the modal window if it was requested.
  @meovmInternal
  @mustCallSuper
  void reset() {
    if (isModalRequested) {
      _completer!.complete(null);
      _shouldCloseModal = true;
    }
    _result = null;
    _completer = null;

    notifyListeners();
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
        debugName,
        isModalRequested
            ? '<requested>'
            : _result?.toString() ?? '<not requested>',
        quoted: false,
        description: 'Member that controls modal flow',
      );
}
