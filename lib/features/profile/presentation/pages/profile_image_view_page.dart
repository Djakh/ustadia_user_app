import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/cached_images_primary/cached_image_primary.dart';

class ProfileImageViewParams {
  final String? imageUrl;
  final String? filePath;

  const ProfileImageViewParams({this.imageUrl, this.filePath});
}

class ProfileImageViewPage extends StatelessWidget {
  final ProfileImageViewParams params;

  const ProfileImageViewPage({super.key, required this.params});

  Widget get cachedNetworkImage =>
      CachedImagePrimary(imageUrl: params.imageUrl,  width: double.infinity);

  Widget imageView() {
    if (params.filePath != null && params.filePath!.isNotEmpty) {
      return Image.file(File(params.filePath!), fit: BoxFit.contain);
    }
    if (params.imageUrl != null && params.imageUrl!.isNotEmpty) {
      return cachedNetworkImage;
    }
    return const Icon(Icons.person, color: Colors.white, size: 120);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
          child: Stack(children: [
        Center(child: InteractiveViewer(minScale: 1, maxScale: 3, child: imageView())),
        Align(
            alignment: Alignment.topLeft,
            child: IconButton(
                onPressed: () => context.pop(), icon: const Icon(Icons.close, color: Colors.white)))
      ])));
}
