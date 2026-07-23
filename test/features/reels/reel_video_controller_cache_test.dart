import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/reels/presentation/widgets/reel_video_player.dart';

void main() {
  test('uses the original media URL after a stream endpoint fails', () {
    final cache = ReelVideoControllerCache();
    const streamUrl = 'https://backend.ustadia.findecor.io/uploads/video.mp4/stream';
    const originalUrl = 'https://backend.ustadia.findecor.io/uploads/video.mp4';

    expect(cache.preferredUrl(streamUrl), streamUrl);

    cache.rememberFallback(failedUrl: streamUrl, fallbackUrl: originalUrl);

    expect(cache.preferredUrl(streamUrl), originalUrl);
    cache.clear();
    expect(cache.preferredUrl(streamUrl), streamUrl);
  });
}
