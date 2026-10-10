import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/characters/player_character.dart';
import '../../domain/content/region_definition.dart';
import '../../domain/progression/player_level.dart';
import '../../domain/repositories/word_forge_repositories.dart';
import '../../domain/services/word_forge_audio.dart';
import '../art/region_backdrop_painter.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/character_portrait.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';
import 'character_select_page.dart';
import 'sandbox_map_page.dart';
import 'save_slots_page.dart';
import 'word_forge_hub_page.dart';

/// First Word Forge screen: Continue / Load Game / New Game.
/// Only the controls that make sense are shown (no saves → New Game only).
class WordForgeStartPage extends StatelessWidget {
  const WordForgeStartPage({super.key});

  static Future<void> _play(BuildContext context, {bool openMap = false}) async {
    final cubit = context.read<WordForgeCubit>();
    final save = cubit.state.save;
    if (save == null) return;
    if (save.characterId == null) {
      final character = await WordForgeNavigator.push<String>(context, const CharacterSelectPage());
      if (character == null || !context.mounted) return;
      await cubit.chooseCharacter(character);
    }
    if (!context.mounted) return;
    final hub = WordForgeNavigator.push<void>(context, const WordForgeHubPage(), fade: true);
    if (openMap && context.mounted) {
      // Fresh games go straight to the adventure; the hub waits underneath.
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (context.mounted) WordForgeNavigator.push<void>(context, const SandboxMapPage());
    }
    await hub;
    await cubit.closeSave();
  }

  Future<void> _continue(BuildContext context, SaveSlotState slot) async {
    WordForgeScope.of(context).audio.play(WordForgeSfx.tap);
    if (await context.read<WordForgeCubit>().openSlot(slot.index) && context.mounted) await _play(context);
  }

  Future<void> _load(BuildContext context) async {
    final choice = await WordForgeNavigator.push<SlotChoice>(context, const SaveSlotsPage(mode: SaveSlotsMode.load));
    if (choice == null || !context.mounted) return;
    if (choice.startNew) {
      await _newGame(context, slot: choice.slot);
    } else if (await context.read<WordForgeCubit>().openSlot(choice.slot) && context.mounted) {
      await _play(context);
    }
  }

  Future<void> _newGame(BuildContext context, {int? slot}) async {
    final cubit = context.read<WordForgeCubit>();
    var target = slot;
    if (target == null) {
      final empty = cubit.state.slots.where((state) => state.isEmpty).toList();
      if (!cubit.state.hasAnySave && empty.isNotEmpty) {
        target = empty.first.index;
      } else {
        final choice =
            await WordForgeNavigator.push<SlotChoice>(context, const SaveSlotsPage(mode: SaveSlotsMode.newGame));
        if (choice == null || !context.mounted) return;
        target = choice.slot;
      }
    }
    final character = await WordForgeNavigator.push<String>(context, const CharacterSelectPage());
    if (character == null || !context.mounted) return;
    await cubit.createNewGame(target, character);
    if (!context.mounted) return;
    await showIntroDialog(context);
    if (context.mounted) await _play(context, openMap: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          glow: WfColors.brand,
          child: BlocBuilder<WordForgeCubit, WordForgeState>(
            builder: (context, state) {
              final continueSlot = state.continueSlot;
              final cubit = context.read<WordForgeCubit>();
              return Stack(
                children: [
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 300,
                    child: _HeroArt(),
                  ),
                  SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: WfRoundButton(
                                glyph: WfGlyphType.back,
                                semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                            const SizedBox(height: 120),
                            const _Title(),
                            const SizedBox(height: 26),
                            if (continueSlot != null) ...[
                              _ContinueCard(
                                slot: continueSlot,
                                completion: cubit.completionOf(continueSlot.save!),
                                regionName: cubit.regionOf(continueSlot.save!)?.name ?? '',
                                onTap: () => _continue(context, continueSlot),
                              ),
                              const SizedBox(height: 12),
                              WfButton(
                                label: WfStrings.loadGame,
                                style: WfButtonStyle.secondary,
                                glyph: WfGlyphType.book,
                                onTap: () => _load(context),
                              ),
                              const SizedBox(height: 10),
                              WfButton(
                                label: WfStrings.newGame,
                                style: WfButtonStyle.secondary,
                                glyph: WfGlyphType.sparkle,
                                onTap: () => _newGame(context),
                              ),
                            ] else ...[
                              Text(WfStrings.startHint, textAlign: TextAlign.center, style: WfText.body(15)),
                              const SizedBox(height: 20),
                              WfButton(
                                label: WfStrings.newGame,
                                glyph: WfGlyphType.sparkle,
                                onTap: () => _newGame(context),
                              ),
                              if (state.slots.any((slot) => slot.corrupted)) ...[
                                const SizedBox(height: 10),
                                WfButton(
                                  label: WfStrings.loadGame,
                                  style: WfButtonStyle.secondary,
                                  onTap: () => _load(context),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  // Clipped: the vignette paints slightly past its box, which the fade mask would not cover.
  Widget build(BuildContext context) => ClipRect(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.6, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: const RegionVignette(theme: RegionTheme.road),
        ),
      );
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFE9B5), WfColors.gold, Color(0xFFE09A3E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              WfStrings.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: WfText.display(38, spacing: 6)
                  .copyWith(shadows: WfFx.textGlow(WfColors.gold.withValues(alpha: 0.6), 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(WfStrings.tagline, textAlign: TextAlign.center, style: WfText.body(14)),
        ],
      );
}

class _ContinueCard extends StatelessWidget {
  final SaveSlotState slot;
  final double completion;
  final String regionName;
  final VoidCallback onTap;

  const _ContinueCard({required this.slot, required this.completion, required this.regionName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final save = slot.save!;
    final level = PlayerLevel.fromXp(save.xp).level;
    final character = PlayerCharacterDefinition.byId(save.characterId);
    return WfPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticsLabel: WfStrings.continueLabel,
      child: WfPanel(
        glow: WfColors.brand,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                CharacterPortrait(
                  character: character,
                  tier: PlayerCharacterDefinition.tierForLevel(level),
                  size: 96,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(WfStrings.characterName(character.name), style: WfText.title(17)),
                      const SizedBox(height: 3),
                      Text(WfStrings.levelValue(level), style: WfText.title(14, color: WfColors.brand)),
                      const SizedBox(height: 3),
                      Text(regionName, maxLines: 1, overflow: TextOverflow.ellipsis, style: WfText.body(13)),
                      const SizedBox(height: 8),
                      WfProgressBar(value: completion, color: WfColors.brand, height: 6),
                      const SizedBox(height: 4),
                      Text(WfStrings.percentComplete((completion * 100).round()),
                          style: WfText.body(11.5, color: WfColors.textMute)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            WfButton(label: WfStrings.continueLabel, glyph: WfGlyphType.forward, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

/// Short, skippable introduction shown once after a new game is created.
Future<void> showIntroDialog(BuildContext context) => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: WfStrings.introTitle,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Material(
            type: MaterialType.transparency,
            child: WfPanel(
              glow: WfColors.brand,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WfGlyph(WfGlyphType.book, size: 50, color: WfColors.brand),
                  const SizedBox(height: 14),
                  Text(WfStrings.introTitle, textAlign: TextAlign.center, style: WfText.display(22, spacing: 1)),
                  const SizedBox(height: 10),
                  Text(WfStrings.introBody, textAlign: TextAlign.center, style: WfText.body(15)),
                  const SizedBox(height: 22),
                  WfButton(label: WfStrings.beginTraining, onTap: () => Navigator.of(dialogContext).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
