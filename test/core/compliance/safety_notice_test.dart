import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/compliance/safety_notice.dart';

void main() {
  Widget host() => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const SafetyNoticeDialog(type: SafetyNoticeType.ieltsWritingSubmission)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  testWidgets('IELTS notice blocks outside dismissal and supports cancel', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Submit your IELTS Writing safely'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('Submit your IELTS Writing safely'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Submit your IELTS Writing safely'), findsNothing);
  });
}
