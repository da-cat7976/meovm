import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:meovm/src/core/view_model.dart';
import 'package:meovm/src/members/common.dart';
import 'package:meovm/src/members/hooks.dart';
import 'package:meovm/src/members/navigation.dart';
import 'package:meovm/src/members/value.dart';

extension ViewModelMemberBuilder on BuildableViewModelMember {
  ListenableBuilder build({
    required TransitionBuilder builder,
    List<ViewModelMember> mergeWith = const [],
    Key? key,
    Widget? child,
  }) {
    final Listenable listenable;

    if (mergeWith.isNotEmpty) {
      listenable = Listenable.merge([this, ...mergeWith]);
    } else {
      listenable = this;
    }

    return ListenableBuilder(
      key: key,
      listenable: listenable,
      builder: builder,
      child: child,
    );
  }
}

extension UseUpdateNotifierMember<T> on UpdateNotifierMember<T> {
  T use() {
    useListenable(this);
    return data;
  }
}

extension UseValueMember<T> on ValueMember<T> {
  T use() {
    useListenable(this);
    return data;
  }
}

extension UseListMember<T> on ListMember<T> {
  UnmodifiableListView<T> use() {
    useListenable(this);
    return data;
  }
}

extension UseSetMember<T> on SetMember<T> {
  UnmodifiableSetView<T> use() {
    useListenable(this);
    return data;
  }
}

typedef NavigationCallback<T> = void Function(BuildContext context, T data);

typedef ModalCallback<Result> = Future<Result?> Function(BuildContext context);

typedef CloseModalCallback = void Function(BuildContext context);

extension NavigationMemberListener<T, Param> on NavigationMember<T> {
  /// Subscribes [callback] to the events of the current [NavigationMember].
  ///
  /// If [repeat] is `true`, then [callback] will be called immediately after
  /// calling this method with the current [data].
  ///
  /// It is safe to use within build methods of widgets.
  void useNavigation(NavigationCallback<T> callback, {bool repeat = false}) {
    use(
      ViewModelMemberListenerHook(
        member: this,
        listener: (context) => callback(context, data),
        callOnInit: repeat,
      ),
    );
  }
}

extension ModalFlowMemberListener<Result> on ModalFlowMember<Result> {
  void useModal(ModalCallback<Result> callback, {CloseModalCallback? onClose}) {
    use(
      ViewModelMemberListenerHook(
        member: this,
        listener: (context) async {
          if (shouldCloseModal) {
            final close = onClose ?? _fallbackOnClose;
            close(context);
            return;
          }

          if (!isModalRequested) return;

          final result = await callback(context);
          notifyCompleted(result);
        },
      ),
    );
  }

  static void _fallbackOnClose(BuildContext context) {
    Navigator.of(context).pop();
  }
}
