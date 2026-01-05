import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;

  const UserAvatar({super.key, this.radius = 40, this.imageUrl});

  double get _size => radius * 2;

  Widget _fallbackIcon(BuildContext context) => Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceContainerHighest),
      child:
          Icon(Icons.person, size: radius, color: Theme.of(context).colorScheme.onSurfaceVariant));

  Widget _loading(BuildContext context) => Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceContainerHighest),
      child: SizedBox(
          width: radius * 0.6,
          height: radius * 0.6,
          child: const CircularProgressIndicator(strokeWidth: 2)));

  CachedNetworkImage cachedImage(BuildContext context) => CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover))),
      placeholder: (_, __) => _loading(context),
      errorWidget: (_, __, ___) => _fallbackIcon(context));

  @override
  Widget build(BuildContext context) =>
      imageUrl == null || imageUrl!.isEmpty ? _fallbackIcon(context) : cachedImage(context);
}
