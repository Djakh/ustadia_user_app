import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

void main() {
  test('parses section image and linked hotspot file', () {
    final section = SectionModel.fromJson({
      'id': 'section-1',
      'type': 'article',
      'image': {'id': 'image-1', 'url': '/uploads/body.jpg'},
      'link_positions': [
        {
          'id': 'position-1',
          'x': 40.5,
          'y': 60,
          'width': 12,
          'height': 8,
          'link': 'https://example.com/video.mp4'
        },
        {
          'id': 'position-2',
          'x': 10,
          'y': 20,
          'file_id': 'video-1',
          'file': {
            'id': 'video-1',
            'filename': 'lesson.mp4',
            'mimetype': 'video/mp4',
            'url': '/uploads/lesson.mp4'
          }
        }
      ]
    });

    expect(section.sectionType, SectionType.article);
    expect(section.image?.url, '/uploads/body.jpg');
    expect(section.linkPositions, hasLength(2));
    expect(section.linkPositions.first.x, 40.5);
    expect(section.linkPositions.first.targetUrl, 'https://example.com/video.mp4');
    expect(section.linkPositions.last.file?.mimetype, 'video/mp4');
    expect(section.linkPositions.last.targetUrl, '/uploads/lesson.mp4');

    final reading = SectionModel.fromJson({
      'id': 'reading-1',
      'type': 'reading',
      'image': {'url': '/uploads/should-not-render.jpg'},
      'link_positions': [
        {'x': 10, 'y': 10, 'link': 'https://example.com/video.mp4'}
      ]
    });
    expect(reading.image, isNull);
    expect(reading.linkPositions, isEmpty);
  });
}
