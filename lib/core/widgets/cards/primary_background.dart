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
  final String? headerTooltipText;
  final bool isHeader;
  final bool isScrollable;
  final Color? backgroundColor;
  final VoidCallback? onBack;
  const PrimaryBackground(
      {super.key,
      required this.child,
      this.padding,
      this.title,
      this.headerTooltipText,
      this.isHeader = true,
      this.header,
      this.isScrollable = false,
      this.backgroundColor,
      this.onBack});

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
              onTap: widget.onBack ?? () => goBack(context),
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: context.cs.surface, shape: BoxShape.circle),
                  child: Center(child: backButtonIcon))))
      : const SizedBox(width: 40, height: 40);

  Widget titleWidget(BuildContext context) => Text(widget.title ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Style.body3w7(context));

  String? get resolvedHeaderTooltipText {
    final explicit = widget.headerTooltipText?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final title = widget.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return null;
  }

  Widget centerWidget(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Center(
          child: Tooltip(
              message: resolvedHeaderTooltipText ?? '',
              triggerMode: TooltipTriggerMode.longPress,
              waitDuration: Duration.zero,
              preferBelow: false,
              excludeFromSemantics: true,
              child: widget.header ?? titleWidget(context))));

  Widget backButtonAndCenterWidget(BuildContext context) => IntrinsicHeight(
          child: Stack(alignment: Alignment.center, children: [
        Align(alignment: Alignment.centerLeft, child: backButton(context)),
        centerWidget(context)
      ]));

  Widget scrollableChild(BoxConstraints constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight), child: widget.child));

  Widget checkScrollabilityChild(BoxConstraints constraints) =>
      widget.isScrollable ? scrollableChild(constraints) : widget.child;

  Widget view(BuildContext context) => SafeArea(
      child: Container(
          margin: const EdgeInsets.all(8),
          padding: widget.padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: widget.backgroundColor ?? context.cs.secondaryContainer,
              borderRadius: Style.border24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.isHeader) backButtonAndCenterWidget(context),
            Expanded(
                child: LayoutBuilder(
                    builder: (context, constraints) => checkScrollabilityChild(constraints)))
          ])));

  @override
  Widget build(BuildContext context) => view(context);
}
