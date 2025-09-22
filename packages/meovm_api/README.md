Side package for [meovm](https://pub.dev/packages/meovm). Adds high-level API for code generation.

# Meovm

A lightweight MVVM framework for Flutter that provides:

- A clear ViewModel lifecycle
- Fine-grained UI updates via ViewModel members
- Declarative dependencies between members with topological ordering
- Built-in members for values, lists, sets, streams, and common Flutter controllers
- Hook-based utilities for ergonomic consumption in widgets
- Integrations for [flutter_bloc](https://pub.dev/packages/flutter_bloc)
  and [riverpod](https://pub.dev/packages/riverpod)
- Code generation for VMs & params

## Table of contents
- [Installation](#installation)
  - [TL;DR](#tldr)
- [Core concepts](#core-concepts)
- [Quick start](#quick-start)
- [Scopes](#scopes)
- [Members in detail](#members-in-detail)
- [Dependencies between members](#dependencies-between-members)
- [Accessing ViewModel and params in widgets](#accessing-viewmodel-and-params-in-widgets)
- [Diagnostics](#diagnostics)

## Installation

### TL;DR

1. Run:

    ```bash
    flutter pub add meovm meovm_api flutter_hooks dev:custom_lint dev:meovm_lint dev:build_runner dev:meovm_gen
    ```

2. Add to analysis_options.yaml (if not added yet):

    ```yaml
    analyzer:
      plugins:
        - custom_lint
    ```

3. Integrate with your state manager:

   Riverpod:

    ```bash
    flutter pub add meovm_riverpod
    ```

   Bloc:

    ```bash
    flutter pub add meovm_bloc
    ```

### Packages overview

- This package: core package that implements core idea of the framework
- [meovm_api](https://pub.dev/packages/meovm_api): annotations & interfaces required to work with
  linter & codegen
- [meovm_gen](https://pub.dev/packages/meovm_gen): code generation for VMs & params
- [meovm_lint](https://pub.dev/packages/meovm_lint): linter that keeps you away from the most common
  mistakes
- [meovm_bloc](https://pub.dev/packages/meovm_bloc): integration
  with [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- [meovm_riverpod](https://pub.dev/packages/meovm_riverpod): integration
  with [riverpod](https://pub.dev/packages/riverpod)

Just add selected packages via `flutter pub add`. And don't forget to add:
1. `flutter_hooks` to use
navigation members (and `hooks_riverpod` if you use riverpod).
2. Following to `analysis_options.yaml`:
    ```yaml
    analyzer:
      plugins:
        - custom_lint
    ```

## Core concepts

- ViewModel
    - Implements the MVVM state holder and lifecycle
    - Manages a list of members and their dependencies, ensuring topological initialization,
      updates, and disposal.
    - Provides owner (the Flutter-side host) and param (configuration/state passed from the widget).
- ViewModelDispatcher
    - The ViewModelDispatcher widget (as well as corresponding dispatchers from meovm_bloc &
      meovm_riverpod) instantiates your ViewModel, wires lifecycle methods, provides param, and
      exposes the ViewModel to the widget tree via Inherited widgets.
- Members
    - Encapsulated state units that are Listenable and can build widgets or notify changes.
    - Built-in members:
        - ValueMember, ListMember, SetMember
        - StreamMember
        - Navigation and modal flow helpers: NavigationMember, ModalFlowMember
        - Flutter-oriented members: EditableTextMember, AnimationMember, FocusMember, TabMember,
          CustomChangeNotifierMember
    - Members can be composed and can depend on each other. Dependencies let the framework update
      only affected parts of the UI in the right order.
- Hooks and builders
    - `.build(...)` to produce a ListenableBuilder from members
    - `.use()` to consume member state in Hook widgets
    - `NavigationMember.useNavigation(...)` and `ModalFlowMember.useModal(...)` to easily integrate
      navigation & VM

## Quick start

1. Define a ViewModel

    ```dart
    import 'package:meovm/meovm.dart';
    import 'package:meovm_api/meovm_api.dart';
    
    @Meovm()
    class CounterVm extends ViewModel<CounterParam?> with _$CounterVm {
      @override
      late final count = member.value<int>(initial: 0, debugName: 'count');
    
      @override
      void increment() => count.data = count.data + 1;
    }
    
    @Meovm()
    class CounterParam extends ViewModelParameter with _$CounterParam {
      const CounterParam({this.step = 1});
      
      @override
      final int step;
    }
    ```

2. Insert it into widget tree

    ```dart
    import 'package:flutter/material.dart';
    import 'package:meovm/meovm.dart';
    
    class CounterScreen extends StatelessWidget {
      const CounterScreen({super.key});
    
      @override
      Widget build(BuildContext context) {
        return ViewModelDispatcher<CounterVm, CounterParam?>(
          factory: CounterVm.new,
          param: const CounterParam(step: 1),
          child: const CounterView(),
        );
      }
    }
    ```

3. Consume it in the UI:

   Using `.build(...)`:

    ```dart
    class CounterView extends StatelessWidget {
      const CounterView({super.key});
    
      @override
      Widget build(BuildContext context) {
        final vm = context.useVM<CounterVm>();
    
        return vm.count.build(
          builder: (context, _) => Column(
            children: [
              Text('Count: ${vm.count.data}'),
              ElevatedButton(
                onPressed: vm.increment,
                child: const Text('Increment'),
              ),
            ],
          ),
        );
      }
    }
    ```

   Or with hooks and `.use()`:

    ```dart
    import 'package:flutter_hooks/flutter_hooks.dart';
    
    class CounterViewHooks extends HookWidget {
      const CounterViewHooks({super.key});
    
      @override
      Widget build(BuildContext context) {
        final vm = context.useVM<CounterVm>();
        final count = vm.count.use();
    
        return Column(
          children: [
            Text('Count: $count'),
            ElevatedButton(
              onPressed: vm.increment,
              child: const Text('Increment'),
            ),
          ],
        );
      }
    }
    ```

## Scopes

Scopes allow retrieving a ViewModel or its parameter by a supertype from anywhere in the subtree, not just by the exact type provided by the nearest `InheritedWidget`.

How it works:

- `ViewModelDispatcher` can optionally wrap its subtree with an internal `ViewModelScope` when `scope: true` is passed. See `packages/meovm/lib/src/core/dispatcher.dart`.
- When you call `context.useVmOrNull<T>(scope: true)` or `context.useParamOrNull<T>(scope: true)`, meovm will look into the nearest active `ViewModelScope` and return the first instance that matches the requested supertype.
- Retrieval by supertype is a relatively expensive operation; only enable it when you need it.

Notes and limitations:

- Supertype retrieval works only when the corresponding `ViewModelDispatcher` was created with `scope: true`.
- You can still use the regular, fast path with exact-type retrieval via `context.useVM<ExactType>()` or `context.useParam<ExactType>()` without enabling scope.
- Scopes are nestable: the nearest scope that satisfies the requested type wins.

Retrieve ViewModel by a supertype:

```dart
abstract class SomeAbstractVm extends ViewModel<SomeParam?> {}

final class SomeVm extends SomeAbstractVm {
  @override
  List<ViewModelMember> get members => [];

  @override
  void setDependencies(ViewModelDependencySetter depend) {}
}

class SomeScreen extends StatelessWidget {
  const SomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelDispatcher<SomeVm, SomeParam?>(
      factory: SomeVm.new,
      param: null,
      scope: true, // enable ViewModelScope for supertype retrieval
      child: const SomeWidget(),
    );
  }
}

class SomeWidget extends StatelessWidget {
  const SomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieves by supertype because scope: true is passed here and on dispatcher
    final vm = context.useVmOrNull<SomeAbstractVm>(scope: true);
    return Text(vm == null ? 'no vm' : 'vm ok');
  }
}
```

Retrieve Param by a supertype:

```dart
abstract base class SomeBaseParam extends ViewModelParameter {
  const SomeBaseParam();
  @override
  bool shouldUpdateDependencies(ViewModelParameter? oldParam) => false;
}

final class SomeParam extends SomeBaseParam {
  const SomeParam();
}

class ParamConsumer extends StatelessWidget {
  const ParamConsumer({super.key});

  @override
  Widget build(BuildContext context) {
    final param = context.useParamOrNull<SomeBaseParam>(scope: true);
    return Text(param == null ? 'no param' : 'param ok');
  }
}

class ParamScopeScreen extends StatelessWidget {
  const ParamScopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelDispatcher<SomeVm, SomeBaseParam?>(
      factory: SomeVm.new,
      param: const SomeParam(),
      scope: true,
      child: const ParamConsumer(),
    );
  }
}
```

Performance tips:

- Prefer exact-type retrieval (`useVM<Exact>()`, `useParam<Exact>()`) whenever possible.
- Use `scope: true` selectively on dispatchers that must support supertype retrieval.
- Combine with `listen: false` in `useVmOrNull`/`useParamOrNull` when you only need a one-time lookup.

## Members in detail

### Keep in mind

1. All members are Listenable and can be used with ListenableBuilder.
2. All members can be declared directly or via `ViewModel.member` factory (preferred). Refer to
   `ViewModelFactory` for more details.

### Available members

- ValueMember
    - Holds a single value. Updates notify listeners only when the value actually changes.
- ListMember and SetMember
    - Hold collections and provide mutating helpers (add, remove, insert, etc.).
    - Expose immutable views (`UnmodifiableListView`, `UnmodifiableSetView`) to consumers.
- StreamMember
    - Subscribes to a Stream from `resolver` parameter.
    - On new stream or new events, manages subscription lifecycle and notifies changes only when
      data changes.
- NavigationMember
    - Allows ViewModel-driven navigation. In widgets, use `useNavigation((context, data) { ... })`
      to react to events.
    - `NavigationMember.autoReset(initial: ...)` is available to auto-reset after update via
      `resolver`.
- ModalFlowMember
    - Request a modal via await `modal.requestModal()`.
    - In widgets, call `modal.useModal((context) => showModalBottomSheet(...))` to open/complete the
      flow.
    - Supports programmatic close via `reset()` and handles result completion.
- Flutter members
    - Manages corresponding Flutter controllers, listens to its changes, allows updating controller
      state on VM updates.
    - Members:
        - EditableTextMember for `TextEditingController`
        - AnimationMember for `AnimationController`
        - FocusMember for `FocusNode`
        - TabMember for `TabController`

## Dependencies between members

Members can be defined as dependent from each other. If you're using codegen, just access other
member in the constructor of member (typically in `resolver`):

```dart
@Meovm()
class SomeVm extends ViewModel with _$SomeVm {
  @override
  late final memberA = member.value(initial: 0);

  @override
  late final memberB = member.value(
    resolver: (_) => memberA.data + 1,
  );
}
```

That's it! Now, meovm will take care of updating memberB when memberA changes, as well as update
order of this members on full VM updates.

Note that you can use members from other VMs (passed within parameter) as well:

```dart
@Meovm()
class ExternalVm extends ViewModel with _$ExternalVm {
  @override
  late final value = member.value(initial: 0);
}

@Meovm()
class SomeParam extends ViewModelParameter with _$SomeParam {
  SomeParam({
    required this.externalMember,
    required this.externalVm,
  });

  @override
  final ValueMember<int> externalMember;

  @override
  final ExternalVm externalVm;
}

@Meovm()
class SomeVm extends ViewModel<SomeParam> with _$SomeVm {
  @override
  late final memberA = member.value(resolver: (_) => param.externalMember.data + 1);

  @override
  late final memberB = member.value(
    resolver: (_) => param.externalVm.value.data + 1,
  );
}
```

Alternatively, if you're not using codegen, set dependencies manually:

```dart
class SomeVm extends ViewModel {
  late final memberA = member.value(initial: 0);

  late final memberB = member.value(
    resolver: (_) => memberA.data + 1,
  );

  @override
  List<ViewModelMember> get members => [memberA, memberB];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(memberA, memberB);
  }
}
```

## Accessing ViewModel and params in widgets

Use `BuildContext` extensions:

```dart

final vm = context.useVM<MyVm>(); // throws if not found
final vmOrNull = context.useVmOrNull<MyVm>();

final param = context.useParam<MyParam>(); // throws if not found
final paramOrNull = context.useParamOrNull<MyParam>();
```

## Diagnostics

All ViewModels and members implement diagnostics for Flutter DevTools:

- ViewModel prints current state and member list with dependencies
- Members print meaningful current values, lengths, focus state, etc.