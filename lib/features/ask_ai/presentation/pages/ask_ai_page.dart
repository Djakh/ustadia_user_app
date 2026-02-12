import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/coming_soon.dart';
import 'package:ustadia_user_app/injection_container.dart';

class AskAiPage extends StatefulWidget {
  const AskAiPage({super.key});

  @override
  State<AskAiPage> createState() => _AskAiPageState();
}

class _AskAiPageState extends State<AskAiPage> {

  @override
  Widget build(BuildContext context) => PrimaryBackground(
      isScrollable: false, backgroundColor: context.cs.surface, child: const ComingSoonPage());
}
