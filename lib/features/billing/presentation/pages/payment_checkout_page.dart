import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';

/// Paylov checkout inside the app. Pops `true` once Paylov redirects to the
/// order's `return_url`; pops `false`/`null` when the student leaves first.
/// The result is never "paid" — the caller still asks the server.
class PaymentCheckoutPage extends StatefulWidget {
  final BillingPurchaseModel purchase;

  const PaymentCheckoutPage({super.key, required this.purchase});

  /// `return_url` is a web page; the app only needs to know it was reached.
  static bool isReturnUrl(String? url, String returnUrl) {
    if (url == null || url.isEmpty || returnUrl.isEmpty) return false;
    if (url.startsWith(returnUrl)) return true;
    final target = Uri.tryParse(url);
    final expected = Uri.tryParse(returnUrl);
    if (target == null || expected == null || expected.host.isEmpty) return false;
    if (target.host.toLowerCase() != expected.host.toLowerCase()) return false;
    final expectedPath = expected.path.endsWith('/')
        ? expected.path.substring(0, expected.path.length - 1)
        : expected.path;
    return target.path == expectedPath || target.path.startsWith('$expectedPath/');
  }

  /// Bank apps and wallets are opened outside the WebView.
  static bool isExternalScheme(Uri uri) =>
      !const {'http', 'https', 'about', 'data', 'blob', 'javascript'}.contains(uri.scheme);

  @override
  State<PaymentCheckoutPage> createState() => PaymentCheckoutPageState();
}

class PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  InAppWebViewController? webViewController;
  double progress = 0;
  bool hasLoadError = false;
  bool isFinished = false;

  InAppWebViewSettings get settings => InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      javaScriptEnabled: true,
      supportZoom: false,
      allowsBackForwardNavigationGestures: false,
      mediaPlaybackRequiresUserGesture: true);

  /// --- Methods ---

  bool reachedReturnUrl(String? url) =>
      PaymentCheckoutPage.isReturnUrl(url, widget.purchase.returnUrl);

  void finish(bool reachedReturn) {
    if (isFinished || !mounted) return;
    isFinished = true;
    context.pop(reachedReturn);
  }

  Future<NavigationActionPolicy> onNavigation(
      InAppWebViewController controller, NavigationAction action) async {
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;
    if (reachedReturnUrl(uri.toString())) {
      finish(true);
      return NavigationActionPolicy.CANCEL;
    }
    if (PaymentCheckoutPage.isExternalScheme(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  /// Redirects do not always pass through [onNavigation] on every platform.
  void onUrlChanged(InAppWebViewController controller, WebUri? url) {
    if (!reachedReturnUrl(url?.toString())) return;
    controller.stopLoading();
    finish(true);
  }

  void onError(
      InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
    if (request.isForMainFrame == false || isFinished) return;
    if (reachedReturnUrl(request.url.toString())) return;
    setState(() => hasLoadError = true);
  }

  Future<void> retry() async {
    setState(() {
      hasLoadError = false;
      progress = 0;
    });
    final controller = webViewController;
    if (controller == null) return;
    final current = await controller.getUrl();
    await controller.loadUrl(
        urlRequest: URLRequest(url: current ?? WebUri(widget.purchase.checkoutUrl)));
  }

  /// --- Widgets ---

  Widget closeButton(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: () => finish(false),
          borderRadius: Style.border24,
          child: Ink(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: context.cs.secondaryContainer, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 22))));

  Widget header(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(children: [
        closeButton(context),
        Expanded(
            child: Column(children: [
          Text('Payment'.tr(), style: Style.body2w7(context)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_rounded, size: 12, color: AppColors.green36),
            const SizedBox(width: 4),
            Text('Secure payment via Paylov'.tr(),
                style: Style.small2w4(context, color: TextColorRole.greyColor))
          ])
        ])),
        const SizedBox(width: 40)
      ]));

  Widget progressBar(BuildContext context) => SizedBox(
      height: 3,
      child: progress < 1
          ? LinearProgressIndicator(
              value: progress == 0 ? null : progress,
              color: context.cs.primary,
              backgroundColor: AppColors.greenE7)
          : null);

  Widget errorView(BuildContext context) => Container(
      color: context.cs.surface,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(color: AppColors.redE2, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32)),
        const SizedBox(height: 16),
        Text('Payment page did not load'.tr(),
            textAlign: TextAlign.center, style: Style.body2w7(context)),
        const SizedBox(height: 6),
        Text('Check your internet connection and try again.'.tr(),
            textAlign: TextAlign.center,
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 24),
        Button.primary(onTap: retry, text: 'Try again'.tr()),
        const SizedBox(height: 8),
        Button.text(onTap: () => finish(false), text: 'Close'.tr())
      ]));

  Widget webView() => InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.purchase.checkoutUrl)),
      initialSettings: settings,
      onWebViewCreated: (controller) => webViewController = controller,
      shouldOverrideUrlLoading: onNavigation,
      onLoadStart: onUrlChanged,
      onUpdateVisitedHistory: (controller, url, _) => onUrlChanged(controller, url),
      onProgressChanged: (_, value) {
        if (mounted) setState(() => progress = value / 100);
      },
      onReceivedError: onError);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: SafeArea(
          child: Column(children: [
        header(context),
        progressBar(context),
        Expanded(
            child: Stack(children: [
          Positioned.fill(child: webView()),
          if (hasLoadError) Positioned.fill(child: errorView(context))
        ]))
      ])));
}
