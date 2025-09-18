import 'package:flutter/material.dart';
import 'package:meovm/meovm.dart';
import 'package:meta/meta.dart';

/// ViewModel member factory providing a convenient way to add
/// members to the ViewModel with assigned identifiers (if no
/// explicit [ViewModelMember.debugName] is specified).
///
/// Members are declared as follows:
/// ```dart
/// class SomeVm extends ViewModel {
///   late final value = member.value<int>(initial: 0);
///
///   List<ViewModelMemberBase> get members => [
///     value,
///   ];
/// }
/// ```
///
/// Note that if the ViewModel does not use the dependency mechanism,
/// initialization, updating, and deinitialization of members
/// will be performed in the same order as they are declared.
///
/// See also: [ViewModelMemberFactory], [setDependencies].
class ViewModelMemberFactory {
  int _id = 0;

  int nextId() => _id++;

  /// Creates a [ValueMember].
  ValueMember<T> value<T>({
    T? initial,
    ValueMemberResolver<T>? resolver,
    String? debugName,
  }) => ValueMember<T>(
    initial: initial,
    resolver: resolver,
    debugName: debugName ?? 'ValueMember #${nextId()}',
  );

  /// Creates a [ListMember].
  ListMember<T> list<T>({
    List<T>? initial,
    ValueMemberResolver<List<T>>? resolver,
    String? debugName,
  }) => ListMember<T>(
    initial: initial,
    resolver: resolver,
    debugName: debugName ?? 'ListMember #${nextId()}',
  );

  /// Creates a [SetMember].
  SetMember<T> set<T>({
    Set<T>? initial,
    ValueMemberResolver<Set<T>>? resolver,
    String? debugName,
  }) => SetMember<T>(
    initial: initial,
    resolver: resolver,
    debugName: debugName ?? 'SetMember #${nextId()}',
  );

  /// Creates a [EditableTextMember].
  EditableTextMember editableText({
    MemberInitializer<String?>? initText,
    MemberUpdater<TextEditingController>? onUpdate,
    String? debugName,
    Duration debounce = Duration.zero,
  }) => EditableTextMember(
    initText: initText,
    onUpdate: onUpdate,
    debugName: debugName ?? 'EditableTextMember #${nextId()}',
    debounce: debounce,
  );

  /// Creates a [AnimationMember].
  AnimationMember animation({
    required MemberInitializer<AnimationController> initController,
    MemberUpdater<AnimationController>? onUpdate,
    String? debugName,
  }) => AnimationMember(
    initController: initController,
    onUpdate: onUpdate,
    debugName: debugName ?? 'AnimationMember #${nextId()}',
  );

  /// Creates a [FocusMember].
  FocusMember focus({MemberUpdater<FocusNode>? onUpdate, String? debugName}) =>
      FocusMember(
        onUpdate: onUpdate,
        debugName: debugName ?? 'FocusMember #${nextId()}',
      );

  /// Creates a [TabMember].
  TabMember tab({
    required MemberInitializer<TabController> initController,
    MemberUpdater<TabController>? onUpdate,
    MemberUpdaterWithResult<TabController, TabController>? updateController,
    String? debugName,
  }) => TabMember(
    initController: initController,
    onUpdate: onUpdate,
    updateController: updateController,
    debugName: debugName ?? 'TabMember #${nextId()}',
  );

  /// Creates a [CustomChangeNotifierMember].
  CustomChangeNotifierMember<N> notifier<N extends ChangeNotifier>(
    MemberInitializer<N> initNotifier, {
    String? debugName,
  }) => CustomChangeNotifierMember(
    initNotifier,
    debugName: debugName ?? 'CustomChangeNotifierMember #${nextId()}',
  );

  /// Creates a [NavigationMember].
  NavigationMember<T> navigation<T>({
    T? initial,
    ValueMemberResolver<T>? resolver,
    String? debugName,
  }) => NavigationMember<T>(
    initial: initial,
    resolver: resolver,
    debugName: debugName ?? 'NavigationMember #${nextId()}',
  );

  /// Creates an [NavigationMember] with auto reset.
  NavigationMember<T> autoResetNavigation<T>({
    required T initial,
    String? debugName,
  }) => NavigationMember<T>.autoReset(
    initial: initial,
    debugName: debugName ?? 'NavigationMember #${nextId()}',
  );

  /// Creates a [ModalFlowMember].
  ModalFlowMember<T> modalFlow<T>({String? debugName}) => ModalFlowMember<T>(
    debugName: debugName ?? 'ModalFlowMember #${nextId()}',
  );

  /// Creates a [MemberGroup].
  @experimental
  MemberGroup<K, M> memberGroup<K, M extends ViewModelMember>({
    required List<K> keys,
    required GroupMemberBuilder<K, M> builder,
    String? debugName,
  }) => MemberGroup<K, M>(
    keys: keys,
    builder: builder,
    debugName: debugName ?? 'MemberGroup #${nextId()}',
  );

  /// Creates a [StreamMember].
  StreamMember<T> stream<T>({
    required StreamMemberResolver<T> resolver,
    StreamMemberErrorListener? onError,
    bool cancelOnError = false,
    String? debugName,
  }) {
    return StreamMember<T>(
      resolver: resolver,
      onError: onError,
      cancelOnError: cancelOnError,
      debugName: debugName ?? 'StreamMember #${nextId()}',
    );
  }
}

mixin ViewModelMemberFactoryAccess {
  final _memberFactory = ViewModelMemberFactory();

  ViewModelState get state;

  /// Factory for ViewModel members providing a convenient way to add
  /// members to the ViewModel with assigned identifiers (if no
  /// explicit [ViewModelMember.debugName] is specified).
  ///
  /// Members are declared as follows:
  /// ```dart
  /// class SomeVm extends ViewModel {
  ///   late final value = member.value<int>(initial: 0);
  /// }
  /// ```
  @protected
  @nonVirtual
  ViewModelMemberFactory get member {
    assert(
      state == ViewModelState.created,
      'Members can be added only from the created state.\n'
      'Did you forget to add one or more members to the members getter?',
    );

    return _memberFactory;
  }
}
