import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_picture_in_picture.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_player_page.dart';

void main() {
  testWidgets('changes size and snaps to every screen corner', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Stack(children: [
      HtmlVideoPictureInPicture(
          params: const HtmlVideoPlayerParams(url: ''), onClose: () {}, onEnterFullscreen: (_) {}),
    ]))));
    await tester.pump();

    AnimatedPositioned position() =>
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));

    expect(position().left, closeTo(12, .01));
    final initialWidth = position().width!;
    expect(initialWidth, closeTo(376, .01));

    await tester.tap(find.byTooltip('Change player size'));
    await tester.pumpAndSettle();
    final resizedWidth = position().width!;
    expect(resizedWidth, lessThan(initialWidth));
    final expectedRight = 400 - 12 - resizedWidth;
    final expectedBottom = 800 - 12 - resizedWidth / (16 / 9);

    await tester.drag(find.byTooltip('Move video'), const Offset(-1000, -1000));
    await tester.pumpAndSettle();
    expect(position().left, closeTo(12, .01));
    expect(position().top, closeTo(12, .01));

    await tester.drag(find.byTooltip('Move video'), const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(position().left, closeTo(expectedRight, .01));
    expect(position().top, closeTo(12, .01));

    await tester.drag(find.byTooltip('Move video'), const Offset(-1000, 1000));
    await tester.pumpAndSettle();
    expect(position().left, closeTo(12, .01));
    expect(position().top, closeTo(expectedBottom, .01));

    await tester.drag(find.byTooltip('Move video'), const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(position().left, closeTo(expectedRight, .01));
    expect(position().top, closeTo(expectedBottom, .01));
  });
}
