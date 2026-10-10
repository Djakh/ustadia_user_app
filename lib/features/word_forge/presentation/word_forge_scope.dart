import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/services/word_forge_audio.dart';
import '../word_forge_module.dart';
import 'cubit/word_forge_cubit.dart';

/// Session services shared by every Word Forge screen.
class WordForgeScope extends InheritedWidget {
  final WordForgeDependencies dependencies;
  final WordForgeAudio audio;

  const WordForgeScope({super.key, required this.dependencies, required this.audio, required super.child});

  static WordForgeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WordForgeScope>();
    assert(scope != null, 'WordForgeScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(WordForgeScope oldWidget) =>
      oldWidget.dependencies != dependencies || oldWidget.audio != audio;
}

/// Word Forge navigates with plain Navigator routes so the module does not
/// depend on the host app's router. Each pushed page is re-wrapped with the
/// session scope and cubit.
abstract final class WordForgeNavigator {
  static Future<T?> push<T>(BuildContext context, Widget page, {bool fade = false}) {
    final scope = WordForgeScope.of(context);
    final cubit = context.read<WordForgeCubit>();
    Widget wrap(BuildContext _) => WordForgeScope(
          dependencies: scope.dependencies,
          audio: scope.audio,
          child: BlocProvider.value(value: cubit, child: page),
        );
    return Navigator.of(context).push<T>(PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: fade ? 450 : 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, __) => wrap(context),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        if (fade) return FadeTransition(opacity: curved, child: child);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ));
  }
}
