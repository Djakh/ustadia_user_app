import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_answer_evidence_view.dart';

void main() {
  testWidgets('highlights using clean text positions across inline and block tags', (tester) async {
    const content = '<p>The <b>quick</b> &amp; brown</p><p><i>fox</i> jumps</p>';
    const cleanText = 'The quick & brownfox jumps';
    final start = cleanText.indexOf('brownfox');
    final end = start + 'brownfox'.length;

    await _pumpEvidenceView(tester, content: content, start: start, end: end);

    expect(_highlightedTexts(), containsAll(['brown', 'fox']));
    expect(_highlightedTexts(), isNot(contains('&')));
  });

  testWidgets('br tag is visual only and does not shift highlight positions', (tester) async {
    const content = '<p>Hello<br>world answer</p>';
    const cleanText = 'Helloworld answer';
    final start = cleanText.indexOf('world');
    final end = start + 'world'.length;

    await _pumpEvidenceView(tester, content: content, start: start, end: end);

    expect(_highlightedTexts(), contains('world'));
  });

  test('nearestTranscriptStart chooses the transcript occurrence closest to declared start', () {
    const cleanText = 'alpha beta gamma alpha beta';
    final preferredStart = cleanText.lastIndexOf('alpha beta') + 2;

    final start = nearestTranscriptStart(
        cleanText: cleanText, transcript: 'alpha beta', preferredStart: preferredStart);

    expect(start, cleanText.lastIndexOf('alpha beta'));
  });
}

Future<void> _pumpEvidenceView(WidgetTester tester,
    {required String content, required int start, required int end}) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SectionAnswerEvidenceView(
              content: content,
              answer: SectionAnswerModel(
                  id: 'a1',
                  questionId: 'q1',
                  answerText: 'Answer',
                  isCorrect: true,
                  userSelected: false,
                  orderIndex: 0,
                  transcript: null,
                  startPosition: start,
                  endPosition: end,
                  audioStartTime: null,
                  audioEndTime: null)))));
  await tester.pumpAndSettle();
}

List<String> _highlightedTexts() {
  final highlighted = <String>[];
  for (final richText in find.byType(RichText).evaluate()) {
    final widget = richText.widget as RichText;
    _collectHighlightedTexts(widget.text, highlighted);
  }
  return highlighted;
}

void _collectHighlightedTexts(InlineSpan span, List<String> output) {
  if (span is TextSpan) {
    final hasHighlight = span.style?.backgroundColor != null;
    final text = span.text;
    if (hasHighlight && text != null && text.isNotEmpty) output.add(text);
    span.children?.forEach((child) => _collectHighlightedTexts(child, output));
  }
}
