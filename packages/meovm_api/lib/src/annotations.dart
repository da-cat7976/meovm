import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
final class Meovm {
  const Meovm();
}

@Target({TargetKind.field})
final class MeovmDepend {
  const MeovmDepend(this.dependOn);

  final Symbol dependOn;
}
