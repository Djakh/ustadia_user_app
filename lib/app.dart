import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/theme.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';
import 'package:ustadia_user_app/size_config.dart';

class UstadiaUserApp extends StatelessWidget {
  const UstadiaUserApp({super.key});

  /// --- Widgets ---

  Locale? localeFromProfile(BuildContext context, String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) return null;
    for (final locale in context.supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }

  Future<void> syncProfileLocale(BuildContext context, String? languageCode) async {
    final targetLocale = localeFromProfile(context, languageCode);
    if (targetLocale == null) return;
    if (context.locale.languageCode == targetLocale.languageCode) return;
    await context.setLocale(targetLocale);
  }

  Widget get materialApp => LayoutBuilder(builder: (context, constraints) {
        SizeConfig().init(context, constraints);
        return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => NextTaskBloc()),
              BlocProvider(create: (_) => sl<UserBloc>()),
              BlocProvider(create: (_) => sl<FileUploadBloc>()),
              BlocProvider(create: (_) => sl<AskAiBloc>()),
              BlocProvider(create: (_) => sl<TeacherBloc>()..add(const TeachersRequested())),
            ],
            child: BlocListener<UserBloc, UserState>(
                listenWhen: (previous, current) =>
                    previous.profile?.language != current.profile?.language &&
                    current.profile != null,
                listener: (context, state) => syncProfileLocale(context, state.profile?.language),
                child: MaterialApp.router(
                    title: 'Ustadia User'.tr(),
                    theme: AppTheme.light(),
                    darkTheme: AppTheme.dark(),
                    themeMode: ThemeMode.light,
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    routerConfig: appRouter)));
      });
  @override
  Widget build(BuildContext context) => materialApp;
}
