import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:meovm/src/members/common.dart';
import 'package:meovm/src/core/annotations.dart';

typedef ValueMemberResolver<T> = T Function(T? data);


/// A member that implements data storage and change. For passing data to
/// widgets, it is recommended to use this class specifically:
/// ```dart
/// class SomeVm extends ViewModel {
///   late final value = member.value<int>(initial: 0);
///
///   @override
///   List<ViewModelMember> get members => [value];
///
///   void increment() {
///     value.data++;
///   }
/// }
///
/// class SomeWidget extends Widget {
///   @override
///   Widget build(BuildContext context) {
///     final vm = context.useVM<SomeVm>();
///
///     return vm.value.build(
///       builder: (context) => TextButton(
///         onPressed: vm.increment,
///         child: Text('${vm.value.data}'),
///       ),
///     );
/// }
/// ```
///
/// Note: for list handling, it is recommended to use [ListMember].
@VmMemberDefinition()
class ValueMember<T> extends BuildableViewModelMember with ChangeNotifier {
  /// Creates a new member that stores a value of type [T].
  ///
  /// [initial] - the initial value
  ///
  /// [resolver] - a function that updates the value upon calling [update].
  ///
  /// Note that if both [initial] and [resolver] are provided, after the first
  /// update, the value will be the one returned by [resolver].
  ValueMember({
    T? initial,
    ValueMemberResolver<T>? resolver,
    super.debugName,
  })  : _resolver = resolver,
        _data = initial;

  /// The data stored in this member.
  ///
  /// Subscribers will be notified of data changes if the set value is not equal
  /// to the current value.
  T get data {
    final data = _data;
    assert(data is T, 'ViewModel should be initialized first');

    return data as T;
  }

  set data(T value) {
    if (_data == value) return;

    _data = value;
    _wasChanged = true;
    notifyListeners();
  }

  /// {@macro view_model_member.wasChanged}
  @nonVirtual
  bool get wasChanged => _wasChanged;

  final ValueMemberResolver<T>? _resolver;

  T? _data;

  bool _wasChanged = false;

  @override
  @mustCallSuper
  void update() {
    final resolver = _resolver;
    if(resolver is! ValueMemberResolver<T>) return;

    final data = resolver(_data);
    if (_data == data) return;

    _data = data;
    _wasChanged = true;
    notifyListeners();
  }

  @override
  @mustCallSuper
  void notifyUpdateCompleted() {
    _wasChanged = false;
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _data = null;
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => StringProperty(
        debugName,
        _data?.toString() ?? '<non ready>',
        quoted: false,
        description: 'Member that holds a value',
      );
}

/// A member that implements data storage and change of a list. For passing
/// data to widgets, it is recommended to use this class specifically:
/// ```dart
/// class SomeVm extends ViewModel {
///   late final list = member.list<int>(initial: [1, 2, 3]);
///
///   @override
///   List<ViewModelMember> get members => [list];
///
///   void add() {
///     final last = list.data.last;
///     list.add(last + 1);
///   }
/// }
///
/// class SomeWidget extends Widget {
///   @override
///   Widget build(BuildContext context) {
///     final vm = context.useVM<SomeVm>();
///
///     return Column(
///       children: [
///         TextButton(
///           onPressed: vm.add,
///           child: Text('Add'),
///         ),
///         vm.list.build(
///           builder: (context) => Wrap(
///             children: vm.list.data.map((e) => Text('$e')).toList(),
///           ),
///         ),
///       ],
///     );
///   }
/// }
@VmMemberDefinition()
class ListMember<T> extends BuildableViewModelMember with ChangeNotifier {
  /// Creates a new member that holds a list of values of type [T].
  ///
  /// [initial] — the initial value
  ///
  /// [resolver] — a function that updates the value upon calling [update].
  ///
  /// Note that if both [initial] and [resolver] are provided, after the first
  /// update, the value will be the one returned by [resolver].
  ListMember({
    List<T>? initial,
    ValueMemberResolver<List<T>>? resolver,
    super.debugName,
  })  : _resolver = resolver,
        _data = initial ?? [];

  /// The data stored in this member.
  ///
  /// Note that the passed list is immutable.
  UnmodifiableListView<T> get data {
    final data = _data;
    assert(data is List<T>, 'ViewModel should be initialized first');

    return UnmodifiableListView(data!);
  }

  /// {@macro view_model_member.wasChanged}
  @nonVirtual
  bool get wasChanged => _wasChanged;

  final ValueMemberResolver<List<T>>? _resolver;

  List<T>? _data;

  bool _wasChanged = false;

  @override
  @mustCallSuper
  void update() {
    final oldData = _data ?? [];
    final newData = _resolver?.call(oldData) ?? oldData;
    if (oldData.equals(newData)) return;

    _data = newData;
    _wasChanged = true;
    notifyListeners();
  }

  @override
  @mustCallSuper
  void notifyUpdateCompleted() {
    _wasChanged = false;
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _data = null;
  }

  @mustCallSuper
  void add(T element) {
    _data?.add(element);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void addAll(Iterable<T> elements) {
    _data?.addAll(elements);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void sort([int Function(T a, T b)? compare]) {
    _data?.sort(compare);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void shuffle([Random? random]) {
    _data?.shuffle(random);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void clear() {
    _data?.clear();
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void insert(int index, T element) {
    _data?.insert(index, element);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void insertAll(int index, Iterable<T> elements) {
    _data?.insertAll(index, elements);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void setAll(int index, Iterable<T> elements) {
    _data?.setAll(index, elements);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void remove(T element) {
    _data?.remove(element);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void removeAt(int index) {
    _data?.removeAt(index);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void removeLast() {
    _data?.removeLast();
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void removeWhere(bool Function(T element) test) {
    _data?.removeWhere(test);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void retainWhere(bool Function(T element) test) {
    _data?.retainWhere(test);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    _data?.setRange(start, end, iterable, skipCount);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void removeRange(int start, int end) {
    _data?.removeRange(start, end);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void fillRange(int start, int end, [T? fillValue]) {
    _data?.fillRange(start, end, fillValue);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void replaceRange(int start, int end, Iterable<T> newContents) {
    _data?.replaceRange(start, end, newContents);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void operator []=(int index, T value) {
    _data?[index] = value;
    _wasChanged = true;
    notifyListeners();
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => IterableProperty(
        debugName,
        _data,
        ifNull: '<non ready>',
      );
}

@VmMemberDefinition()
class SetMember<T> extends BuildableViewModelMember with ChangeNotifier {
  /// Creates a new member that stores a set of values of type [T].
  ///
  /// [initial] — the initial value
  ///
  /// [resolver] — a function that updates the value when [update] is called.
  ///
  /// Note that if both [initial] and [resolver] are passed, after the first
  /// update, the value will be the one returned by [resolver].
  SetMember({
    Set<T>? initial,
    ValueMemberResolver<Set<T>>? resolver,
    super.debugName,
  })  : _resolver = resolver,
        _data = initial ?? {};

  /// The data stored in this member.
  ///
  /// Note that the passed set is immutable.
  UnmodifiableSetView<T> get data {
    final data = _data;
    assert(data is Set<T>, 'ViewModel should be initialized first');

    return UnmodifiableSetView(data!);
  }

  final ValueMemberResolver<Set<T>>? _resolver;

  Set<T>? _data;

  /// {@macro view_model_member.wasChanged}
  @nonVirtual
  bool get wasChanged => _wasChanged;

  bool _wasChanged = false;

  @override
  @mustCallSuper
  void update() {
    final oldData = _data ?? {};
    final newData = _resolver?.call(oldData) ?? oldData;
    if (setEquals(oldData, newData)) return;

    _data = newData;
    _wasChanged = true;
    notifyListeners();
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _data = null;
  }

  @mustCallSuper
  void add(T element) {
    _data?.add(element);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void addAll(Iterable<T> elements) {
    _data?.addAll(elements);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void clear() {
    _data?.clear();
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void remove(T element) {
    _data?.remove(element);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void removeWhere(bool Function(T element) test) {
    _data?.removeWhere(test);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void retainWhere(bool Function(T element) test) {
    _data?.retainWhere(test);
    _wasChanged = true;
    notifyListeners();
  }

  @mustCallSuper
  void removeAll(Iterable<T?> elements) {
    _data?.removeAll(elements);
    _wasChanged = true;
    notifyListeners();
  }

  @override
  DiagnosticsNode toDiagnosticsNode() => IterableProperty(
        debugName,
        _data,
        ifNull: '<non ready>',
      );

  @override
  void notifyUpdateCompleted() {
    _wasChanged = false;
  }
}
