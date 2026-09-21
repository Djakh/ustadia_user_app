import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/network/api_url_resolver.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_picture_in_picture.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_player_page.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_url_utils.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_link_position_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays a section image and the teacher-authored clickable areas on it.
/// Coordinates are treated as percentages, which is the convention used by
/// the teacher hotspot editor. Values in the 0..1 range are also accepted as
/// normalized fractions.
class SectionImageLinksView extends StatefulWidget {
  final SectionModel sectionModel;
  final double maxHeight;

  const SectionImageLinksView(
      {super.key, required this.sectionModel, this.maxHeight = double.infinity});

  @override
  State<SectionImageLinksView> createState() => _SectionImageLinksViewState();
}

class _SectionImageLinksViewState extends State<SectionImageLinksView> {
  double aspectRatio = 16 / 9;
  double? sourceImageWidth;
  double? sourceImageHeight;
  ImageStream? imageStream;
  ImageStreamListener? imageStreamListener;
  OverlayEntry? videoOverlay;

  String get imageUrl {
    final url = widget.sectionModel.image?.url ?? '';
    if (url.isEmpty) return '';
    return resolveApiAssetUrl(url, baseUrl: sl<AuthRemoteDataSource>().dio.options.baseUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (imageStream == null && imageUrl.isNotEmpty) resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant SectionImageLinksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionModel.id != widget.sectionModel.id) closeVideoOverlay();
    if (oldWidget.sectionModel.image?.url != widget.sectionModel.image?.url) {
      closeVideoOverlay();
      removeImageListener();
      aspectRatio = 16 / 9;
      sourceImageWidth = null;
      sourceImageHeight = null;
      if (imageUrl.isNotEmpty) resolveImageSize();
    }
  }

  void resolveImageSize() {
    final stream = NetworkImage(imageUrl).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      final width = info.image.width.toDouble();
      final height = info.image.height.toDouble();
      if (mounted && width > 0 && height > 0) {
        setState(() {
          aspectRatio = width / height;
          sourceImageWidth = width;
          sourceImageHeight = height;
        });
      }
    });
    imageStream = stream;
    imageStreamListener = listener;
    stream.addListener(listener);
  }

  void removeImageListener() {
    final stream = imageStream;
    final listener = imageStreamListener;
    if (stream != null && listener != null) stream.removeListener(listener);
    imageStream = null;
    imageStreamListener = null;
  }

  @override
  void dispose() {
    closeVideoOverlay();
    removeImageListener();
    super.dispose();
  }

  double coordinate(double value, double renderedExtent, double? sourceExtent) {
    if (value.abs() <= 1) return value * renderedExtent;
    if (value <= 100) return value / 100 * renderedExtent;
    if (sourceExtent != null && sourceExtent > 0) {
      return value / sourceExtent * renderedExtent;
    }
    return value.clamp(0, renderedExtent).toDouble();
  }

  double dimension(double? value, double renderedExtent, double? sourceExtent, double fallback) {
    if (value == null) return fallback.clamp(1.0, renderedExtent).toDouble();
    return coordinate(value, renderedExtent, sourceExtent).clamp(1.0, renderedExtent).toDouble();
  }

  String resolveTargetUrl(SectionLinkPositionModel position) =>
      resolveApiAssetUrl(position.targetUrl,
          baseUrl: sl<AuthRemoteDataSource>().dio.options.baseUrl);

  bool isVideoTarget(SectionLinkPositionModel position, String url) {
    final mimetype = position.file?.mimetype.toLowerCase() ?? '';
    final filename = position.file?.filename ?? '';
    return mimetype.startsWith('video/') ||
        HtmlVideoUrlUtils.isYoutubeUrl(url) ||
        HtmlVideoUrlUtils.isDirectVideoUrl(url) ||
        HtmlVideoUrlUtils.isDirectVideoUrl(filename);
  }

  Future<void> openPosition(SectionLinkPositionModel position) async {
    final url = resolveTargetUrl(position);
    if (url.isEmpty) return;
    if (isVideoTarget(position, url)) {
      if (!mounted) return;
      showVideoOverlay(url);
      return;
    }
    final parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null || !(parsedUrl.scheme == 'http' || parsedUrl.scheme == 'https')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid link'.tr())));
      }
      return;
    }
    await launchUrl(parsedUrl, mode: LaunchMode.externalApplication);
  }

  void closeVideoOverlay([OverlayEntry? expectedEntry]) {
    final entry = videoOverlay;
    if (entry == null || (expectedEntry != null && entry != expectedEntry)) return;
    videoOverlay = null;
    entry.remove();
  }

  void showVideoOverlay(String url, {Duration initialPosition = Duration.zero}) {
    closeVideoOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
        builder: (_) => HtmlVideoPictureInPicture(
            params: HtmlVideoPlayerParams(
                url: url, title: widget.sectionModel.title, initialPosition: initialPosition),
            onClose: () => closeVideoOverlay(entry),
            onEnterFullscreen: (position) =>
                openFullscreen(url, position: position, sourceEntry: entry)));
    videoOverlay = entry;
    overlay.insert(entry);
  }

  Future<void> openFullscreen(String url,
      {required Duration position, required OverlayEntry sourceEntry}) async {
    closeVideoOverlay(sourceEntry);
    if (!mounted) return;
    final resumePosition = await Navigator.of(context, rootNavigator: true).push<Duration>(
        MaterialPageRoute(
            builder: (_) => HtmlVideoPlayerPage(
                params: HtmlVideoPlayerParams(
                    url: url, title: widget.sectionModel.title, initialPosition: position))));
    if (mounted && resumePosition != null) {
      showVideoOverlay(url, initialPosition: resumePosition);
    }
  }

  Future<void> openExpandedImage() async {
    if (!mounted || imageUrl.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (pageContext) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
                child: Stack(children: [
              Positioned.fill(
                  child: LayoutBuilder(
                      builder: (context, viewport) => InteractiveViewer(
                          minScale: 1,
                          maxScale: 6,
                          child: SizedBox(
                              width: viewport.maxWidth,
                              height: viewport.maxHeight,
                              child: Center(
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: viewport.maxWidth,
                                          maxHeight: viewport.maxHeight),
                                      child: AspectRatio(
                                          aspectRatio: aspectRatio,
                                          child: LayoutBuilder(
                                              builder: (context, size) => imageCanvas(context, size,
                                                  rounded: false, showExpandButton: false))))))))),
              Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                          tooltip: MaterialLocalizations.of(pageContext).closeButtonTooltip,
                          onPressed: () => Navigator.of(pageContext).pop(),
                          icon: const Icon(Icons.close, color: Colors.white))))
            ])))));
  }

  Widget hotspot(BuildContext context, SectionLinkPositionModel position, BoxConstraints size) {
    final x = coordinate(position.x, size.maxWidth, sourceImageWidth);
    final y = coordinate(position.y, size.maxHeight, sourceImageHeight);
    final width = dimension(position.width, size.maxWidth, sourceImageWidth,
        (size.maxWidth * .08).clamp(44.0, size.maxWidth).toDouble());
    final height = dimension(position.height, size.maxHeight, sourceImageHeight,
        (size.maxHeight * .08).clamp(36.0, size.maxHeight).toDouble());
    // A position without dimensions represents a point from the editor, so
    // center its default hit target on x/y. Explicit rectangles remain
    // top-left anchored.
    final left = position.width == null ? x - width / 2 : x;
    final top = position.height == null ? y - height / 2 : y;
    final safeLeft = left.clamp(0.0, (size.maxWidth - width).clamp(0.0, size.maxWidth));
    final safeTop = top.clamp(0.0, (size.maxHeight - height).clamp(0.0, size.maxHeight));
    return Positioned(
        left: safeLeft,
        top: safeTop,
        width: width,
        height: height,
        child: Semantics(
            button: true,
            label: 'Open linked video'.tr(),
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => openPosition(position),
                child: const SizedBox.expand())));
  }

  Widget networkImage(BuildContext context, {required bool rounded}) {
    final child = Image.network(imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final totalBytes = loadingProgress.expectedTotalBytes;
          final progress =
              totalBytes == null ? null : loadingProgress.cumulativeBytesLoaded / totalBytes;
          return Stack(
              fit: StackFit.expand,
              children: [child, Center(child: CircularProgressIndicator(value: progress))]);
        },
        errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Text('Image is not available'.tr())));
    if (!rounded) return child;
    return ClipRRect(borderRadius: Style.border16, child: child);
  }

  Widget imageCanvas(BuildContext context, BoxConstraints size,
      {required bool rounded, required bool showExpandButton}) {
    final positions = sourceImageWidth == null || sourceImageHeight == null
        ? const <SectionLinkPositionModel>[]
        : widget.sectionModel.linkPositions
            .where((position) => position.targetUrl.isNotEmpty)
            .toList(growable: false);
    return Stack(fit: StackFit.expand, children: [
      networkImage(context, rounded: rounded),
      ...positions.map((position) => hotspot(context, position, size)),
      if (showExpandButton)
        Positioned(
            top: 8,
            right: 8,
            child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                    tooltip: 'Expand image'.tr(),
                    onPressed: openExpandedImage,
                    icon: const Icon(Icons.fullscreen, color: Colors.white))))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.sectionModel.image;
    if (image == null || imageUrl.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: widget.maxHeight, maxWidth: MediaQuery.sizeOf(context).width),
                child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: LayoutBuilder(
                        builder: (context, size) =>
                            imageCanvas(context, size, rounded: true, showExpandButton: true))))));
  }
}
