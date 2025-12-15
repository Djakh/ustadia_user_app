import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/theme.dart';
import 'package:ustadia_user_app/features/posts/presentation/bloc/post_bloc.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class UstadiaUserApp extends StatelessWidget {
  const UstadiaUserApp({super.key});

  /// --- Widgets ---

  Widget get materialApp => MaterialApp.router(
        title: 'Ustadia User',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter
      );

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [BlocProvider<PostBloc>(create: (_) => sl<PostBloc>())],
        child: materialApp,
      );
}
