import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

/// Collects a report reason without implying that a report was submitted.
Future<String?> showReportReasonDialog(
  BuildContext context, {
  required String title,
  required List<String> reasons,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Text(title.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((reason) => ListTile(
                    title: Text(reason.tr()),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.of(context).pop(reason),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'.tr(), style: Style.bodyw5(context)),
        ),
      ],
    ),
  );
}
