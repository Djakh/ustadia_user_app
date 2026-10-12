import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/services/subscription_expired_handler.dart';

void main() {
  late DateTime now;
  late String path;
  late int opened;
  late SubscriptionExpiredHandler handler;

  setUp(() {
    now = DateTime(2026, 10, 10, 12);
    path = '/home/learn_lessons';
    opened = 0;
    handler = SubscriptionExpiredHandler(
        openPaywall: () => opened++,
        currentPath: () => path,
        ignoredPaths: const {'/', '/login'},
        clock: () => now);
  });

  test('a burst of 402 responses opens the paywall once', () {
    handler
      ..handle()
      ..handle()
      ..handle();

    expect(opened, 1);
  });

  test('does not open a second paywall while one is visible', () {
    handler.handle();
    handler.paywallShown();
    now = now.add(const Duration(minutes: 1));

    handler.handle();

    expect(opened, 1);
  });

  test('a paywall the student opened also blocks the automatic one', () {
    handler.paywallShown();

    handler.handle();

    expect(opened, 0);
  });

  test('stays quiet right after the paywall is closed, then opens again', () {
    handler
      ..handle()
      ..paywallShown()
      ..paywallHidden();

    now = now.add(const Duration(seconds: 2));
    handler.handle();
    expect(opened, 1);

    now = now.add(const Duration(seconds: 5));
    handler.handle();
    expect(opened, 2);
  });

  test('a paywall that never appeared does not block forever', () {
    handler.handle();

    now = now.add(const Duration(seconds: 4));
    handler.handle();

    expect(opened, 2);
  });

  test('ignores auth pages, which replace the whole stack', () {
    path = '/login';
    handler.handle();
    path = '/';
    handler.handle();

    expect(opened, 0);
  });

  test('reset clears the cooldown after a purchase', () {
    handler
      ..handle()
      ..paywallShown()
      ..paywallHidden()
      ..reset();

    handler.handle();

    expect(opened, 2);
  });
}
