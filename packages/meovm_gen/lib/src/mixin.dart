import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:meovm_gen/src/param_helper.dart';
import 'package:meovm_gen/src/vm_helper.dart';
import 'package:source_gen/source_gen.dart';

class VmMixinGenerator extends GeneratorForAnnotation<Meovm> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSource(
        'Only classes can be annotated with @Meovm annotation',
      );
    }

    final vmChecker = TypeChecker.fromRuntime(MeovmAutoVm);
    if (vmChecker.isAssignableFrom(element)) {
      return vmHelper.generate(element, annotation, buildStep);
    }

    final paramChecker = TypeChecker.fromRuntime(MeovmAutoVmParameter);
    if (paramChecker.isAssignableFrom(element)) {
      return paramHelper.generate(element, annotation, buildStep);
    }

    throw InvalidGenerationSource('Invalid annotated element: $element');
  }

  final VmMixinGeneratorHelper vmHelper = VmMixinGeneratorHelper();

  final ParamMixinGeneratorHelper paramHelper = ParamMixinGeneratorHelper();
}
