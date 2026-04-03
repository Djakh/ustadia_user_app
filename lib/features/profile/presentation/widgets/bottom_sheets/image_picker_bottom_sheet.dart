import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_event.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final BuildContext sheetContext;
  const ImagePickerBottomSheet({super.key, required this.sheetContext});

  /// --- Methods ----

  void showMessage(String text) {
    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 90);
      if (file == null || file.path.isEmpty) return;
      if (!sheetContext.mounted) return;
      sheetContext.read<FileUploadBloc>().add(ImageUploadRequested(filePath: file.path));
      Navigator.of(sheetContext).pop();
    } on MissingPluginException {
      showMessage('Image picker is not available on this device. Try a real device.'.tr());
    } on PlatformException catch (error) {
      showMessage(error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'Unable to access photos or camera. Please check permissions and try again.'.tr());
    }
  }

  Future<void> pickFromGallery() => pickImage(ImageSource.gallery);

  Future<void> pickFromCamera() => pickImage(ImageSource.camera);

  /// --- Widgets ----

  Container get view => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: sheetContext.cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: sheetContext.cs.onTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Button.primary(onTap: pickFromCamera, text: 'Take photo'.tr()),
        const SizedBox(height: 12),
        Button.border(
          onTap: pickFromGallery,
          text: 'Choose from gallery'.tr(),
          borderWidth: 1,
          borderColor: AppColors.gray400,
        ),
        const SizedBox(height: 20)
      ]));

  @override
  Widget build(BuildContext sheetContext) => view;
}
