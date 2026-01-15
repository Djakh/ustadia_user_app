import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/image_upload_bloc/image_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/image_upload_bloc/image_upload_state.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/profile_image_view_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/bottom_sheets/image_picker_bottom_sheet.dart';
import 'package:ustadia_user_app/router.dart';

class ProfileEditableAvatar extends StatelessWidget {
  final double radius;

  const ProfileEditableAvatar({super.key, this.radius = 48});

  /// --- Methods ---

  String fullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://backend.ustadia.findecor.io$url';
  }

  void showImagePickerSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => ImagePickerBottomSheet(sheetContext: sheetContext));
  }

  void openAvatarPreview(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    context.push(profileImageViewRoute, extra: ProfileImageViewParams(imageUrl: imageUrl));
  }

  /// --- Widgets ---

  Widget get avatar => BlocBuilder<UserBloc, UserState>(
      builder: (context, state) => UserAvatar(
            radius: radius,
            imageUrl: fullImageUrl(state.profile?.profilePictureUrl),
          ));

  Positioned editIcon(BuildContext context) => Positioned(
      right: 2,
      bottom: 2,
      child: GestureDetector(
          onTap: () => showImagePickerSheet(context),
          child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))
                  ]),
              child: const Icon(Icons.edit, size: 16, color: Colors.white))));

  Widget get view => BlocBuilder<ImageUploadBloc, ImageUploadState>(
      builder: (context, state) => Stack(alignment: Alignment.center, children: [
            avatar,
            if (state.status.isLoading) const PrimaryLoadingIndicator(isCenter: false),
            editIcon(context)
          ]));

  @override
  Widget build(BuildContext context) => BlocBuilder<UserBloc, UserState>(
      builder: (context, state) => GestureDetector(
          onTap: () => openAvatarPreview(context, fullImageUrl(state.profile?.profilePictureUrl)),
          child: view));
}
