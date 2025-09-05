import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/api.dart';
import 'package:meovm/src/core/view_model.dart';

typedef GroupMemberBuilder<K, M extends ViewModelMember> = M Function(
  K key,
);

class MemberGroup<K, M extends ViewModelMember> extends ViewModelMember
    with ChangeNotifier {
  MemberGroup({
    required List<K> keys,
    required GroupMemberBuilder<K, M> builder,
    List<ViewModelMember>? dependOn,
    super.debugName,
  })  : _members = {
          for (final key in keys) key: builder(key),
        },
        _dependOn = dependOn ?? <ViewModelMember>[];

  final Map<K, M> _members;

  final List<ViewModelMember> _dependOn;

  @nonVirtual
  List<ViewModelMember> get members => _members.values.toList();

  @override
  @mustCallSuper
  void init(ViewModelOwner owner) {
    super.init(owner);

    for (final member in _members.values) {
      member.addListener(notifyListeners);
    }
  }

  @mustCallSuper
  void setDependencies(ViewModelDependencySetter depend) {
    for (final slave in _members.values) {
      for (final master in _dependOn) {
        depend(master, slave);
      }
    }
  }

  @override
  void notifyUpdateCompleted() {
    // Intentionally left blank
  }

  @override
  void update() {
    // Intentionally left blank
  }

  @nonVirtual
  M operator [](K key) {
    final member = _members[key];
    assert(member != null, 'No member for key $key in this group');

    return member!;
  }
}
