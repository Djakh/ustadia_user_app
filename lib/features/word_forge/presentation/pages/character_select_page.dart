import 'package:flutter/material.dart';

import '../../domain/characters/player_character.dart';
import '../../domain/services/word_forge_audio.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/character_portrait.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';

/// "Choose your apprentice": Male or Female, cosmetic only. Pops with the
/// chosen character id.
class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  String? _selected;

  void _select(PlayerCharacterDefinition character) {
    WordForgeScope.of(context).audio.play(WordForgeSfx.tap);
    setState(() => _selected = character.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          glow: WfColors.brand,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: WfRoundButton(
                          glyph: WfGlyphType.back,
                          semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(WfStrings.chooseApprentice, textAlign: TextAlign.center, style: WfText.display(24, spacing: 1)),
                      const SizedBox(height: 8),
                      Text(WfStrings.chooseApprenticeHint, textAlign: TextAlign.center, style: WfText.body(14)),
                      const Spacer(),
                      Row(
                        children: [
                          for (final character in PlayerCharacterDefinition.all) ...[
                            if (character != PlayerCharacterDefinition.all.first) const SizedBox(width: 12),
                            Expanded(
                              child: _CharacterCard(
                                character: character,
                                selected: _selected == character.id,
                                onTap: () => _select(character),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      WfButton(
                        label: WfStrings.confirm,
                        glyph: WfGlyphType.check,
                        onTap: _selected == null ? null : () => Navigator.of(context).pop(_selected),
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

class _CharacterCard extends StatelessWidget {
  final PlayerCharacterDefinition character;
  final bool selected;
  final VoidCallback onTap;

  const _CharacterCard({required this.character, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => WfPressable(
        onTap: onTap,
        pressedScale: 0.97,
        semanticsLabel: WfStrings.characterName(character.name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WfShape.card),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? [WfColors.brand.withValues(alpha: 0.28), WfColors.panel]
                  : [WfColors.panelHigh, WfColors.panel],
            ),
            border: Border.all(color: selected ? WfColors.brand : WfColors.stroke, width: selected ? 2 : 1),
            boxShadow: selected ? [...WfFx.shadow(WfColors.brand.withValues(alpha: 0.35), blurRadius: 24)] : null,
          ),
          child: Column(
            children: [
              CharacterPortrait(character: character, casting: selected, size: 190),
              const SizedBox(height: 12),
              Text(WfStrings.characterName(character.name),
                  textAlign: TextAlign.center, style: WfText.title(15, color: selected ? WfColors.brand : WfColors.text)),
            ],
          ),
        ),
      );
}
