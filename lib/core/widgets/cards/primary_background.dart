import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PrimaryBackground extends StatefulWidget {
  final Widget child;
  final Widget? header;
  final EdgeInsets? padding;
  final String? title;
  final bool isHeader;

  const PrimaryBackground(
      {super.key,
      required this.child,
      this.padding,
      this.title,
      this.isHeader = true,
      this.header});

  @override
  State<PrimaryBackground> createState() => _PrimaryBackgroundState();
}

class _PrimaryBackgroundState extends State<PrimaryBackground> {
  GoRouter? _router;

  /// --- Life cycle ---

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newRouter = GoRouter.of(context);
    if (_router != newRouter) {
      _router?.routerDelegate.removeListener(_onRouteChange);
      _router = newRouter;
      _router?.routerDelegate.addListener(_onRouteChange);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() => setState(() {});

  /// --- Navigation ---

  bool canGoBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) return true;
    final navigator = Navigator.maybeOf(context);
    return navigator?.canPop() ?? false;
  }

  void goBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final navigator = Navigator.maybeOf(context);
    if (navigator?.canPop() ?? false) navigator!.pop();
  }

  /// --- Widgets ---
  Widget get backButtonIcon => Image.asset(AppImages.arrowLeft);

  Widget backButton(BuildContext context) => context.canPop()
      ? Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () => goBack(context),
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: context.cs.surface, shape: BoxShape.circle),
                  child: Center(child: backButtonIcon))))
      : const SizedBox(width: 40, height: 40);

  Widget titleWidget(BuildContext context) => Center(
      child: Text(widget.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Style.body3w7(context)));

  Widget centerWidget(BuildContext context) => widget.header ?? titleWidget(context);

  Widget backButtonAndCenterWidget(BuildContext context) => IntrinsicHeight(
          child: Stack(alignment: Alignment.center, children: [
        Align(alignment: Alignment.centerLeft, child: backButton(context)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 56), child: centerWidget(context))
      ]));

  Widget view(BuildContext context) => SafeArea(
      child: Container(
          margin: const EdgeInsets.all(8),
          padding: widget.padding ?? const EdgeInsets.all(12),
          decoration:
              BoxDecoration(color: context.cs.secondaryContainer, borderRadius: Style.border24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ THIS FIXES IT

              children: [
                if (widget.isHeader) backButtonAndCenterWidget(context),
                Expanded(child: widget.child)
              ])));

  @override
  Widget build(BuildContext context) => view(context);
}
