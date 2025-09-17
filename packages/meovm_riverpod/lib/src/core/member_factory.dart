import 'package:meovm/meovm.dart';
import 'package:meovm_riverpod/src/members/riverpod.dart';

extension RiverpodMemberFactory on ViewModelMemberFactory {
  /// Creates a [RiverpodDataMember].
  RiverpodDataMember<T> data<T>(
    RiverpodDataMemberResolver<T> resolver, {
    String? debugName,
  }) => RiverpodDataMember<T>(
    resolver,
    debugName: debugName ?? 'RiverpodDataMember #${nextId()}',
  );

  /// Creates a [RiverpodActionGroup].
  RiverpodActionGroup<Group, State> actionGroup<Group, State>(
    RiverpodActionGroupResolver<Group, State> resolver, {
    String? debugName,
  }) => RiverpodActionGroup<Group, State>(
    resolver,
    debugName: debugName ?? 'RiverpodActionGroup #${nextId()}',
  );
}
