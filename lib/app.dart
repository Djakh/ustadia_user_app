import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/theme.dart';
import 'package:ustadia_user_app/features/posts/presentation/bloc/post_bloc.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';
import 'package:ustadia_user_app/size_config.dart';

class UstadiaUserApp extends StatelessWidget {
  const UstadiaUserApp({super.key});

  /// --- Widgets ---

  Widget get materialApp => LayoutBuilder(builder: (context, constraints) {
        SizeConfig().init(context, constraints);
        return MaterialApp.router(
            title: 'Ustadia User',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.light,
            routerConfig: appRouter);
      });
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [BlocProvider<PostBloc>(create: (_) => sl<PostBloc>())],
        child: materialApp,
      );
}
