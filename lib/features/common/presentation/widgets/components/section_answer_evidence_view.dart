import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';

class SectionAnswerEvidenceView extends StatelessWidget {
  final String content;
  final SectionAnswerModel answer;
  final TextStyle? textStyle;

  const SectionAnswerEvidenceView({
    super.key,
    required this.content,
    required this.answer,
    this.textStyle,
  });

  bool get hasTranscript => answer.transcript?.trim().isNotEmpty == true;

  List<dom.Node> get _contentNodes {
    final fragment = html_parser.parseFragment(content);
    return fragment.nodes;
  }

  TextStyle highlightedStyle(TextStyle style) => style.copyWith(
      color: AppColors.green36,
      fontWeight: FontWeight.w700,
      backgroundColor: AppColors.greenE7.withValues(alpha: 0.9));

  String _formatAudioTime(double value) {
    final totalSeconds = value.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _audioEvidenceView(BuildContext context) {
    if (!answer.hasAudioEvidenceData) return const SizedBox.shrink();
    final range =
        '${_formatAudioTime(answer.audioStartTime!)} - ${_formatAudioTime(answer.audioEndTime!)}';
    return Container(
        margin: EdgeInsets.only(bottom: answer.hasEvidenceRangeData ? 16 : 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.blueFF,
            borderRadius: Style.border16,
            border: Border.all(color: AppColors.blueD3.withValues(alpha: 0.16))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(Icons.graphic_eq_rounded, color: AppColors.blueD3, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audio answer time'.tr(),
                style: Style.small3w5(context).copyWith(color: AppColors.blueD3)),
            const SizedBox(height: 4),
            Text(range, style: Style.bodyw6(context).copyWith(color: AppColors.blueD3)),
            if (hasTranscript) ...[
              const SizedBox(height: 8),
              Text(answer.transcript!.trim(),
                  style: Style.small3w4(context).copyWith(color: AppColors.gray700))
            ]
          ]))
        ]));
  }

  TextStyle _styleForElement(dom.Element element, TextStyle style) {
    switch (element.localName) {
      case 'strong':
      case 'b':
        return style.copyWith(fontWeight: FontWeight.w700);
      case 'em':
      case 'i':
        return style.copyWith(fontStyle: FontStyle.italic);
      case 'u':
        return style.copyWith(decoration: TextDecoration.underline);
      default:
        return style;
    }
  }

  _HtmlPositionMap _computePositionMap(List<dom.Node> nodes) {
    final buffer = StringBuffer();
    final segments = <_TextSegment>[];

    void walk(dom.Node node) {
      if (node is dom.Text) {
        final text = node.text;
        final start = buffer.length;
        buffer.write(text);
        final end = buffer.length;
        segments.add(_TextSegment(node: node, start: start, end: end, text: text));
        return;
      }
      for (final child in node.nodes) {
        walk(child);
      }
    }

    for (final node in nodes) {
      walk(node);
    }
    return _HtmlPositionMap(cleanText: buffer.toString(), segments: segments);
  }

  _EvidenceRange? _evidenceRange(_HtmlPositionMap positionMap) {
    if (!answer.hasEvidenceRangeData || positionMap.cleanText.isEmpty) return null;
    final declaredStart = answer.startPosition!;
    final declaredEnd = answer.endPosition!;
    final cleanLength = positionMap.cleanText.length;
    final start = declaredStart.clamp(0, cleanLength);
    final end = declaredEnd.clamp(0, cleanLength);
    if (end <= start) return null;

    final transcript = answer.transcript?.trim();
    if (transcript == null || transcript.isEmpty) {
      return _EvidenceRange(start: start, end: end);
    }

    final declaredText = positionMap.cleanText.substring(start, end).trim();
    if (declaredText == transcript) return _EvidenceRange(start: start, end: end);

    final transcriptStart = nearestTranscriptStart(
        cleanText: positionMap.cleanText, transcript: transcript, preferredStart: declaredStart);
    if (transcriptStart == null) return _EvidenceRange(start: start, end: end);
    return _EvidenceRange(start: transcriptStart, end: transcriptStart + transcript.length);
  }

  void _addTextSpans(dom.Text node, TextStyle style, List<TextSpan> spans,
      Map<dom.Text, _TextSegment> segmentByNode, _EvidenceRange? range) {
    final text = node.text;
    if (text.isEmpty) return;
    final segment = segmentByNode[node];
    if (segment == null) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }
    final nodeStart = segment.start;
    final nodeEnd = segment.end;

    if (range == null) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    if (range.end <= nodeStart || range.start >= nodeEnd) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    final localStart = (range.start - nodeStart).clamp(0, text.length);
    final localEnd = (range.end - nodeStart).clamp(0, text.length);

    if (localStart > 0) {
      spans.add(TextSpan(text: text.substring(0, localStart), style: style));
    }
    if (localEnd > localStart) {
      spans.add(
          TextSpan(text: text.substring(localStart, localEnd), style: highlightedStyle(style)));
    }
    if (localEnd < text.length) {
      spans.add(TextSpan(text: text.substring(localEnd), style: style));
    }
  }

  void _addNodeSpans(dom.Node node, TextStyle style, List<TextSpan> spans,
      Map<dom.Text, _TextSegment> segmentByNode, _EvidenceRange? range) {
    if (node is dom.Text) {
      _addTextSpans(node, style, spans, segmentByNode, range);
      return;
    }
    if (node is dom.Element && node.localName == 'br') {
      spans.add(TextSpan(text: '\n', style: style));
      return;
    }
    final nextStyle = node is dom.Element ? _styleForElement(node, style) : style;
    for (final child in node.nodes) {
      _addNodeSpans(child, nextStyle, spans, segmentByNode, range);
    }
  }

  Widget _paragraph(BuildContext context, dom.Node node, Map<dom.Text, _TextSegment> segmentByNode,
      _EvidenceRange? range) {
    final style = textStyle ?? Style.bodyw4(context);
    final spans = <TextSpan>[];
    _addNodeSpans(node, style, spans, segmentByNode, range);
    if (node is dom.Text && node.text.trim().isEmpty) return const SizedBox.shrink();
    if (spans.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RichText(text: TextSpan(children: spans), textAlign: TextAlign.start));
  }

  @override
  Widget build(BuildContext context) {
    if (!answer.hasAnswerEvidenceData) return const SizedBox.shrink();
    final nodes = _contentNodes;
    final positionMap = _computePositionMap(nodes);
    final segmentByNode = {for (final segment in positionMap.segments) segment.node: segment};
    final range = _evidenceRange(positionMap);
    final contentView = content.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: nodes.map((node) => _paragraph(context, node, segmentByNode, range)).toList())
        : const SizedBox.shrink();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_audioEvidenceView(context), contentView]);
  }
}

@visibleForTesting
int? nearestTranscriptStart(
    {required String cleanText, required String transcript, required int preferredStart}) {
  if (cleanText.isEmpty || transcript.isEmpty) return null;
  var bestIndex = -1;
  var bestDistance = 1 << 62;
  var index = cleanText.indexOf(transcript);
  while (index != -1) {
    final distance = (index - preferredStart).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = index;
    }
    index = cleanText.indexOf(transcript, index + transcript.length);
  }
  return bestIndex == -1 ? null : bestIndex;
}

class _HtmlPositionMap {
  final String cleanText;
  final List<_TextSegment> segments;

  const _HtmlPositionMap({required this.cleanText, required this.segments});
}

class _TextSegment {
  final dom.Text node;
  final int start;
  final int end;
  final String text;

  const _TextSegment(
      {required this.node, required this.start, required this.end, required this.text});
}

class _EvidenceRange {
  final int start;
  final int end;

  const _EvidenceRange({required this.start, required this.end});
}
