import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/injection_container.dart';

class AskAiPage extends StatefulWidget {
  const AskAiPage({super.key});

  @override
  State<AskAiPage> createState() => _AskAiPageState();
}

class _AskAiPageState extends State<AskAiPage> {
  final UserBloc userBloc = sl<UserBloc>();

  Widget get view => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text("Coming soon", style: Style.headline5w7(context))],
      );

  @override
  Widget build(BuildContext context) =>
      PrimaryBackground(isScrollable: false, backgroundColor: context.cs.surface, child: view);
}
