import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/practice/data/models/activity_model.dart';

class PracticeItemTileCard extends StatelessWidget {
  final ActivityModel activityModel;
  const PracticeItemTileCard({super.key, required this.activityModel});

  /// --- Methods ---
  void goToPracticeActivityPage(BuildContext context) => context.push(activityModel.route);

  /// --- Widgets ---

  Widget get image => ClipRRect(
      borderRadius: Style.border12,
      child: Image.asset(activityModel.image, height: 56, width: 56, fit: BoxFit.cover));

  Widget textInfoBody(BuildContext context) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(activityModel.title, style: Style.body2w5(context)),
        const SizedBox(height: 4),
        Text(activityModel.description,
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]));

  Widget view(BuildContext context) => Row(children: [
        image,
        const SizedBox(width: 12),
        textInfoBody(context),
      ]);

  @override
  Widget build(BuildContext context) =>
      PrimaryBox(onTap: () => goToPracticeActivityPage(context), child: view(context));
}
