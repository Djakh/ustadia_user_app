import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class HtmlText extends StatelessWidget {
  final String data;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const HtmlText(
      {super.key,
      required this.data,
      this.textStyle,
      this.textAlign,
      this.maxLines,
      this.overflow = TextOverflow.ellipsis});

  bool get isHtml => data.contains('<') && data.contains('>');

  String get plainText => data.replaceAll(htmlTagRegex, ' ').replaceAll(spaceRegex, ' ').trim();




  @override
  Widget build(BuildContext context) {


    
    if (!isHtml || maxLines != null) {
      return  Text(plainText.isEmpty ? data : plainText,
          style: textStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines == null ? TextOverflow.visible : overflow);
    }
    return HtmlWidget(
      data,
      textStyle: textStyle,
      customStylesBuilder: (element) {
        if (element.localName == 'body' || element.localName == 'p') {
          return {'margin': '0', 'padding': '0'};
        }
        return null;
      }
    );
  }
}

final RegExp htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true);
final RegExp spaceRegex = RegExp(r'\s+');
