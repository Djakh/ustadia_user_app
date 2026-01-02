import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class NavigationShellScope extends InheritedWidget {
  const NavigationShellScope({
    super.key,
    required this.shell,
    required super.child,
  });

  final StatefulNavigationShell shell;

  static StatefulNavigationShell of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavigationShellScope>();
    assert(scope != null, 'NavigationShellScope not found in context');
    return scope!.shell;
  }

  @override
  bool updateShouldNotify(NavigationShellScope oldWidget) => shell != oldWidget.shell;
}
