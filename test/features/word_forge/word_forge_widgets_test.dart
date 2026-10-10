import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_models.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/word_forge_content.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/answer_validator.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/word_mastery.dart';
import 'package:ustadia_user_app/features/word_forge/domain/save/word_forge_save.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/cubit/battle_controller.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/cubit/word_forge_cubit.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/pages/battle_page.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/pages/character_select_page.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/pages/sandbox_map_page.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/pages/skills_page.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/pages/spellbook_page.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/widgets/challenge_panels.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/widgets/spell_chooser.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/widgets/wf_components.dart';
import 'package:ustadia_user_app/features/word_forge/presentation/word_forge_scope.dart';
import 'package:ustadia_user_app/features/word_forge/word_forge.dart';

import 'helpers.dart';

class _MemoryContent implements WordForgeContentRepository {
  @override
  Future<WordForgeContent> load() async => loadShippedContent();
}

/// In-memory three-slot repository.
class _MemorySaves implements WordForgeSaveRepository {
  final Map<int, WordForgeSave> slots;
  final Set<int> corrupted;
  int? last;
  int writes = 0;

  _MemorySaves({Map<int, WordForgeSave>? slots, this.corrupted = const {}, this.last}) : slots = slots ?? {};

  @override
  Future<List<SaveSlotState>> listSlots(String profileId) async => [
        for (final index in WordForgeSaveRepository.slots)
          SaveSlotState(index: index, save: slots[index], corrupted: corrupted.contains(index) && slots[index] == null),
      ];

  @override
  Future<WordForgeSave?> loadSlot(String profileId, int slot) async => slots[slot];

  @override
  Future<void> save(WordForgeSave save) async {
    writes++;
    slots[save.slotIndex] = save;
    last = save.slotIndex;
  }

  @override
  Future<void> deleteSlot(String profileId, int slot) async => slots.remove(slot);

  @override
  Future<int?> lastPlayedSlot(String profileId) async => last;
}

WordForgeDependencies _deps(_MemorySaves saves) => WordForgeDependencies(
      contentRepository: _MemoryContent(),
      saveRepository: saves,
      audioFactory: SilentWordForgeAudio.new,
    );

WordForgeSave _save({
  int slot = 1,
  String character = 'male_apprentice',
  int xp = 0,
  Map<String, WordStats> words = const {},
  Map<String, NodeProgress> nodes = const {},
}) =>
    WordForgeSave.fresh('tester', slotIndex: slot, characterId: character, nowMs: 1).copyWith(xp: xp, words: words, nodes: nodes);

Future<WordForgeCubit> _playing(_MemorySaves saves, {int slot = 1}) async {
  final cubit = WordForgeCubit(dependencies: _deps(saves), playerId: 'tester');
  await cubit.load();
  await cubit.openSlot(slot);
  return cubit;
}

Widget _host(WordForgeCubit cubit, Widget child) => MaterialApp(
      home: WordForgeScope(
        dependencies: cubit.dependencies,
        audio: SilentWordForgeAudio(),
        child: BlocProvider.value(value: cubit, child: child),
      ),
    );

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  spellChooserTests();
  testWidgets('with no saves the start screen offers only New Game', (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(home: WordForgeEntryPage(dependencies: _deps(_MemorySaves()), playerId: 'p1')));
    await _settle(tester);
    expect(find.text('WORD FORGE'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('CONTINUE'), findsNothing);
    expect(find.text('LOAD GAME'), findsNothing);
  });

  testWidgets('New Game: choose an apprentice, see the intro, and the save is created in a free slot', (tester) async {
    _phone(tester);
    final saves = _MemorySaves();
    await tester.pumpWidget(MaterialApp(home: WordForgeEntryPage(dependencies: _deps(saves), playerId: 'tester')));
    await _settle(tester);
    await tester.tap(find.text('NEW GAME'));
    await _settle(tester, 8);
    expect(find.byType(CharacterSelectPage), findsOneWidget);
    expect(find.text('Male Apprentice'), findsOneWidget);
    expect(find.text('Female Apprentice'), findsOneWidget);
    await tester.tap(find.text('Female Apprentice'));
    await _settle(tester, 3);
    await tester.tap(find.text('CONFIRM'));
    await _settle(tester, 8);
    expect(find.text('Your training begins'), findsOneWidget);
    expect(saves.slots[1]!.characterId, 'female_apprentice');
    expect(saves.slots[1]!.saveId, isNotEmpty);
    await tester.tap(find.text('BEGIN TRAINING'));
    await _settle(tester, 15);
    expect(find.byType(SandboxMapPage), findsOneWidget);
  });

  testWidgets('with saves the start screen shows Continue with a summary, plus Load and New Game', (tester) async {
    _phone(tester);
    final saves = _MemorySaves(slots: {2: _save(slot: 2, xp: 300), 3: _save(slot: 3)}, last: 2);
    await tester.pumpWidget(MaterialApp(home: WordForgeEntryPage(dependencies: _deps(saves), playerId: 'tester')));
    await _settle(tester);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('LOAD GAME'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget, reason: 'the most recently played slot is shown');
  });

  testWidgets('Load Game lists three slots and New Game asks before replacing progress', (tester) async {
    _phone(tester);
    final saves = _MemorySaves(slots: {1: _save(slot: 1, xp: 300)}, corrupted: {3}, last: 1);
    await tester.pumpWidget(MaterialApp(home: WordForgeEntryPage(dependencies: _deps(saves), playerId: 'tester')));
    await _settle(tester);
    await tester.tap(find.text('LOAD GAME'));
    await _settle(tester, 8);
    expect(find.text('SAVE SLOT 1'), findsOneWidget);
    expect(find.text('SAVE SLOT 2'), findsOneWidget);
    expect(find.text('SAVE SLOT 3'), findsOneWidget);
    expect(find.text('Empty slot'), findsOneWidget);
    expect(find.text('This save could not be read'), findsOneWidget);
    expect(find.text('LOAD'), findsOneWidget);

    // Back to start, then New Game on the occupied slot.
    await tester.tap(find.byType(WfRoundButton).first);
    await _settle(tester, 6);
    await tester.tap(find.text('NEW GAME'));
    await _settle(tester, 8);
    await tester.tap(find.text('NEW GAME').first);
    await _settle(tester, 6);
    expect(find.text('Replace this save?'), findsOneWidget);
    await tester.tap(find.text('CANCEL'));
    await _settle(tester, 6);
    expect(saves.slots[1]!.xp, 300, reason: 'cancel keeps the save');
  });

  testWidgets('map shows the start node available and later nodes locked', (tester) async {
    _phone(tester);
    final cubit = await _playing(_MemorySaves(slots: {1: _save()}));
    await tester.pumpWidget(_host(cubit, const SandboxMapPage()));
    await _settle(tester);
    final medallions = tester.widgetList<MapNodeMedallion>(find.byType(MapNodeMedallion, skipOffstage: false)).toList();
    expect(medallions.length, cubit.state.content!.regions.first.nodes.length);
    expect(medallions.firstWhere((m) => m.node.id == 'r1_n1').state.name, 'available');
    expect(medallions.firstWhere((m) => m.node.id == 'r1_n2').state.name, 'locked');
    await cubit.close();
  });

  testWidgets('spellbook hides undiscovered words and shows details of discovered ones', (tester) async {
    _phone(tester);
    final cubit = await _playing(_MemorySaves(slots: {
      1: _save(words: {'cold': const WordStats().record(isCorrect: true, type: ChallengeType.antonym, battleIndex: 1)}),
    }));
    await tester.pumpWidget(_host(cubit, const SpellbookPage()));
    await _settle(tester, 4);
    expect(find.text('COLD'), findsOneWidget);
    expect(find.text('HOT'), findsNothing);
    await tester.tap(find.text('COLD'));
    await _settle(tester, 4);
    expect(find.text('having a low temperature'), findsWidgets);
    expect(find.text('HOT'), findsWidgets);
    await cubit.close();
  });

  testWidgets('the Skills page separates passives, spells and buffs; a witnessed spell is learned for one point', (tester) async {
    _phone(tester);
    // Level 3 (two points), Keeper of the Gate already beaten: Guardian Ward is witnessed.
    final saves = _MemorySaves(slots: {
      1: _save(xp: 220, nodes: {'r1_boss': const NodeProgress(completed: true, wins: 1)}),
    });
    final cubit = await _playing(saves);
    final progression = cubit.dependencies.progression;
    expect(progression.availableSkillPoints(cubit.state.save!), 2);
    await tester.pumpWidget(_host(cubit, const SkillsPage()));
    await _settle(tester, 4);
    expect(find.text('PASSIVE SKILLS'), findsOneWidget);
    // The list is lazy: scroll section by section.
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('SPELLS'), 160, scrollable: list);
    await _settle(tester, 2);
    expect(find.text('SPELLS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('LEARN'), 160, scrollable: list);
    await _settle(tester, 2);
    expect(find.text('LEARN'), findsOneWidget, reason: 'only the witnessed Guardian Ward can be learned');
    await tester.tap(find.text('LEARN'));
    await _settle(tester, 6);
    expect(cubit.state.save!.spells, ['guardian_ward']);
    expect(progression.availableSkillPoints(cubit.state.save!), 1);
    expect(find.text('LEARN'), findsNothing);
    expect(find.text('LEARNED'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Defeat').first, 160, scrollable: list);
    await _settle(tester, 2);
    expect(find.textContaining('Defeat'), findsWidgets, reason: 'Thorn Blight and Rune Bind stay locked');
    await tester.scrollUntilVisible(find.text('BUFFS'), 160, scrollable: list);
    await _settle(tester, 2);
    expect(find.text('BUFFS'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('a battle alternates turns and can be played to victory; progress is saved', (tester) async {
    _phone(tester);
    final saves = _MemorySaves(slots: {1: _save()});
    final cubit = await _playing(saves);
    final region = cubit.state.content!.regions.first;
    final node = region.node('r1_n1')!;
    await tester.pumpWidget(_host(cubit, BattlePage(node: node, region: region, seed: 4, renderScene: false)));
    await _settle(tester, 25);

    const validator = AnswerValidator();
    final turnsSeen = <String>{};
    for (var round = 0; round < 60; round++) {
      if (cubit.state.save!.isCompleted('r1_n1')) break;
      final panel = find.byType(ChoicePanel);
      if (panel.evaluate().isEmpty) {
        await _settle(tester, 4);
        continue;
      }
      final controller = tester.element(panel).read<BattleController>();
      final snapshot = controller.state;
      if (snapshot.phase != BattlePhase.awaitingInput) {
        await _settle(tester, 3);
        continue;
      }
      turnsSeen.add(snapshot.turn.name);
      final correct = validator.correctOptionId(snapshot.challenge!)!;
      final text = snapshot.challenge!.option(correct)!.text.toUpperCase();
      await tester.tap(find.descendant(of: panel, matching: find.text(text)));
      await _settle(tester, 22);
    }
    await _settle(tester, 30);
    expect(turnsSeen, containsAll(['player', 'enemy']));
    expect(cubit.state.save!.isCompleted('r1_n1'), isTrue);
    expect(saves.writes, greaterThan(0));
    expect(find.text('VICTORY'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _settle(tester, 30);
    await cubit.close();
  });
}

void spellChooserTests() {
  testWidgets('the spell chooser lists every known spell with cost and state, and returns the tapped castable one',
      (tester) async {
    final content = loadShippedContent();
    final ids = content.combat.allSpecials;
    final spells = [for (final id in ids) content.combat.move(id)!];
    // Spell 0 rests, spell 1 lacks mana, spells 2 and 3 are castable.
    final states = {
      ids[0]: SpellState(id: ids[0], manaCost: spells[0].manaCost, cooldownLeft: 2, block: SpellBlock.cooldown),
      ids[1]: SpellState(id: ids[1], manaCost: spells[1].manaCost, block: SpellBlock.mana, manaMissing: 12),
      ids[2]: SpellState(id: ids[2], manaCost: spells[2].manaCost, castable: true),
      ids[3]: SpellState(id: ids[3], manaCost: spells[3].manaCost, castable: true),
    };
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async =>
                chosen = await showSpellChooser(context, spells: spells, states: states, mana: 40, manaMax: 100),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(SpecialSpellCard), findsNWidgets(4));
    expect(find.text('Choose a spell'), findsOneWidget);
    expect(find.text('40/100'), findsOneWidget);
    expect(find.text('READY IN 2 TURNS'), findsOneWidget);
    expect(find.text('NEED 12 MORE MANA'), findsOneWidget);
    expect(find.text('READY'), findsNWidgets(2));
    // Resting spell: tapping its CAST does nothing.
    await tester.tap(find.text('CAST').at(0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    await tester.ensureVisible(find.text('CAST').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CAST').at(2));
    await tester.pumpAndSettle();
    expect(chosen, ids[2]);
  });
}
