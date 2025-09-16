import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meovm/src/core/api.dart';
import 'package:meovm/src/members/common.dart';
import 'package:meovm/src/members/utils.dart';

typedef MemberInitializer<T> = T Function();

typedef MemberUpdater<T extends Listenable> = void Function(T ctr);

typedef MemberUpdaterWithResult<T extends Listenable, R> = R Function(T ctr);

/// A member that allows the ViewModel to work with a [TextEditingController].
///
/// Changes to the [TextEditingController] are tracked by this member.
class EditableTextMember extends BuildableViewModelMember with ChangeTracker {
  EditableTextMember({
    this.initText,
    this.onUpdate,
    this.debounce = Duration.zero,
    super.debugName,
  });

  /// Initializer for the text, used to create a [TextEditingController]
  /// during [init].
  ///
  /// If not specified, an empty text will be used.
  final MemberInitializer<String?>? initText;

  /// A function that allows interaction with the text controller during
  /// the [update] call.
  ///
  /// Useful for changing text fields that should be updated when any data
  /// changes inside the ViewModel.
  final MemberUpdater<TextEditingController>? onUpdate;

  /// Duration of Debounce events for [TextEditingController].
  /// By default [Duration.zero]
  final Duration debounce;

  /// The [TextEditingController] accessible for use within the ViewModel
  /// and from widgets.
  ///
  /// The lifecycle of the returned controller is managed by this member,
  /// so manual calls to [TextEditingController.dispose] are discouraged.
  TextEditingController get controller {
    final controller = _controller;
    assert(
      controller is TextEditingController,
      'ViewModel should be initialized first',
    );

    return controller!;
  }

  TextEditingController? _controller;

  @override
  void init(ViewModelOwner owner) {
    super.init(owner);

    final initial = initText?.call() ?? '';
    _controller = TextEditingController(text: initial);
    _controller!.addListener(notifyChanged);
  }

  @override
  void update() {
    onUpdate?.call(controller);
  }

  @override
  void addListener(VoidCallback listener) {
    controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    controller.removeListener(listener);
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
    _controller = null;
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
    debugName,
    _controller?.text ?? '<non ready>',
    tooltip: 'Editable text. Selection: ${_controller?.selection}',
  );
}

/// A member that allows the ViewModel to work with an [AnimationController].
///
/// Changes to the [AnimationController] are tracked by this member.
class AnimationMember extends BuildableViewModelMember with ChangeTracker {
  AnimationMember({
    required this.initController,
    this.onUpdate,
    super.debugName,
  });

  /// Animation controller initializer.
  ///
  /// As [TickerProvider], it is recommended to use [ViewModel.owner],
  /// for example:
  /// ```dart
  /// class SomeVm extends ViewModel {
  ///   late final animation = member.animation(
  ///     initController: () => AnimationController(vsync: owner);
  ///   );
  ///
  ///   @override
  ///   List<ViewModelMember> get members => [animation];
  /// }
  /// ```
  final MemberInitializer<AnimationController> initController;

  /// A function that allows interaction with the animation controller during
  /// the [update] call.
  ///
  /// Useful for controlling animations that should occur when any data changes
  /// inside the ViewModel.
  final MemberUpdater<AnimationController>? onUpdate;

  /// The [AnimationController] accessible for use within the ViewModel
  /// and from widgets.
  ///
  /// The lifecycle of the returned controller is managed by this member,
  /// so manual calls to [AnimationController.dispose] are discouraged.
  AnimationController get controller {
    final controller = _controller;
    assert(
      controller is AnimationController,
      'ViewModel should be initialized first',
    );

    return controller!;
  }

  AnimationController? _controller;

  @override
  void init(ViewModelOwner owner) {
    super.init(owner);

    _controller = initController();
    _controller!.addListener(notifyChanged);
  }

  @override
  @mustCallSuper
  void update() {
    onUpdate?.call(controller);
  }

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);

  @override
  void dispose() {
    super.dispose();

    _controller?.dispose();
    _controller = null;
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => DoubleProperty(
    debugName,
    _controller?.value,
    ifNull: '<non ready>',
    tooltip:
        'Animation ${_controller?.lowerBound} -> '
        '${_controller?.upperBound}',
  );
}

typedef FocusNodeUpdater = void Function(FocusNode node);

/// A member that allows the ViewModel to work with a [FocusNode].
///
/// Changes to the [FocusNode] are tracked by this member.
class FocusMember extends BuildableViewModelMember with ChangeTracker {
  FocusMember({this.onUpdate, super.debugName});

  /// A function that allows interaction with a [FocusNode] during the [update] call.
  ///
  /// It is useful for managing focus, which should occur when changing
  /// any data within the ViewModel.
  final FocusNodeUpdater? onUpdate;

  /// A [FocusNode] available for use both within the ViewModel and from widgets.
  ///
  /// The lifecycle of the returned node is managed by this member, so manual
  /// calls to [FocusNode.dispose] are not necessary.
  FocusNode get node {
    final node = _node;
    assert(node is FocusNode, 'ViewModel should be initialized first');

    return node!;
  }

  FocusNode? _node;

  @override
  void init(ViewModelOwner owner) {
    super.init(owner);
    final node = _node = FocusNode();
    node.addListener(notifyChanged);
  }

  @override
  void update() {
    onUpdate?.call(node);
  }

  @override
  void dispose() {
    super.dispose();

    _node?.dispose();
    _node = null;
  }

  @override
  void addListener(VoidCallback listener) => node.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => node.removeListener(listener);

  @override
  DiagnosticsNode toDiagnosticsNode() =>
      StringProperty(debugName, node.hasFocus ? 'focused' : 'not focused');
}

/// A member that allows the ViewModel to work with a [TabController].
///
/// Changes to the [TabController] are tracked by this member.
class TabMember extends BuildableViewModelMember with ChangeTracker {
  TabMember({
    required this.initController,
    this.updateController,
    this.onUpdate,
    super.debugName,
  });

  /// Initializer for the tab controller.
  final MemberInitializer<TabController> initController;

  /// Function that replaces the tab controller on call to [update].
  ///
  /// Useful for changing the number of tabs when the data inside the ViewModel changes.
  final MemberUpdaterWithResult<TabController, TabController>? updateController;

  /// A function that allows interaction with the tab controller during the [update] call.
  ///
  /// Useful for managing tabs, which should occur when changing any data within the ViewModel.
  final MemberUpdater<TabController>? onUpdate;

  /// [TabController], accessible both within the ViewModel and from widgets.
  ///
  /// The lifecycle of the returned controller is managed by this member,
  /// so manual calls to [TabController.dispose] are not required.
  TabController get controller {
    final controller = _controller;
    assert(
      controller is TabController,
      'ViewModel should be initialized first',
    );

    return controller!;
  }

  TabController? _controller;

  final List<VoidCallback> _listeners = [];

  @override
  void init(ViewModelOwner owner) {
    super.init(owner);

    _controller = initController();
    addListener(notifyChanged);
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    controller.removeListener(listener);
  }

  @override
  void update() {
    final updateController = this.updateController;
    if (updateController != null) {
      final newController = updateController(controller);
      if (newController != _controller) {
        _scheduleDispose(_controller);

        _controller = newController;
        _listeners.forEach(newController.addListener);
      }
    }

    onUpdate?.call(controller);
  }

  @override
  void dispose() {
    super.dispose();

    _controller?.dispose();
    _listeners.clear();
  }

  void _scheduleDispose(TabController? controller) {
    if (controller == null) return;
    Future(controller.dispose);
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
    debugName,
    _controller?.length.toString() ?? '<non ready>',
    tooltip: 'TabController length: ${_controller?.length}',
  );
}

/// A member that allows the ViewModel to work with an arbitrary
/// [ChangeNotifier].
///
/// Calls to [ChangeNotifier.notifyListeners] are tracked by this member.
class CustomChangeNotifierMember<N extends ChangeNotifier>
    extends BuildableViewModelMember
    with ChangeTracker {
  CustomChangeNotifierMember(this.initNotifier, {super.debugName});

  final MemberInitializer<N> initNotifier;

  /// [ChangeNotifier], accessible both within the ViewModel and from widgets.
  ///
  /// The lifecycle of the returned controller is managed by this member,
  /// so manual calls to [ChangeNotifier.dispose] are discouraged.
  N get notifier {
    final notifier = _notifier;
    assert(notifier != null, 'ViewModel should be initialized first');

    return notifier!;
  }

  N? _notifier;

  @override
  void init(ViewModelOwner owner) {
    super.init(owner);

    final notifier = _notifier = initNotifier();
    notifier.addListener(notifyChanged);
  }

  @override
  void update() {
    // Intentionally left blank
  }

  @override
  void addListener(VoidCallback listener) {
    notifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    notifier.removeListener(listener);
  }

  @override
  void dispose() {
    super.dispose();

    _notifier?.dispose();
    _notifier = null;
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
    debugName,
    _notifier != null ? _notifier.toString() : '<non ready>',
  );
}
