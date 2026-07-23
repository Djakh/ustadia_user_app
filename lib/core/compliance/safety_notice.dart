import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

enum SafetyNoticeType { ieltsWritingSubmission, publicAvatarUpload }

/// Presents the required privacy reminder immediately before a user-upload flow.
/// A process-wide guard prevents rapid taps from opening duplicate dialogs.
class SafetyNoticeCoordinator {
  SafetyNoticeCoordinator._();

  static bool _isShowing = false;

  static Future<bool> confirm(BuildContext context, SafetyNoticeType type) async {
    if (!context.mounted || _isShowing) return false;
    _isShowing = true;
    try {
      return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => SafetyNoticeDialog(type: type)) ??
          false;
    } finally {
      _isShowing = false;
    }
  }
}

class SafetyNoticeDialog extends StatelessWidget {
  final SafetyNoticeType type;

  const SafetyNoticeDialog({super.key, required this.type});

  String get title => switch (type) {
        SafetyNoticeType.ieltsWritingSubmission => 'Submit your IELTS Writing safely'.tr(),
        SafetyNoticeType.publicAvatarUpload => 'Choose a safe profile image'.tr(),
      };

  String get message => switch (type) {
        SafetyNoticeType.ieltsWritingSubmission =>
          'Upload only the document or image needed for your IELTS Writing assessment. Do not include unnecessary personal information such as your home address, phone number, passwords, identification documents, financial information, or private photos.\n\nYour submission will be reviewed privately by authorized teachers or administrators. It will not be published or shown to other students.'
              .tr(),
        SafetyNoticeType.publicAvatarUpload =>
          'Your profile image may be visible to other users. Do not upload an image containing identification documents, your address, phone number, school details, financial information, private messages, or other sensitive personal information.\n\nUse an appropriate image that you are comfortable sharing with other users.'
              .tr(),
      };

  @override
  Widget build(BuildContext context) => PopScope<void>(
      canPop: false,
      child: AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .58),
              child: SingleChildScrollView(child: Text(message, style: Style.bodyw4(context)))),
          actions: [
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Button.border(
                  onTap: () => Navigator.of(context).pop(false),
                  text: 'Cancel'.tr(),
                  borderColor: AppColors.gray200,
                  color: AppColors.white,
                  textColor: AppColors.gray700),
              const SizedBox(height: 8),
              Button.primary(
                  onTap: () => Navigator.of(context).pop(true),
                  text: 'I understand and continue'.tr())
            ])
          ]));
}
