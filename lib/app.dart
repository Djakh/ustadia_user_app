import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/features/posts/presentation/bloc/post_bloc.dart';
import 'package:ustadia_user_app/features/posts/presentation/pages/post_page.dart';
import 'package:ustadia_user_app/injection_container.dart';

class UstadiaUserApp extends StatelessWidget {
  const UstadiaUserApp({super.key});

  /// --- Widgets ---
  
  Widget get materialApp => MaterialApp(
    title: 'Ustadia User',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
    home: const PostPage(),
  );

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [BlocProvider<PostBloc>(create: (_) => sl<PostBloc>())],
    child: materialApp,
  );
}
