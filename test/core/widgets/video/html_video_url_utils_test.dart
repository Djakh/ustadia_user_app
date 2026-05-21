import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_url_utils.dart';

void main() {
  group('HtmlVideoUrlUtils', () {
    test('extracts YouTube ids from common URL formats', () {
      expect(HtmlVideoUrlUtils.youtubeVideoId('https://youtu.be/abcdefghijk'), 'abcdefghijk');
      expect(HtmlVideoUrlUtils.youtubeVideoId('https://www.youtube.com/watch?v=abcdefghijk'),
          'abcdefghijk');
      expect(
          HtmlVideoUrlUtils.youtubeVideoId('https://youtube.com/shorts/abcdefghijk?feature=share'),
          'abcdefghijk');
      expect(HtmlVideoUrlUtils.youtubeVideoId('www.youtube.com/embed/abcdefghijk'), 'abcdefghijk');
    });

    test('does not treat lookalike domains as YouTube', () {
      expect(
          HtmlVideoUrlUtils.youtubeVideoId('https://notyoutube.com/watch?v=abcdefghijk'), isNull);
    });

    test('detects direct video urls with query parameters', () {
      expect(
          HtmlVideoUrlUtils.isDirectVideoUrl(
              'https://dev.backend.ustadia.findecor.io/uploads/video.mp4?token=123'),
          isTrue);
      expect(HtmlVideoUrlUtils.isDirectVideoUrl('https://example.com/post/123'), isFalse);
    });
  });
}
