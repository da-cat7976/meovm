import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meovm_lint/src/rules/abstract_resolver.dart';
import 'package:meovm_lint/src/rules/external_modification.dart';
import 'package:meovm_lint/src/rules/lifecycle_use.dart';

PluginBase createPlugin() => _MeovmLint();

class _MeovmLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      ExternalModificationRule(),
      AbstractResolverRule(),
      LifecycleAccessRule(),
    ];
  }
}
