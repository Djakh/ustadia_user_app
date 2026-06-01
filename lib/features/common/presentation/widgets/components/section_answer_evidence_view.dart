import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class SectionAnswerEvidenceView extends StatelessWidget {
  final String content;
  final String questionId;
  final TextStyle? textStyle;

  const SectionAnswerEvidenceView({
    super.key,
    required this.content,
    required this.questionId,
    this.textStyle,
  });

  static bool hasEvidence({required String content, required String questionId}) {
    if (content.isEmpty || questionId.isEmpty) return false;
    final fragment = html_parser.parseFragment(content);
    return fragment.querySelectorAll('mark').any((element) =>
        element.attributes['data-qid'] == questionId && element.text.trim().isNotEmpty);
  }

  List<dom.Node> get contentNodes {
    final fragment = html_parser.parseFragment(content);
    final blockNodes = fragment.nodes.where(_isBlockNode).toList();
    return blockNodes.isEmpty ? fragment.nodes : blockNodes;
  }

  bool _isBlockNode(dom.Node node) {
    if (node is! dom.Element) return false;
    return const {'p', 'div', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}.contains(node.localName);
  }

  bool _isQuestionMark(dom.Node node) =>
      node is dom.Element && node.localName == 'mark' && node.attributes['data-qid'] == questionId;

  void addNodeSpans(BuildContext context, dom.Node node, TextStyle style, List<TextSpan> spans,
      {bool highlighted = false}) {
    final nextHighlighted = highlighted || _isQuestionMark(node);
    if (node is dom.Text) {
      final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty) return;
      spans.add(TextSpan(
          text: text,
          style: nextHighlighted
              ? style.copyWith(
                  color: AppColors.green36,
                  fontWeight: FontWeight.w700,
                  backgroundColor: AppColors.greenE7.withValues(alpha: 0.9))
              : style));
      return;
    }
    if (node is dom.Element && node.localName == 'br') {
      spans.add(const TextSpan(text: '\n'));
      return;
    }
    for (final child in node.nodes) {
      addNodeSpans(context, child, style, spans, highlighted: nextHighlighted);
    }
  }

  Widget paragraph(BuildContext context, dom.Node node) {
    final style = textStyle ?? Style.bodyw4(context);
    final spans = <TextSpan>[];
    addNodeSpans(context, node, style, spans);
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RichText(text: TextSpan(children: spans), textAlign: TextAlign.start));
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: contentNodes.map((node) => paragraph(context, node)).toList());
}
