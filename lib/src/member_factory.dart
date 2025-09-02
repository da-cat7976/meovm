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
abstract base class ViewModelMemberFactoryBase {
  int _id = 0;

  int nextId() => _id++;
}

abstract interface class ViewModelMemberFactoryAccess {
  // Intentionally left blank
}