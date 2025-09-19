import 'package:meta/meta_meta.dart';

/// Annotation for VMs and params that use meovm code generation.
@Target({TargetKind.classType})
final class Meovm {
  const Meovm();
}

/// Annotation for manual control of dependencies between VM members.
@Target({TargetKind.field})
final class MeovmDepend {
  const MeovmDepend(
    this.dependOn, {
    this.from,
    this.external = false,
    this.disabled = false,
  });

  /// Name of the source member (on which annotated depends).
  final Symbol dependOn;

  /// Name of the VM (in parameter) from which the source member is.
  ///
  /// Ignored if [external] equals to `false`.
  final Symbol? from;

  /// Is dependency external? If `true`, source member should be in param.
  final bool external;

  /// Is dependency disabled?
  final bool disabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeovmDepend &&
          runtimeType == other.runtimeType &&
          dependOn == other.dependOn &&
          from == other.from &&
          external == other.external &&
          disabled == other.disabled;

  @override
  int get hashCode =>
      dependOn.hashCode ^ from.hashCode ^ external.hashCode ^ disabled.hashCode;
}

/// Annotates field, getter, setter or method as not intended to use outside of
/// ViewModel.
const meovmInternal = _MeovmInternal();

@Target({TargetKind.field, TargetKind.getter, TargetKind.setter, TargetKind.method})
final class _MeovmInternal {
  const _MeovmInternal();
}