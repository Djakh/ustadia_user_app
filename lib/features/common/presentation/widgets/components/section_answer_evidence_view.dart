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

  List<dom.Node> get contentNodes {
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

  void _addTextSpans(dom.Text node, TextStyle style, List<TextSpan> spans, _PositionCursor cursor) {
    final text = node.text;
    if (text.isEmpty) return;
    final nodeStart = cursor.value;
    final nodeEnd = nodeStart + text.length;
    cursor.value = nodeEnd;

    if (!answer.hasEvidenceRangeData) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    final highlightStart = answer.startPosition!;
    final highlightEnd = answer.endPosition!;

    if (highlightEnd <= nodeStart || highlightStart >= nodeEnd) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    final localStart = (highlightStart - nodeStart).clamp(0, text.length);
    final localEnd = (highlightEnd - nodeStart).clamp(0, text.length);

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

  void _addNodeSpans(dom.Node node, TextStyle style, List<TextSpan> spans, _PositionCursor cursor) {
    if (node is dom.Text) {
      _addTextSpans(node, style, spans, cursor);
      return;
    }
    if (node is dom.Element && node.localName == 'br') {
      spans.add(TextSpan(text: '\n', style: style));
      return;
    }
    final nextStyle = node is dom.Element ? _styleForElement(node, style) : style;
    for (final child in node.nodes) {
      _addNodeSpans(child, nextStyle, spans, cursor);
    }
  }

  Widget _paragraph(BuildContext context, dom.Node node, _PositionCursor cursor) {
    final style = textStyle ?? Style.bodyw4(context);
    final spans = <TextSpan>[];
    _addNodeSpans(node, style, spans, cursor);
    if (node is dom.Text && node.text.trim().isEmpty) return const SizedBox.shrink();
    if (spans.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RichText(text: TextSpan(children: spans), textAlign: TextAlign.start));
  }

  @override
  Widget build(BuildContext context) {
    if (!answer.hasAnswerEvidenceData) return const SizedBox.shrink();
    final cursor = _PositionCursor();
    final contentView = content.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: contentNodes.map((node) => _paragraph(context, node, cursor)).toList())
        : const SizedBox.shrink();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_audioEvidenceView(context), contentView]);
  }
}

class _PositionCursor {
  int value = 0;
}
