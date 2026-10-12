import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/billing/presentation/pages/payment_checkout_page.dart';

void main() {
  const returnUrl = 'https://students.ustadia.com/plans/return';

  group('isReturnUrl', () {
    test('matches the return url with or without query and sub paths', () {
      expect(PaymentCheckoutPage.isReturnUrl(returnUrl, returnUrl), isTrue);
      expect(PaymentCheckoutPage.isReturnUrl('$returnUrl?order=1&status=ok', returnUrl), isTrue);
      expect(PaymentCheckoutPage.isReturnUrl('$returnUrl/', returnUrl), isTrue);
      expect(
          PaymentCheckoutPage.isReturnUrl(
              'https://STUDENTS.ustadia.com/plans/return?x=1', returnUrl),
          isTrue);
    });

    test('ignores checkout pages and other student pages', () {
      expect(
          PaymentCheckoutPage.isReturnUrl('https://my.paylov.uz/checkout/abc', returnUrl), isFalse);
      expect(PaymentCheckoutPage.isReturnUrl('https://students.ustadia.com/plans', returnUrl),
          isFalse);
      expect(PaymentCheckoutPage.isReturnUrl('https://evil.com/plans/return', returnUrl), isFalse);
      expect(PaymentCheckoutPage.isReturnUrl(null, returnUrl), isFalse);
      expect(PaymentCheckoutPage.isReturnUrl(returnUrl, ''), isFalse);
    });
  });

  test('bank and wallet links leave the WebView', () {
    expect(PaymentCheckoutPage.isExternalScheme(Uri.parse('https://my.paylov.uz')), isFalse);
    expect(PaymentCheckoutPage.isExternalScheme(Uri.parse('about:blank')), isFalse);
    expect(PaymentCheckoutPage.isExternalScheme(Uri.parse('tel:+998901234567')), isTrue);
    expect(PaymentCheckoutPage.isExternalScheme(Uri.parse('intent://pay#Intent;end')), isTrue);
    expect(PaymentCheckoutPage.isExternalScheme(Uri.parse('click://pay?id=1')), isTrue);
  });
}
