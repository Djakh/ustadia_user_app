import 'package:file_picker/file_picker.dart';
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

  Future<void> pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null || path.isEmpty) return;
      if (!sheetContext.mounted) return;
      sheetContext.read<FileUploadBloc>().add(ImageUploadRequested(filePath: path));
    } on MissingPluginException {
      ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(
          content: Text('File picker is not available on this device. Try a real device.')));
    }
    Navigator.of(sheetContext).pop();
  }

  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (file == null) return;
    if (!sheetContext.mounted) return;

    sheetContext.read<FileUploadBloc>().add(ImageUploadRequested(filePath: file.path));
    Navigator.of(sheetContext).pop();
  }

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
        Button.primary(onTap: pickFromCamera, text: 'Take photo'),
        const SizedBox(height: 12),
        Button.border(
          onTap: pickFromGallery,
          text: 'Choose from gallery',
          borderWidth: 1,
          borderColor: AppColors.gray400,
        ),
        const SizedBox(height: 20)
      ]));

  @override
  Widget build(BuildContext sheetContext) => view;
}
