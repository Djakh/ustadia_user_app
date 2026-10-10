import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/characters/player_character.dart';
import '../../domain/progression/player_level.dart';
import '../../domain/repositories/word_forge_repositories.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/character_portrait.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';

enum SaveSlotsMode { load, newGame }

class SlotChoice {
  final int slot;
  final bool startNew;

  const SlotChoice(this.slot, {required this.startNew});
}

/// Three save slots. Load mode loads saves (empty slots offer New Game);
/// New Game mode picks a slot and confirms before replacing progress.
class SaveSlotsPage extends StatelessWidget {
  final SaveSlotsMode mode;

  const SaveSlotsPage({super.key, required this.mode});

  Future<void> _choose(BuildContext context, SaveSlotState slot, {required bool startNew}) async {
    if (startNew && !slot.isEmpty) {
      final replace = await showWfConfirm(
        context,
        title: WfStrings.overwriteTitle,
        message: WfStrings.overwriteMessage,
        confirmLabel: WfStrings.replace,
        cancelLabel: WfStrings.cancel,
        glyph: WfGlyphType.mystery,
      );
      if (!replace || !context.mounted) return;
    }
    Navigator.of(context).pop(SlotChoice(slot.index, startNew: startNew));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          glow: WfColors.brand,
          animate: false,
          child: SafeArea(
            child: BlocBuilder<WordForgeCubit, WordForgeState>(
              builder: (context, state) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                    children: [
                      Row(
                        children: [
                          WfRoundButton(
                            glyph: WfGlyphType.back,
                            semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(mode == SaveSlotsMode.load ? WfStrings.loadGame : WfStrings.chooseSlot,
                                style: WfText.title(22)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      for (final slot in state.slots)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SaveSlotCard(
                            slot: slot,
                            mode: mode,
                            onLoad: () => _choose(context, slot, startNew: false),
                            onNewGame: () => _choose(context, slot, startNew: true),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class SaveSlotCard extends StatelessWidget {
  final SaveSlotState slot;
  final SaveSlotsMode mode;
  final VoidCallback onLoad;
  final VoidCallback onNewGame;

  const SaveSlotCard({
    super.key,
    required this.slot,
    required this.mode,
    required this.onLoad,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WordForgeCubit>();
    final save = slot.save;
    final Widget body;
    final Widget action;
    if (save != null) {
      final level = PlayerLevel.fromXp(save.xp).level;
      final character = PlayerCharacterDefinition.byId(save.characterId);
      final completion = cubit.completionOf(save);
      body = Row(
        children: [
          CharacterPortrait(character: character, tier: PlayerCharacterDefinition.tierForLevel(level), size: 78),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(WfStrings.characterName(character.name), style: WfText.title(15.5)),
                const SizedBox(height: 2),
                Text('${WfStrings.levelValue(level)} · ${cubit.regionOf(save)?.name ?? ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: WfText.body(12.5)),
                const SizedBox(height: 8),
                WfProgressBar(value: completion, color: WfColors.brand, height: 6),
                const SizedBox(height: 3),
                Text(WfStrings.percentComplete((completion * 100).round()),
                    style: WfText.body(11.5, color: WfColors.textMute)),
              ],
            ),
          ),
        ],
      );
      action = mode == SaveSlotsMode.load
          ? WfButton(label: WfStrings.load, onTap: onLoad, expand: false)
          : WfButton(label: WfStrings.newGame, style: WfButtonStyle.secondary, onTap: onNewGame, expand: false);
    } else if (slot.corrupted) {
      body = Row(
        children: [
          const WfGlyph(WfGlyphType.mystery, size: 36, color: WfColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(WfStrings.corruptedSlot, style: WfText.title(14.5, color: WfColors.danger)),
                const SizedBox(height: 3),
                Text(WfStrings.corruptedHint, style: WfText.body(12.5)),
              ],
            ),
          ),
        ],
      );
      action = WfButton(label: WfStrings.newGame, style: WfButtonStyle.secondary, onTap: onNewGame, expand: false);
    } else {
      body = Row(
        children: [
          Container(
            width: 62,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WfColors.stroke),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: const WfGlyph(WfGlyphType.sparkle, size: 24, color: WfColors.textMute),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(WfStrings.emptySlot, style: WfText.title(15, color: WfColors.textDim))),
        ],
      );
      action = WfButton(label: WfStrings.newGame, onTap: onNewGame, expand: false);
    }

    return WfPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 14),
      glow: save != null && mode == SaveSlotsMode.load ? WfColors.brand : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(WfStrings.slotLabel(slot.index).toUpperCase(), style: WfText.label(11, color: WfColors.brand)),
          const SizedBox(height: 8),
          body,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    );
  }
}
