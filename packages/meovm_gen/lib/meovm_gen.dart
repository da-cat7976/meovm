import 'package:build/build.dart';
import 'package:meovm_gen/src/mixin.dart';
import 'package:source_gen/source_gen.dart';

Builder vmMixinBuilder(BuilderOptions options) => SharedPartBuilder(
  [VmMixinGenerator()],
  'vm_mixin_builder', // fmt
);
