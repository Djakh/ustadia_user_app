import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/characters/player_character.dart';
import '../../domain/content/region_definition.dart';
import '../../domain/content/word_forge_content.dart';
import '../../domain/progression/player_level.dart';
import '../../domain/progression/word_mastery.dart';
import '../../domain/save/word_forge_save.dart';
import '../../domain/services/word_forge_audio.dart';
import '../art/region_backdrop_painter.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/character_portrait.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';
import 'qa_arena_page.dart';
import 'sandbox_map_page.dart';
import 'skills_page.dart';
import 'spellbook_page.dart';

class WordForgeHubPage extends StatelessWidget {
  const WordForgeHubPage({super.key});

  void _openMap(BuildContext context) {
    WordForgeScope.of(context).audio.play(WordForgeSfx.tap);
    WordForgeNavigator.push(context, const SandboxMapPage());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          child: SafeArea(
            child: BlocBuilder<WordForgeCubit, WordForgeState>(
              builder: (context, state) {
                final content = state.content!;
                final save = state.save;
                if (save == null) return const SizedBox.shrink();
                final cubit = context.read<WordForgeCubit>();
                final region = cubit.mapRules.currentRegion(content, save);
                return LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                          _TopBar(muted: save.settings.muted),
                          const SizedBox(height: 18),
                          const _Title(),
                          const SizedBox(height: 22),
                          _PlayerCard(save: save, content: content),
                          const SizedBox(height: 14),
                          _AdventureCard(
                            region: region,
                            save: save,
                            content: content,
                            onTap: () => _openMap(context),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _MenuTile(
                                  glyph: WfGlyphType.book,
                                  color: WfColors.arcane,
                                  title: WfStrings.spellbook,
                                  subtitle: WfStrings.wordsCount(save.discoveredWordCount),
                                  onTap: () {
                                    cubit.logSpellbookOpened();
                                    WordForgeNavigator.push(context, const SpellbookPage());
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MenuTile(
                                  glyph: WfGlyphType.skills,
                                  color: WfColors.resonance,
                                  title: WfStrings.skills,
                                  subtitle: WfStrings.pointsCount(
                                      cubit.dependencies.progression.availableSkillPoints(save)),
                                  highlight: cubit.dependencies.progression.availableSkillPoints(save) > 0,
                                  onTap: () => WordForgeNavigator.push(context, const SkillsPage()),
                                ),
                              ),
                            ],
                          ),
                          if (kDebugMode) ...[
                            const SizedBox(height: 14),
                            _MenuTile(
                              glyph: WfGlyphType.elite,
                              color: WfColors.ember,
                              title: 'QA Arena (debug)',
                              subtitle: 'Any enemy, any spells, nothing saved',
                              onTap: () => WordForgeNavigator.push(context, const QaArenaPage()),
                            ),
                          ],
                          if (kDebugMode && content.errors.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ContentIssuesBanner(content: content),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  final bool muted;

  const _TopBar({required this.muted});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          WfRoundButton(
            glyph: WfGlyphType.back,
            semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          WfRoundButton(
            glyph: muted ? WfGlyphType.soundOff : WfGlyphType.sound,
            semanticsLabel: WfStrings.sound,
            color: muted ? WfColors.textMute : WfColors.gold,
            onTap: () => context.read<WordForgeCubit>().setMuted(!muted),
          ),
        ],
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
              style: WfText.display(36, spacing: 6).copyWith(
                shadows: WfFx.textGlow(WfColors.gold.withValues(alpha: 0.6), 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(WfStrings.tagline, textAlign: TextAlign.center, style: WfText.body(14)),
        ],
      );
}

class _PlayerCard extends StatelessWidget {
  final WordForgeSave save;
  final WordForgeContent content;

  const _PlayerCard({required this.save, required this.content});

  @override
  Widget build(BuildContext context) {
    final level = PlayerLevel.fromXp(save.xp);
    const mastery = MasteryCalculator();
    final masteredCount = save.words.values.where((stats) => mastery.level(stats) >= 5).length;
    return WfPanel(
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CharacterPortrait(
                    character: PlayerCharacterDefinition.byId(save.characterId),
                    tier: PlayerCharacterDefinition.tierForLevel(level.level),
                    size: 92,
                  ),
                  Positioned(right: -4, bottom: 0, child: _LevelBadge(level: level.level)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${WfStrings.level} ${level.level}', style: WfText.title(18)),
                    const SizedBox(height: 8),
                    WfProgressBar(value: level.progress),
                    const SizedBox(height: 6),
                    Text('${level.xpIntoLevel} / ${level.xpForNextLevel} ${WfStrings.xp}',
                        style: WfText.body(12, color: WfColors.textMute)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(glyph: WfGlyphType.book, value: '${save.discoveredWordCount}', label: WfStrings.wordsDiscovered,
                  color: WfColors.arcane),
              _Stat(glyph: WfGlyphType.star, value: '${save.totalStars}', label: WfStrings.starsEarned, color: WfColors.gold),
              _Stat(glyph: WfGlyphType.sparkle, value: '$masteredCount', label: WfStrings.mastered, color: WfColors.resonance),
              _Stat(
                  glyph: WfGlyphType.bolt,
                  value: '${1 + save.spells.length}/${content.combat.allSpecials.length}',
                  label: WfStrings.spellsKnown,
                  color: WfColors.sky),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFF3B3470), WfColors.deep]),
          border: Border.all(color: WfColors.gold, width: 2),
          boxShadow: [...WfFx.shadow(WfColors.gold.withValues(alpha: 0.35), blurRadius: 16)],
        ),
        child: Text('$level', style: WfText.display(16, color: WfColors.gold, spacing: 0)),
      );
}

class _Stat extends StatelessWidget {
  final WfGlyphType glyph;
  final String value;
  final String label;
  final Color color;

  const _Stat({required this.glyph, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WfGlyph(glyph, size: 16, color: color),
                const SizedBox(width: 6),
                Text(value, style: WfText.title(18)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: WfText.body(11.5, color: WfColors.textMute)),
          ],
        ),
      );
}

class _AdventureCard extends StatelessWidget {
  final RegionDefinition region;
  final WordForgeSave save;
  final WordForgeContent content;
  final VoidCallback onTap;

  const _AdventureCard({required this.region, required this.save, required this.content, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rules = context.read<WordForgeCubit>().mapRules;
    final progress = rules.regionProgress(save, region);
    final started = save.nodes.isNotEmpty;
    final index = content.regions.indexOf(region) + 1;
    return WfPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticsLabel: '${WfStrings.sandbox}: ${region.name}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WfColors.gold.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RegionVignette(theme: region.theme),
                    Positioned(
                      left: 16,
                      top: 14,
                      child: WfTag('${WfStrings.sandbox} · $index', color: WfColors.gold),
                    ),
                  ],
                ),
              ),
              Container(
                color: WfColors.panel,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(region.name, style: WfText.title(21)),
                    const SizedBox(height: 4),
                    Text(region.subtitle, style: WfText.body(13.5)),
                    const SizedBox(height: 14),
                    WfProgressBar(value: progress.completed / progress.total, color: WfColors.arcane, height: 7),
                    const SizedBox(height: 6),
                    Text(WfStrings.nodesCleared(progress.completed, progress.total),
                        style: WfText.body(12, color: WfColors.textMute)),
                    const SizedBox(height: 14),
                    WfButton(
                      label: started ? WfStrings.continueJourney : WfStrings.startJourney,
                      glyph: WfGlyphType.forward,
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final WfGlyphType glyph;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  const _MenuTile({
    required this.glyph,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => WfPressable(
        onTap: onTap,
        semanticsLabel: title,
        child: WfPanel(
          glow: highlight ? color : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: WfGlyph(glyph, size: 22, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: WfText.title(15.5)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: WfText.body(12.5)),
            ],
          ),
        ),
      );
}

class _ContentIssuesBanner extends StatelessWidget {
  final WordForgeContent content;

  const _ContentIssuesBanner({required this.content});

  @override
  Widget build(BuildContext context) => WfPanel(
        glow: WfColors.danger,
        child: Text(
          'DEBUG · ${content.errors.length} content errors (skipped):\n'
          '${content.errors.take(6).join('\n')}',
          style: WfText.body(11.5, color: WfColors.danger),
        ),
      );
}
