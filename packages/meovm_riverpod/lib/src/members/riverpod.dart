import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/src/core/feature.dart';
import 'package:meta/meta.dart';

typedef RiverpodDataMemberResolver<T> = T Function(WidgetRef ref, T? data);

typedef RiverpodActionGroupResolver<Group, State> =
    ({Group group, State state}) Function(WidgetRef ref, State? data);

abstract class RiverpodMember<T> extends UpdateNotifierMember<T> {
  RiverpodMember({super.debugName, super.frozen});
}

/// A member that provides data from riverpod providers.
///
/// Integration with data providers should be done through this class
/// in the following way:
/// ```dart
/// class SomeClass with EquatableMixin {
///   SomeClass({
///     required this.intValue,
///     required this.stringValue,
///   );
///
///   final int intValue;
///
///   final String stringValue;
///
///   @override
///   List<Object?> get props => [intValue, stringValue];
/// }
///
/// @riverpod
/// SomeClass someClass(SomeClassRef ref) => ...
///
/// class SomeVm extends ViewModel {
///   late final someData = member.data<SomeClass>(
///     (ref, data) => ref.watch(someClass),
///   );
///
///   late final intValue = member.value<int>(
///     () => someData.data?.intValue ?? 0,
///   );
///
///   @override
///   List<ViewModelMember> get members => [someData, intValue];
///
///   @override
///   void setDependencies(ViewModelDependencySetter depend) {
///     depend(someData, intValue);
///   }
/// }
///
/// class SomeWidget extends Widget {
///   @override
///   Widget build(BuildContext context) {
///     final vm = context.useVM<SomeVm>();
///
///     return vm.intValue.build(
///       builder: (context) => Text('${vm.intValue.data}'),
///     );
///   }
/// }
/// ```
///
/// It is recommended not to use [RiverpodDataMember] directly in widgets (though it is possible),
/// as if [T] is passed as [AsyncValue] accessing the data becomes quite cumbersome.
/// This is for demonstration purposes, assuming that in the above example,
/// an asynchronous provider is now used:
/// ```dart
/// class SomeWidget extends Widget {
///   @override
///   Widget build(BuildContext context) {
///     final vm = context.useVM<SomeVm>();
///
///     return vm.someValue.build(
///       builder: (context) =>
///         Text('${vm.someValue.data.valueOrNull?.intValue ?? 0}'),
///     );
///   }
/// }
/// ```
///
/// Instead, it is recommended to proxy the used data through [ValueMember] or
/// [ListMember]. Besides the obvious reduction of data access, this also
/// allows optimizing UI updates, as they only occur if the provided provider
/// object's `intValue` changes.
class RiverpodDataMember<T> extends RiverpodMember<T> {
  RiverpodDataMember(this._resolver, {super.debugName, super.frozen});

  final RiverpodDataMemberResolver<T> _resolver;

  @override
  @mustCallSuper
  T resolve(T? data) => _resolver(owner.ref, data);

  @override
  DiagnosticsNode toDiagnosticsNode() {
    final node = super.toDiagnosticsNode() as StringProperty;

    return StringProperty(
      debugName,
      node.value?.toString(),
      quoted: false,
      description: 'Member that provides data from riverpod provider',
    );
  }
}

/// A member that provides interaction with riverpod action groups.
///
/// Riverpod action groups are usually AsyncNotifier objects of the following
/// form:
/// ```dart
/// @riverpod
/// class SomeGroup extends _$SomeGroup {
///   Future<SomeData> build(int someId) {
///     // ...
///   }
///
///   Future<void> someAction() async {
///     state = const AsyncLoading();
///     state = await AsyncValue.guard(
///       () {
///         // do some stuff
///       }
///     );
///   }
/// }
/// ```
///
/// In order to interact with such groups, it is recommended to use this class:
/// ```dart
/// class SomeVmParam with EquatableMixin {
///   const SomeVmParam({
///     required this.someId,
///   });
///
///   final int someId;
///
///   @override
///   List<Object?> get props => [someId];
/// }
///
/// class SomeVm extends ViewModel<SomeVmParam> {
///   late final someGroup =
///     member.actionGroup<SomeGroup, AsyncValue<SomeData>>(
///     (ref, data) {
///       final provider = someGroupProvider(param.someId);
///
///       return (
///         group: ref.watch(provider.notifier),
///         state: ref.watch(provider),
///       );
///     }
///   );
///
///  @override
///  List<ViewModelMember> get members => [someGroup];
///
///   void doSomeAction() {
///     someGroup.notifier.someAction();
///   }
/// }
/// ```
///
/// This way, you can interact with action groups from widgets by implementing
/// additional logic in ViewModel methods and tracking the progress of actions
/// through [data].
///
/// It is important to consider the peculiarities of [RiverpodDataMember]
/// when working with [data].
class RiverpodActionGroup<Group, State> extends RiverpodMember<State> {
  RiverpodActionGroup(this._resolver, {super.debugName, super.frozen});

  final RiverpodActionGroupResolver<Group, State> _resolver;

  @nonVirtual
  Group get notifier {
    final notifier = _notifier;
    assert(notifier != null, 'ViewModel should be initialized first');

    return notifier!;
  }

  Group? _notifier;

  @override
  @mustCallSuper
  State resolve(State? data) {
    final resolved = _resolver(owner.ref, data);
    _notifier = resolved.group;

    return resolved.state;
  }

  @override
  @mustCallSuper
  void dispose() {
    _notifier = null;
    super.dispose();
  }

  @override
  DiagnosticsNode toDiagnosticsNode() {
    final node = super.toDiagnosticsNode() as StringProperty;

    return StringProperty(
      debugName,
      node.value?.toString(),
      quoted: false,
      description:
          'Riverpod action group controlled by ${notifier.runtimeType}',
    );
  }
}

@experimental
extension SideEffectExtension<Param extends ViewModelParameter?> on ViewModel<Param> {
  /// Delays the execution of a side effect.
  ///
  /// Useful for calling notifier methods from resolvers of [RiverpodDataMember]
  /// and [RiverpodActionGroup]. Example:
  /// ```dart
  /// @riverpod
  /// class SomeNotifier extends _$SomeNotifier {
  ///   void doSomething() {
  ///     state = ...;
  ///   }
  /// }
  ///
  /// class SomeVm extends ViewModel {
  ///   late final someData = member.data(
  ///     () {
  ///       final notifier = ref.watch(someNotifierProvider.notifier);
  ///       sideEffect(notifier.doSomething);
  ///     },
  ///   );
  /// }
  /// ```
  /// This is useful when calling notifier methods from resolvers of [RiverpodDataMember]
  /// and [RiverpodActionGroup]. For example:
  ///
  @protected
  void sideEffect(void Function() effect) {
    Future(() {
      if (state == ViewModelState.disposed) return;
      effect();
    });
  }
}
