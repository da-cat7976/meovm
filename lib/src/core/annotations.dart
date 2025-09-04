import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
final class VmMember {
  const VmMember({this.debugName});

  final String? debugName;
}

@Target({TargetKind.classType})
final class VmMemberDefinition {
  const VmMemberDefinition();

  static const name = 'VmMemberDefinition';
}
