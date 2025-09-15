import 'package:meovm_api/meovm_api.dart';
import 'package:meovm_gen/meovm_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';

void main() async {
  final reader = await initializeLibraryReaderForDirectory('test/src', 'external.dart');

  initializeBuildLogTracking();
  testAnnotatedElements<Meovm>(reader, VmMixinGenerator());
}
