import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:meovm/src/core/api.dart';
import 'package:meta/meta.dart';

@internal
class ViewModelMemberListenerHook extends Hook<void> {
  const ViewModelMemberListenerHook({
    required this.member,
    required this.listener,
    this.callOnInit = false,
  });

  final ViewModelMemberBase member;

  final void Function(BuildContext context) listener;

  final bool callOnInit;

  @override
  ViewModelMemberListenerHookState createState() =>
      ViewModelMemberListenerHookState();
}

@internal
class ViewModelMemberListenerHookState
    extends HookState<void, ViewModelMemberListenerHook> {
  @override
  void initHook() {
    super.initHook();
    hook.member.addListener(_onMemberChanged);

    if (hook.callOnInit) _onMemberChanged();
  }

  @override
  void build(BuildContext context) {
    // Intentionally left blank
  }

  @override
  void dispose() {
    super.dispose();
    hook.member.removeListener(_onMemberChanged);
  }

  void _onMemberChanged() {
    Future(
      () {
        if (!context.mounted) return;
        hook.listener(context);
      },
    );
  }
}
