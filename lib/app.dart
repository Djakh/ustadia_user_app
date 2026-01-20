import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/theme.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/posts/presentation/bloc/post_bloc.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';
import 'package:ustadia_user_app/size_config.dart';

class UstadiaUserApp extends StatelessWidget {
  const UstadiaUserApp({super.key});

  /// --- Widgets ---

  Widget get materialApp => LayoutBuilder(builder: (context, constraints) {
        SizeConfig().init(context, constraints);
        return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<PostBloc>()),
              BlocProvider(create: (_) => NextTaskBloc()),
              BlocProvider(create: (_) => sl<UserBloc>()),
              BlocProvider(create: (_) => sl<FileUploadBloc>()),
              BlocProvider(create: (_) => sl<TeacherBloc>()..add(const TeachersRequested())),
            ],
            child: MaterialApp.router(
                title: 'Ustadia User',
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: ThemeMode.light,
                routerConfig: appRouter));
      });
  @override
  Widget build(BuildContext context) => materialApp;
}
