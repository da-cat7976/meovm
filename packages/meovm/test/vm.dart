import 'package:meovm/meovm.dart';

class TestVm<Param extends ViewModelParameter?> extends ViewModel<Param> {
  @override
  final List<ViewModelMember> members;

  final void Function(ViewModelDependencySetter depend)? setDeps;

  TestVm({this.members = const [], this.setDeps});

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    setDeps?.call(depend);
  }
}
