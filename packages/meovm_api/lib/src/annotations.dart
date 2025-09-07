import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
final class Meovm {
  const Meovm();
}

@Target({TargetKind.field})
final class MeovmDepend {
  const MeovmDepend(
    this.dependOn, {
    this.from,
    this.external = false,
    this.disabled = false,
  });

  final Symbol dependOn;

  final Symbol? from;

  final bool external;

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
