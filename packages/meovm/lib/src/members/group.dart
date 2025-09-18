import 'package:flutter/foundation.dart';
import 'package:meovm/src/core/api.dart';
import 'package:meovm/src/core/view_model.dart';
import 'package:meta/meta.dart';

typedef GroupMemberBuilder<K, M extends ViewModelMember> = M Function(
  K key,
);

/// A member that groups multiple similar members. Useful when you have
/// a large enum for all of which entries should be added appropriate member.
@experimental
class MemberGroup<K, M extends ViewModelMember> extends ViewModelMember
    with ChangeNotifier {
  MemberGroup({
    required List<K> keys,
    required GroupMemberBuilder<K, M> builder,
    super.debugName,
  })  : _members = {
          for (final key in keys) key: builder(key),
        };

  final Map<K, M> _members;

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

  @override
  void notifyUpdateCompleted() {
    for(final member in _members.values) {
      // ? Must be called to ensure correct dependency behavior.
      // ? Check out: https://github.com/da-cat7976/meovm/issues/26
      // ignore: invalid_use_of_visible_for_overriding_member
      member.notifyUpdateCompleted();
    }
  }

  @override
  void update() {
    for(final member in _members.values) {
      // ? Must be called to ensure correct dependency behavior.
      // ? Check out: https://github.com/da-cat7976/meovm/issues/26
      // ignore: invalid_use_of_visible_for_overriding_member
      member.update();
    }
  }

  @nonVirtual
  M operator [](K key) {
    final member = _members[key];
    assert(member != null, 'No member for key $key in this group');

    return member!;
  }
}
