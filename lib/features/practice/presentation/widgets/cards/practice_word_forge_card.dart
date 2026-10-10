import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/word_forge/word_forge.dart';
import 'package:ustadia_user_app/router.dart';

/// Word Forge entry in Practice. Uses the same tile layout as the other
/// activities (PrimaryBox, 56 px artwork, title + description) so it belongs
/// to the Practice list, with a light fantasy accent: the Word Forge emblem,
/// a soft rune glow and a "Play" pill in the brand colour.
class PracticeWordForgeCard extends StatelessWidget {
  const PracticeWordForgeCard({super.key});

  @override
  Widget build(BuildContext context) => PrimaryBox(
        onTap: () => context.push(wordForgeRoute),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -6,
              top: -10,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.14), AppColors.primary.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                const WordForgeEmblem(size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text('Word Forge'.tr(), style: Style.body2w5(context))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: Style.border6,
                            ),
                            child: Text('New'.tr(),
                                style: Style.small3w4(context).copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('A fantasy adventure where English is your magic'.tr(),
                          style: Style.small3w4(context, color: TextColorRole.greyColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: Style.border32),
                  child: Text('Play'.tr(),
                      style: Style.small3w4(context).copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      );
}
