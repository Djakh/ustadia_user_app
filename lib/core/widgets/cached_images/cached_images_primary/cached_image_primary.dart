import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class CachedImagePrimary extends StatelessWidget {
  final double height;
  final double width;
  final String? imageUrl;
  final double? fallBackIconSize;
  final BoxFit? fit;
  const CachedImagePrimary(
      {super.key,
      required this.height,
      required this.width,
      this.imageUrl,
      this.fallBackIconSize,
      this.fit});

  Widget _fallbackIcon(BuildContext context) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(borderRadius: Style.border24, color: context.cs.surface),
      child: Center(
        child: Icon(Icons.image,
            size: fallBackIconSize, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ));

  Widget _loading(BuildContext context) =>
      const Center(child: CircularProgressIndicator.adaptive(strokeWidth: 2));

  CachedNetworkImage cachedImage(BuildContext context) => CachedNetworkImage(
      height: height,
      width: width,
      imageUrl: imageUrl!,
      fit: fit,
      placeholder: (_, __) => _loading(context),
      errorWidget: (_, __, ___) => _fallbackIcon(context));

  @override
  Widget build(BuildContext context) =>
      imageUrl == null || imageUrl!.isEmpty ? _fallbackIcon(context) : cachedImage(context);
}
