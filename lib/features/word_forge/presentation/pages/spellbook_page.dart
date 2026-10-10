import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/content/word_entry.dart';
import '../../domain/content/word_forge_content.dart';
import '../../domain/language/challenge_type.dart';
import '../../domain/language/text_normalizer.dart';
import '../../domain/progression/word_mastery.dart';
import '../../domain/save/word_forge_save.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';

enum SpellbookFilter { all, discovered, needsPractice, mastered }

class SpellbookPage extends StatefulWidget {
  const SpellbookPage({super.key});

  @override
  State<SpellbookPage> createState() => _SpellbookPageState();
}

class _SpellbookPageState extends State<SpellbookPage> {
  static const _mastery = MasteryCalculator();
  final _search = TextEditingController();
  SpellbookFilter _filter = SpellbookFilter.all;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WordEntry> _visible(WordForgeContent content, WordForgeSave save) {
    final query = TextNormalizer.normalize(_query);
    return content.wordList.where((word) {
      final level = _mastery.level(save.words[word.id]);
      final discovered = level > 0;
      final matchesFilter = switch (_filter) {
        SpellbookFilter.all => true,
        SpellbookFilter.discovered => discovered,
        SpellbookFilter.needsPractice => discovered && (level <= 2 || (save.words[word.id]?.lastWasWrong ?? false)),
        SpellbookFilter.mastered => level >= MasteryCalculator.maxLevel,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      // Undiscovered words are searchable only by exact text, so the book
      // does not spoil the collection.
      return discovered ? word.normalized.contains(query) || TextNormalizer.normalize(word.definition).contains(query)
          : word.normalized == query;
    }).toList()
      ..sort((a, b) {
        final aFound = save.words.containsKey(a.id) ? 0 : 1;
        final bFound = save.words.containsKey(b.id) ? 0 : 1;
        return aFound != bFound ? aFound.compareTo(bFound) : 0;
      });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          glow: WfColors.arcane,
          animate: false,
          child: SafeArea(
            bottom: false,
            child: BlocBuilder<WordForgeCubit, WordForgeState>(
              builder: (context, state) {
                final content = state.content!;
                final save = state.save!;
                final words = _visible(content, save);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: Row(
                        children: [
                          WfRoundButton(
                            glyph: WfGlyphType.back,
                            semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(WfStrings.spellbook, style: WfText.title(22)),
                                Text(WfStrings.discoveredOf(save.discoveredWordCount, content.words.length),
                                    style: WfText.body(12.5, color: WfColors.arcane)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: _SearchField(controller: _search, onChanged: (value) => setState(() => _query = value)),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final filter in SpellbookFilter.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: switch (filter) {
                                  SpellbookFilter.all => WfStrings.all,
                                  SpellbookFilter.discovered => WfStrings.discovered,
                                  SpellbookFilter.needsPractice => WfStrings.needsPractice,
                                  SpellbookFilter.mastered => WfStrings.mastered,
                                },
                                selected: filter == _filter,
                                onTap: () => setState(() => _filter = filter),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: words.isEmpty
                          ? Center(child: Text(WfStrings.noWordsFound, style: WfText.body(14)))
                          : LayoutBuilder(
                              builder: (context, constraints) => GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth > 700 ? 4 : (constraints.maxWidth > 460 ? 3 : 2),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  mainAxisExtent: 128,
                                ),
                                itemCount: words.length,
                                itemBuilder: (context, index) {
                                  final word = words[index];
                                  return SpellCard(
                                    word: word,
                                    stats: save.words[word.id],
                                    onTap: () => showSpellDetails(context, word: word, stats: save.words[word.id]),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: WfText.title(15, weight: FontWeight.w500),
        cursorColor: WfColors.arcane,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: WfStrings.search,
          hintStyle: WfText.body(15, color: WfColors.textMute),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: WfGlyph(WfGlyphType.reveal, size: 18, color: WfColors.textMute),
          ),
          filled: true,
          fillColor: WfColors.panel,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WfColors.stroke)),
          enabledBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WfColors.stroke)),
          focusedBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WfColors.arcane)),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => WfPressable(
        onTap: onTap,
        semanticsLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? WfColors.arcane.withValues(alpha: 0.2) : WfColors.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? WfColors.arcane : WfColors.stroke),
          ),
          child: Text(label, style: WfText.title(13, color: selected ? WfColors.arcane : WfColors.textDim, weight: FontWeight.w600)),
        ),
      );
}

class MasteryStars extends StatelessWidget {
  final int level;
  final double size;

  const MasteryStars({super.key, required this.level, this.size = 13});

  @override
  Widget build(BuildContext context) => WfStarRow(stars: level, max: MasteryCalculator.maxLevel, size: size);
}

class SpellCard extends StatelessWidget {
  final WordEntry word;
  final WordStats? stats;
  final VoidCallback onTap;

  const SpellCard({super.key, required this.word, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final level = const MasteryCalculator().level(stats);
    final discovered = level > 0;
    final accent = discovered ? Color.lerp(WfColors.arcane, WfColors.gold, level / 5)! : WfColors.textMute;
    return WfPressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticsLabel: discovered ? word.text : WfStrings.masteryLabel(0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: discovered
                ? [Color.lerp(WfColors.panelHigh, accent, 0.12)!, WfColors.panel]
                : const [Color(0xFF171A33), Color(0xFF111429)],
          ),
          border: Border.all(color: accent.withValues(alpha: discovered ? 0.45 : 0.15)),
        ),
        child: discovered
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(word.text.toUpperCase(),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: WfText.rune(16)),
                      ),
                      Text(word.cefr.label, style: WfText.label(10, color: accent)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(word.partOfSpeech, style: WfText.body(11, color: WfColors.textMute)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(word.definition,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: WfText.body(12, color: WfColors.textDim)),
                  ),
                  MasteryStars(level: level, size: 12),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WfGlyph(WfGlyphType.mystery, size: 30, color: WfColors.textMute.withValues(alpha: 0.6)),
                  const SizedBox(height: 10),
                  Text('? ? ?', style: WfText.rune(15, color: WfColors.textMute)),
                  const SizedBox(height: 4),
                  Text(word.cefr.label, style: WfText.label(10)),
                ],
              ),
      ),
    );
  }
}

Future<void> showSpellDetails(BuildContext context, {required WordEntry word, required WordStats? stats}) =>
    showWfSheet<void>(context, builder: (_) => _SpellDetails(word: word, stats: stats));

class _SpellDetails extends StatelessWidget {
  final WordEntry word;
  final WordStats? stats;

  const _SpellDetails({required this.word, required this.stats});

  @override
  Widget build(BuildContext context) {
    final level = const MasteryCalculator().level(stats);
    if (level == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WfGlyph(WfGlyphType.mystery, size: 44, color: WfColors.textMute),
            const SizedBox(height: 14),
            Text(WfStrings.undiscoveredHint, textAlign: TextAlign.center, style: WfText.body(15)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text(word.text.toUpperCase(), style: WfText.rune(30, color: WfColors.gold))),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(word.partOfSpeech, style: WfText.body(13, color: WfColors.textMute)),
              ),
              const Spacer(),
              WfTag(word.cefr.label, color: WfColors.arcane),
            ],
          ),
          const SizedBox(height: 18),
          _Section(title: WfStrings.meaning, child: Text(word.definition, style: WfText.body(16, color: WfColors.text))),
          if (word.antonyms.isNotEmpty)
            _Section(title: WfStrings.opposite, child: _WordChips(words: word.antonyms, color: WfColors.ember)),
          if (word.synonyms.isNotEmpty)
            _Section(title: WfStrings.similar, child: _WordChips(words: word.synonyms, color: WfColors.resonance)),
          if (word.examples.isNotEmpty)
            _Section(
              title: WfStrings.example,
              child: Text('“${word.examples.first}”',
                  style: WfText.body(15, color: WfColors.textDim).copyWith(fontStyle: FontStyle.italic)),
            ),
          _Section(
            title: WfStrings.mastery,
            child: Row(
              children: [
                MasteryStars(level: level, size: 20),
                const SizedBox(width: 10),
                Flexible(child: Text(WfStrings.masteryLabel(level), style: WfText.title(14, color: WfColors.gold))),
              ],
            ),
          ),
          Row(
            children: [
              _Number(label: WfStrings.seen, value: '${stats?.seen ?? 0}'),
              _Number(label: WfStrings.correct, value: '${stats?.correct ?? 0}'),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    for (final type in stats?.correctTypes ?? const <ChallengeType>{})
                      WfTag(switch (type) {
                        ChallengeType.antonym => WfStrings.opposite,
                        ChallengeType.synonym => WfStrings.similar,
                        ChallengeType.missingRune => WfStrings.sentenceSkill,
                        ChallengeType.incantation => WfStrings.sentenceSkill,
                        ChallengeType.wordMatch => WfStrings.opposite,
                      }, color: WfColors.textDim),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: WfText.label(11)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );
}

class _WordChips extends StatelessWidget {
  final List<String> words;
  final Color color;

  const _WordChips({required this.words, required this.color});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final word in words)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(word.toUpperCase(), style: WfText.rune(13.5, color: WfColors.text)),
            ),
        ],
      );
}

class _Number extends StatelessWidget {
  final String label;
  final String value;

  const _Number({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: WfText.label(10.5)),
            const SizedBox(height: 3),
            Text(value, style: WfText.title(20)),
          ],
        ),
      );
}
