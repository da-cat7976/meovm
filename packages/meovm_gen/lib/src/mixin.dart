import 'dart:async';

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:meovm_api/meovm_api.dart';
import 'package:meovm_gen/src/param_helper.dart';
import 'package:meovm_gen/src/vm_helper.dart';
import 'package:source_gen/source_gen.dart';

class VmMixinGenerator extends GeneratorForAnnotation<Meovm> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement2) {
      throw InvalidGenerationSource(
        'Only classes can be annotated with @Meovm annotation',
      );
    }

    if (vmHelper.canAccept(element)) {
      return vmHelper.generate(element, annotation, buildStep);
    }

    if (paramHelper.canAccept(element)) {
      return paramHelper.generate(element, annotation, buildStep);
    }

    throw InvalidGenerationSource('Invalid annotated element: $element');
  }

  final VmMixinGeneratorHelper vmHelper = VmMixinGeneratorHelper();

  final ParamMixinGeneratorHelper paramHelper = ParamMixinGeneratorHelper();
}
