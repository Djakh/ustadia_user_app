import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/dom.dart' as dom;
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_player_page.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_url_utils.dart';

class HtmlText extends StatelessWidget {
  static const String videoLinkColor = '#00C950';

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

  String? videoUrlFromElement(dom.Element element) {
    final dataVideo = element.attributes['data-video']?.trim();
    if (dataVideo != null && dataVideo.isNotEmpty) return dataVideo;
    final href = element.attributes['href']?.trim();
    if (href != null && HtmlVideoUrlUtils.isPlayableVideoUrl(href)) return href;
    final textUrl = element.text.trim();
    if (element.classes.contains('video-link') && HtmlVideoUrlUtils.isPlayableVideoUrl(textUrl)) {
      return textUrl;
    }
    return null;
  }

  String videoTitleFromElement(dom.Element element, String url) {
    final title = element.text.trim().replaceAll(spaceRegex, ' ');
    return title.isEmpty ? url : title;
  }

  void openVideoPlayer(BuildContext context, String url, String title) {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) =>
            HtmlVideoPlayerPage(params: HtmlVideoPlayerParams(url: url, title: title))));
  }

  Widget videoLink(BuildContext context, dom.Element element, String url) {
    final title = videoTitleFromElement(element, url);
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(textStyle).copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary);

    return InlineCustomWidget(
        child: Semantics(
            button: true,
            label: title,
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openVideoPlayer(context, url, title),
                child: Text(title, style: effectiveStyle, textAlign: textAlign))));
  }

  @override
  Widget build(BuildContext context) {
    if (!isHtml || maxLines != null) {
      return Text(plainText.isEmpty ? data : plainText,
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
        if (element.localName == 'mark') {
          return {'background-color': 'transparent', 'color': 'inherit'};
        }
        final videoUrl = videoUrlFromElement(element);
        if (videoUrl != null || element.classes.contains('video-link')) {
          return {'font-weight': '700', 'color': videoLinkColor, 'text-decoration': 'underline'};
        }
        return null;
      },
      customWidgetBuilder: (element) {
        final videoUrl = videoUrlFromElement(element);
        if (videoUrl == null) return null;
        return videoLink(context, element, videoUrl);
      },
      onTapUrl: (url) {
        if (!HtmlVideoUrlUtils.isPlayableVideoUrl(url)) return false;
        openVideoPlayer(context, url, url);
        return true;
      },
    );
  }
}

final RegExp htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true);
final RegExp spaceRegex = RegExp(r'\s+');
