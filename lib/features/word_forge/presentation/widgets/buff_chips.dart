import 'package:flutter/material.dart';

import '../../domain/progression/buffs.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import 'wf_glyph.dart';

Color buffColor(BuffType buff) => switch (buff) {
      BuffType.hint => WfColors.gold,
      BuffType.reveal => WfColors.arcane,
      BuffType.timeFreeze => const Color(0xFF9FE8FF),
      BuffType.extraTime => const Color(0xFF7FD4FF),
      BuffType.secondChance => WfColors.life,
      BuffType.runeSense => WfColors.resonance,
      BuffType.shield => const Color(0xFFFFB86B),
    };

/// Reward / inventory chips: icon, name and quantity.
class BuffChips extends StatelessWidget {
  final Map<BuffType, int> buffs;
  final bool showPlus;

  const BuffChips({super.key, required this.buffs, this.showPlus = false});

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in buffs.entries)
            if (entry.value > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: buffColor(entry.key).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: buffColor(entry.key).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WfGlyph(WfGlyphType.forBuff(entry.key), size: 16, color: buffColor(entry.key)),
                    const SizedBox(width: 6),
                    Text(
                      '${showPlus ? '+' : ''}${entry.value} ${WfStrings.buffName(entry.key)}',
                      style: WfText.title(13, color: WfColors.text, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
        ],
      );
}

/// Compact inventory line shown on the map header.
class BuffInventoryStrip extends StatelessWidget {
  final Map<BuffType, int> buffs;

  const BuffInventoryStrip({super.key, required this.buffs});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final buff in BuffType.values)
              Tooltip(
                message: '${WfStrings.buffName(buff)}: ${WfStrings.buffDescription(buff)}',
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WfGlyph(WfGlyphType.forBuff(buff),
                          size: 14,
                          color: (buffs[buff] ?? 0) > 0 ? buffColor(buff) : WfColors.textMute.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text('${buffs[buff] ?? 0}',
                          style: WfText.title(12.5,
                              color: (buffs[buff] ?? 0) > 0 ? WfColors.text : WfColors.textMute)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
