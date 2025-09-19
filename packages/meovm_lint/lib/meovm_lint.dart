import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meovm_lint/src/rules/external_modification.dart';

PluginBase createPlugin() => _MeovmLint();

class _MeovmLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [ExternalModificationRule()];
  }
}
