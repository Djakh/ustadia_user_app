import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';

class PracticeDetailLoader<T> extends StatefulWidget {
  final String title;
  final Future<T> Function() load;
  final Widget Function(T detail) builder;

  const PracticeDetailLoader({
    super.key,
    required this.title,
    required this.load,
    required this.builder,
  });

  @override
  State<PracticeDetailLoader<T>> createState() => _PracticeDetailLoaderState<T>();
}

class _PracticeDetailLoaderState<T> extends State<PracticeDetailLoader<T>> {
  late Future<T> detailFuture;

  @override
  void initState() {
    super.initState();
    detailFuture = widget.load();
  }

  void reload() => setState(() => detailFuture = widget.load());

  Widget waitingView(BuildContext context, {Object? error}) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: widget.title,
          isScrollable: false,
          child: Center(
              child: error == null
                  ? const PrimaryLoadingIndicator(height: 30, width: 30)
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(DioErrorMessage.fromUnknown(error).tr(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Button.text(onTap: reload, text: 'Reload'.tr())
                    ]))));

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) return widget.builder(snapshot.requireData);
        return waitingView(context, error: snapshot.error);
      });
}
