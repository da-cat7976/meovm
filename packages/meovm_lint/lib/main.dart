import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:meovm_lint/src/rules/abstract_resolver.dart';
import 'package:meovm_lint/src/rules/external_modification.dart';
import 'package:meovm_lint/src/rules/lifecycle_use.dart';

final plugin = MeovmLintPlugin();

class MeovmLintPlugin extends Plugin {
  @override
  String get name => 'meovm_lint';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(ExternalModificationRule())
      ..registerWarningRule(AbstractResolverRule())
      ..registerWarningRule(LifecycleAccessRule());
  }
}
