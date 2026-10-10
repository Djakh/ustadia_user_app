import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/data/content_parser.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/difficulty.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/region_definition.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_factory.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_validator.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/distractor_style.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/text_normalizer.dart';

import 'helpers.dart';

void main() {
  final content = loadShippedContent();

  group('shipped content', () {
    test('parses without errors', () {
      expect(content.errors, isEmpty, reason: content.errors.join('\n'));
    });

    test('has a substantial beginner-to-B1 dataset', () {
      expect(content.words.length, greaterThanOrEqualTo(200));
      expect(content.runes.length, greaterThanOrEqualTo(60));
      expect(content.incantations.length, greaterThanOrEqualTo(40));
      for (final degree in [1, 2, 3, 4]) {
        expect(content.words.values.where((word) => word.degree == degree).length, greaterThanOrEqualTo(30),
            reason: 'degree $degree');
      }
    });

    test('has at least three regions, each ending with a boss and containing optional paths', () {
      expect(content.regions.length, greaterThanOrEqualTo(3));
      for (final region in content.regions) {
        expect(region.node(region.bossNodeId)!.type, MapNodeType.boss);
        expect(region.nodes.any((node) => node.optional), isTrue, reason: region.id);
        expect(region.nodes.any((node) => node.type == MapNodeType.miniBoss || node.type == MapNodeType.elite), isTrue);
        expect(region.nodes.any((node) => node.next.length > 1), isTrue, reason: '${region.id} needs a branch');
      }
    });

    test('regions get gradually harder', () {
      for (var i = 1; i < content.regions.length; i++) {
        expect(content.regions[i].degrees.max, greaterThanOrEqualTo(content.regions[i - 1].degrees.max));
      }
    });

    test('bosses escalate over phases, open the last one with a signature and grant a finishing Special', () {
      for (final region in content.regions) {
        final battle = content.battles[region.node(region.bossNodeId)!.battleId]!;
        expect(battle.stages.length, greaterThanOrEqualTo(3));
        expect(battle.stages.last.grantSpecial, isTrue);
        expect(content.combat.move(battle.stages.last.opensWith!), isNotNull);
      }
    });

    test('combat balance loads from combat.json and every referenced move exists', () {
      expect(content.combat.balance.normalDamage, greaterThan(0));
      expect(content.combat.archetypes, isNotEmpty);
      for (final id in [...content.combat.playerCriticals, ...content.combat.allSpecials]) {
        expect(content.combat.move(id), isNotNull, reason: id);
      }
      expect(content.combat.allSpecials.length, 4, reason: 'one starter spell plus three learnable ones');
      final taught = [for (final region in content.regions) for (final node in region.nodes) if (node.teaches != null) node.teaches!];
      expect(taught.toSet(), content.combat.learnableSpecials.toSet(), reason: 'every learnable spell is taught by exactly one node');
      expect(taught.length, taught.toSet().length);
      for (final region in content.regions) {
        for (final node in region.nodes) {
          if (node.teaches == null) continue;
          expect(node.optional, isFalse, reason: '${node.id} teaches a spell and must be on the main path');
        }
      }
      expect(content.enemies.values.map((e) => content.combat.behaviourFor(e.archetype.name).merge(e.behaviour).element).toSet().length,
          greaterThanOrEqualTo(7), reason: 'enemy families look different');
      expect(content.issues.where((issue) => issue.source.startsWith('enemy:') && issue.message.contains('unknown move')), isEmpty);
    });

    test('two-enemy encounters exist but never more than two enemies', () {
      expect(content.battles.values.where((battle) => battle.isMultiEnemy), isNotEmpty);
      expect(content.battles.values.every((battle) => battle.enemies.length <= 2), isTrue);
    });

    test('no word lists the same text as synonym and antonym', () {
      for (final word in content.words.values) {
        expect(word.normalizedSynonyms.intersection(word.normalizedAntonyms), isEmpty, reason: word.id);
      }
    });

    test('every incantation alternative uses exactly the same words', () {
      for (final entry in content.incantations) {
        final sorted = [...entry.tokens]..sort();
        for (final alternative in entry.alternatives) {
          final other = TextNormalizer.tokenize(alternative)..sort();
          expect(other, sorted, reason: entry.id);
        }
      }
    });
  });

  group('challenge generation over shipped content', () {
    const validator = ChallengeValidator();

    test('every battle step can always produce a valid challenge', () {
      for (final battle in content.battles.values) {
        for (final type in ChallengeType.values) {
          final factory = ChallengeFactory();
          for (var seed = 0; seed < 12; seed++) {
            final challenge = factory.create(
              GenerationRequest(type: type, degrees: battle.degrees, style: DistractorStyle.mimic),
              GenerationContext(content: content, random: Random(seed)),
            );
            expect(challenge, isNotNull, reason: '${battle.id} ${type.name}');
            expect(validator.validate(challenge!), isEmpty, reason: '${battle.id} ${challenge.prompt}');
          }
        }
      }
    });

    test('antonym distractors are never valid opposites', () {
      final factory = ChallengeFactory();
      for (var seed = 0; seed < 400; seed++) {
        for (final style in DistractorStyle.values) {
          final challenge = factory.create(
            GenerationRequest(type: ChallengeType.antonym, degrees: const DegreeRange(1, 4), style: style),
            GenerationContext(content: content, random: Random(seed)),
          )!;
          final prompt = content.wordByText(challenge.prompt)!;
          for (final option in challenge.options) {
            final text = TextNormalizer.normalize(option.text);
            if (text == TextNormalizer.normalize(challenge.correctAnswer)) continue;
            expect(prompt.normalizedAntonyms.contains(text), isFalse, reason: '${prompt.text}: ${option.text}');
            final entry = content.wordByText(option.text);
            if (entry != null) {
              expect(entry.normalizedAntonyms.contains(prompt.normalized), isFalse,
                  reason: '${prompt.text}: ${option.text} lists it as antonym');
            }
          }
        }
      }
    });

    test('synonym distractors are never valid similar words', () {
      final factory = ChallengeFactory();
      for (var seed = 0; seed < 400; seed++) {
        final challenge = factory.create(
          const GenerationRequest(type: ChallengeType.synonym, degrees: DegreeRange(1, 4), style: DistractorStyle.semantic),
          GenerationContext(content: content, random: Random(seed)),
        )!;
        final prompt = content.wordByText(challenge.prompt)!;
        for (final option in challenge.options) {
          final text = TextNormalizer.normalize(option.text);
          if (text == TextNormalizer.normalize(challenge.correctAnswer)) continue;
          expect(prompt.normalizedSynonyms.contains(text), isFalse, reason: '${prompt.text}: ${option.text}');
          final entry = content.wordByText(option.text);
          if (entry != null) {
            expect(entry.normalizedSynonyms.contains(prompt.normalized), isFalse,
                reason: '${prompt.text}: ${option.text} lists it as synonym');
            expect(entry.cluster == prompt.cluster, isFalse, reason: '${prompt.text}: ${option.text} same cluster');
          }
        }
      }
    });

    test('the correct answer is spread across option positions', () {
      final positions = <int, int>{};
      final factory = ChallengeFactory();
      for (var seed = 0; seed < 200; seed++) {
        final challenge = factory.create(
          const GenerationRequest(type: ChallengeType.antonym, degrees: DegreeRange(1, 2)),
          GenerationContext(content: content, random: Random(seed)),
        )!;
        final index = challenge.options.indexWhere((option) => option.text == challenge.correctAnswer);
        positions[index] = (positions[index] ?? 0) + 1;
      }
      expect(positions.keys.length, 4);
      for (final count in positions.values) {
        expect(count, greaterThan(20));
      }
    });

    test('generation is deterministic for a seed', () {
      final a = ChallengeFactory().create(
        const GenerationRequest(type: ChallengeType.synonym, degrees: DegreeRange(1, 2)),
        GenerationContext(content: content, random: Random(42)),
      );
      final b = ChallengeFactory().create(
        const GenerationRequest(type: ChallengeType.synonym, degrees: DegreeRange(1, 2)),
        GenerationContext(content: content, random: Random(42)),
      );
      expect(a!.prompt, b!.prompt);
      expect(a.options, b.options);
    });
  });

  group('word match', () {
    test('boards have one solution: pairs from different topics with no cross relations', () {
      final factory = ChallengeFactory();
      for (var seed = 0; seed < 150; seed++) {
        final challenge = factory.create(
          const GenerationRequest(type: ChallengeType.wordMatch, degrees: DegreeRange(1, 4)),
          GenerationContext(content: content, random: Random(seed)),
        )!;
        expect(challenge.pairs.length, 3);
        final lefts = [for (final id in challenge.pairs.keys) content.wordByText(challenge.option(id)!.text)!];
        final rights = [for (final id in challenge.pairs.values) content.wordByText(challenge.option(id)!.text)!];
        for (var i = 0; i < lefts.length; i++) {
          expect(lefts[i].normalizedAntonyms.contains(rights[i].normalized), isTrue);
          for (var j = 0; j < rights.length; j++) {
            if (i == j) continue;
            expect(lefts[i].normalizedAntonyms.contains(rights[j].normalized), isFalse,
                reason: '${lefts[i].text} could also match ${rights[j].text}');
          }
        }
        expect(lefts.map((word) => word.domain).toSet().length, lefts.length);
      }
    });
  });

  group('content validation', () {
    test('invalid entries are dropped and reported, the rest still loads', () {
      final parsed = const ContentParser().parse(const ContentDocuments(
        words: '{"words": [{"id": "hot", "text": "hot", "definition": "warm", "synonyms": ["cold"], "antonyms": ["cold"]},'
            '{"id": "big", "text": "big", "definition": "large", "antonyms": ["small"]}, {"id": "x"}]}',
        runes: '{"runes": [{"id": "r1", "sentence": "No blank here", "answer": "a", "distractors": ["b", "c"]},'
            '{"id": "r2", "sentence": "I ___ happy.", "answer": "am", "distractors": ["am", "is"]}]}',
        incantations: '{"incantations": [{"id": "i1", "text": "Too short"}]}',
        enemies: '{"enemies": [{"id": "e1", "name": "E", "maxHp": 10, "attack": 1}]}',
        battles: '{"battles": [{"id": "b1", "enemyId": "missing", "stages": [{"steps": ["counter"]}]}]}',
        regions: 'not json',
      ));
      expect(parsed.words.keys, ['big']);
      expect(parsed.runes, isEmpty);
      expect(parsed.incantations, isEmpty);
      expect(parsed.battles, isEmpty);
      expect(parsed.regions, isEmpty);
      expect(parsed.errors.length, greaterThanOrEqualTo(6));
    });
  });
}
