import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meovm/meovm.dart';

void main() {
  FlutterMembersTests().run();
}

class CounterNotifier extends ChangeNotifier {
  int value = 0;

  void increment() {
    value++;
    notifyListeners();
  }
}

class _CustomNotifierVm extends ViewModel {
  late final custom = CustomChangeNotifierMember<CounterNotifier>(
    () => CounterNotifier(),
  );

  @override
  List<ViewModelMember> get members => [custom];
}

class FlutterMembersTests {
  void run() {
    group('Flutter members', () {
      _editableTextMember();
      _animationMember();
      _focusMember();
      _tabMember();
      _customChangeNotifierMember();
    });
  }

  void _editableTextMember() {
    testWidgets('EditableTextMember updates UI when text changes', (tester) async {
      final vm = _EditableTextVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_EditableTextVm>();
                final editable = vm.editable;

                return editable.build(
                  builder: (_, _) => Text(
                    editable.controller.text,
                    key: const ValueKey('editable_text'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('editable_text')), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);

      vm.editable.controller.text = 'World';
      await tester.pump();

      expect(find.text('World'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);
    });
  }

  void _animationMember() {
    testWidgets('AnimationMember rebuilds when controller value changes', (tester) async {
      final vm = _AnimationMemberVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_AnimationMemberVm>();
                final anim = vm.animation;

                return anim.build(
                  builder: (_, _) => Text(
                    anim.controller.value.toStringAsFixed(1),
                    key: const ValueKey('anim_value'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('anim_value')), findsOneWidget);
      // Initial value is 0.0 by default
      expect(find.text('0.0'), findsOneWidget);

      vm.animation.controller.value = 0.5;
      await tester.pump();

      expect(find.text('0.5'), findsOneWidget);
    });
  }

  void _focusMember() {
    testWidgets('FocusMember notifies and UI updates on focus change', (tester) async {
      final vm = _FocusMemberVm();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewModelDispatcher(
              factory: () => vm,
              param: null,
              child: Builder(
                builder: (context) {
                  final vm = context.useVM<_FocusMemberVm>();
                  final focus = vm.focus;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      focus.build(
                        builder: (_, _) => Text(
                          focus.node.hasFocus ? 'focused' : 'not focused',
                          key: const ValueKey('focus_state'),
                        ),
                      ),
                      // Attach the FocusNode to the tree so it can gain focus
                      Focus(
                        focusNode: focus.node,
                        child: const SizedBox(width: 1, height: 1),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('focus_state')), findsOneWidget);
      expect(find.text('not focused'), findsOneWidget);

      // Directly request focus to avoid hit testing issues in headless tests
      vm.focus.node.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('focused'), findsOneWidget);
    });
  }

  void _tabMember() {
    testWidgets('TabMember swaps controller on update and keeps listeners', (tester) async {
      final vm = _TabMemberVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_TabMemberVm>();
                final tabs = vm.tabs;
                final tabsCount = vm.tabsCount;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Length is driven by tabsCount updates
                    tabsCount.build(
                      builder: (_, _) => Text(
                        'len=${tabs.controller.length}',
                        key: const ValueKey('tabs_len'),
                      ),
                    ),
                    // Index is driven by TabController notifications
                    tabs.build(
                      builder: (_, _) => Text(
                        'index=${tabs.controller.index}',
                        key: const ValueKey('tabs_index'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('tabs_len')), findsOneWidget);
      expect(find.byKey(const ValueKey('tabs_index')), findsOneWidget);
      expect(find.text('len=2'), findsOneWidget);
      expect(find.text('index=0'), findsOneWidget);

      // Change the number of tabs, which should trigger updateController
      vm.tabsCount.data = 3;
      // Allow frames for async disposal/swap scheduling
      await tester.pumpAndSettle();

      expect(find.text('len=3'), findsOneWidget);
      expect(find.text('index=0'), findsOneWidget);

      // Move to next tab and ensure listener still works
      vm.tabs.controller.index = 1;
      await tester.pumpAndSettle();
      expect(find.text('index=1'), findsOneWidget);
      // Ensure no pending timers (scheduled dispose) remain
      await tester.pumpAndSettle();
    });
  }

  void _customChangeNotifierMember() {
    testWidgets('CustomChangeNotifierMember rebuilds on notifyListeners', (tester) async {
      final vm = _CustomNotifierVm();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewModelDispatcher(
            factory: () => vm,
            param: null,
            child: Builder(
              builder: (context) {
                final vm = context.useVM<_CustomNotifierVm>();
                final member = vm.custom;

                return member.build(
                  builder: (_, _) => Text(
                    member.notifier.value.toString(),
                    key: const ValueKey('custom_value'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('custom_value')), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      vm.custom.notifier.increment();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });
  }
}

class _EditableTextVm extends ViewModel {
  late final editable = EditableTextMember(initText: () => 'Hello');

  @override
  List<ViewModelMember> get members => [editable];
}

class _AnimationMemberVm extends ViewModel {
  late final animation = AnimationMember(
    initController: () => AnimationController(vsync: owner, lowerBound: 0, upperBound: 1),
  );

  @override
  List<ViewModelMember> get members => [animation];
}

class _FocusMemberVm extends ViewModel {
  late final focus = FocusMember();

  @override
  List<ViewModelMember> get members => [focus];
}

class _TabMemberVm extends ViewModel {
  late final tabsCount = ValueMember<int>(initial: 2);

  late final tabs = TabMember(
    initController: () => TabController(length: tabsCount.data, vsync: owner),
    updateController: (old) {
      if (old.length != tabsCount.data) {
        return TabController(length: tabsCount.data, vsync: owner);
      }
      return old;
    },
  );

  @override
  List<ViewModelMember> get members => [tabs, tabsCount];

  @override
  void setDependencies(ViewModelDependencySetter depend) {
    depend(tabsCount, tabs);
  }
}
