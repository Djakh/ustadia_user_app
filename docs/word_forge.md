# Word Forge — Sandbox Mode (developer guide)

Word Forge is a lightweight fantasy battle game where English words are spells.
It lives in `lib/features/word_forge/` as a self-contained module; the Ustadia
app only wires its ports (DI, one route, one Practice card).

## Module layout

```
lib/features/word_forge/
  word_forge.dart            public API (exports) — the only file the app imports
  word_forge_module.dart     WordForgeDependencies (ports the host provides)
  word_forge_assets.dart     every asset path in one place
  domain/                    pure Dart, no Flutter imports
    content/                 WordEntry, RuneTemplate, IncantationEntry, EnemyDefinition,
                             BattleDefinition (enemies/stages), RegionDefinition,
                             ContentValidator, WordForgeContent (catalog)
    language/                ChallengeType, LanguageChallenge, ChallengeFactory + generators,
                             DistractorPicker, WordSelector (adaptive), validators
    battle/                  BattleEngine (turn state machine), EncounterDirector (who acts,
                             what they do), CombatConfig (balance + moves), TimerPolicy,
                             BattleAssist, snapshots/events/results
    characters/              PlayerCharacterDefinition (male/female apprentice, cosmetic)
    progression/             mastery, stars, XP/levels, rewards, map unlock rules, buffs, upgrades
    sandbox/                 SandboxProgression (node -> BattleSetup, result -> save)
    save/                    WordForgeSave (versioned, per slot) + SaveCodec (migrations)
    repositories/, services/ ports: content, save slots, analytics, audio
  data/                      asset content repo, SharedPreferences slot repo, cloud sync
                             (Dio client + synced repo), audio, JSON parser
  game/                      Flame runtime: WordForgeBattleGame, BattleChoreographer,
                             entities (animator + skins, apprentice), vfx
  presentation/              Flutter UI: cubits, pages (start, slots, character, hub, map,
                             battle…), widgets, theme bridge, l10n, portal transition
```

Flow of a battle:

```
SandboxProgression.buildSetup(node) ─► BattleEngine ─► snapshots ─► BattleController (Cubit) ─► Flutter HUD/panels
                                         ▲            └► events ────► BattleChoreographer (Flame VFX), audio, analytics
                               EncounterDirector (intents, criticals, specials, fairness)
BattleEngine.result ─► WordForgeCubit.completeBattle ─► SandboxProgression.applyBattle ─► save slot repository
```

The engine is driven by a `Ticker` in `BattlePage` (not by Flame), so battles
are fully testable without rendering and pause with the app lifecycle (a
running Critical timer freezes while the app is in the background). Flame only
listens to events and never changes state. Story Mode can build its own
`BattleSetup` and reuse the engine, content, save and renderer unchanged.

## Combat model

Battles are turn-based: **Your turn** / **Enemy turn** alternate and the HUD
shows HP, the mana pool and the SPELLS button. Every action is one of three
categories:

| | Player | Enemy |
|---|---|---|
| **Normal** | synonym = attack, gently timed (≈8 s + reading time). Correct = full hit; too slow or wrong = **Weak Cast** (35% damage). A *wrong* word also leaves the player open to a small counter (25% of the enemy attack); a slow one does not. | antonym = defence, same relaxed timer scaled by the enemy's pace (goblins ×0.9, golems ×1.2, brutes ×1.25). Timeout = failed defence. |
| **Critical** | *Critical Opportunity* after a correct normal hit (bonus; the hit always stays): Word Match, Sentence Strike, Rapid Words | urgent antonym defence with a short fair timer (≈5.5 / 4.75 / 4 s by degree band, floor 3.5 s); success parries and gives mana, failure is a heavier hit |
| **Special** | a spell cast on the player's attack turn: costs **mana**, then rests for a few attack turns (**cooldown**); each is a multi-stage English challenge (see below) | telegraphed one turn ahead (wind-up VFX + warning cue in the enemy's magic family), per-enemy cooldown: Heavy Spell, Protection (shield with HP), Rune Lock, Double Threat, Sentence Curse, Wisp Storm, Thorn Curse (poison); bosses add a signature |

### Mana

One pool (`specialMeter` in combat.json): max 100, **starts every battle at
20** (never persists between battles), grows with good English: normal hit
+9, successful defence +7, Critical landed +10, Critical defended +12, shield
shattered +8, combo milestone +6 every 4, Word Flow +2 per task. Weak Casts
give nothing. Boss stages with `grantSpecial` fill it.

### Player Specials (spells)

The SPELLS button (always tappable on the player's attack turn) opens a panel
with every known spell, its role, mana cost, rest time and state: READY /
READY IN N TURNS / NEED N MORE MANA / NO EFFECT ON THIS ENEMY. The battle is
paused while the panel is open. One rule for mistakes: a cast with **no
stage solved fizzles** — the mana is spent, the turn is used, and that is all
(no cooldown, no counter). Any solved stage starts the cooldown.

| Spell | Role | Mana / rest | Witnessed at | Stages | Effect (full / partial) |
|---|---|---|---|---|---|
| Apprentice Incantation | damage | 35 / 2 turns | starter | opposite → similar → rune/sentence | 56 dmg + 50% splash / 65% / 30% |
| Guardian Ward | defence | 30 / 3 turns | Keeper of the Gate (`r1_boss`) | opposite → rune | absorbs the next 2 enemy hits and reflects 10 each / 1 hit |
| Thorn Blight | poison | 35 / 3 turns | Thornmother (`r2_boss`) | similar → sentence/rune | 14 dmg before each enemy turn for 3 turns, through stone skin and shields / 2 turns. Ethereal enemies (wisps) are immune, and the panel says so. |
| Rune Bind | control | 35 / 3 turns | Ruin Scribes (`r3_n4`) | rune → similar | enemy loses its next turn + 28 dmg / 28 dmg |

Spells are **witnessed** by clearing the node with `teaches`, then **learned on
the Skills page for one skill point** (the same pool as passive skills:
one point per level). `SandboxProgression.witnessedSpells` derives the
witnessed set from cleared nodes; `learnSpell` spends the point; the save
keeps `spells` (v4). Criticals, Specials and poison ticks pierce stone skin;
Normal hits do not. Word Storm (`word_storm_spell`, multi-hit) stays in the
built-in moves for v2 content but is not in the roster.

**Obvious interactions, no element chart:** stone skin / shields → Thorn
Blight and Criticals; heavy hitters → Guardian Ward; quick enemies and
telegraphed big moves → Rune Bind; ethereal → no poison.

* **EncounterDirector** (seeded `Random`) plans each enemy's intent one turn
  ahead, alternates actors in two-enemy fights, keeps the first turns normal,
  enforces critical cooldowns, minimum normal turns between events, special
  cooldowns and "no same move twice in a row". Boss stages can force a move
  with `opensWith`.
* **Shields** (Protection): a barrier with HP pips; similar-meaning answers
  crack it, breaking it staggers the enemy (it skips its next turn).
  Guardians shield the weakest ally.
* **Enemy identity** comes from `archetypes` in combat.json: `criticalChance`,
  `specialChance`, `specials`, `shieldStrength`, `role`, `armor` (stone skin:
  share of Normal damage ignored), `timerScale` (quick vs slow telegraphs),
  `element` (visual/audio family: slash, rock, arcane, ink, spark, smash,
  thorn, frost, steel, glint — also picks the Special wind-up and warning
  sound) and `poisonImmune` (ethereal).
* **Poison** (`MoveEffect.poison`): ticks `amount` at the start of the
  victim's turn for `duration` turns (`BattleEngine._tickPoison`, its own
  short beat in the flow). Enemy version (`thorn_curse`): a failed defence
  poisons the player; a ward absorbs the whole thing.
* **Gates** unlock mechanics by battle wins (`gates` in combat.json): Critical
  after 1 win, Special 2, Protection 3, other enemy Specials 5. Tutorials show
  once per save the first time a mechanic appears.
* **Timers** come from `TimerPolicy`: base per degree band + reading allowance
  for long words/sentences + bonus for unknown words − discount for mastered
  ones, never below `minimumNormalSeconds` (5 s) / `minimumChoiceSeconds` (3.5 s).
* **Stars**: ★ victory · ★ accuracy ≥ 80% · ★ attack turns within the
  encounter's budget (`StarRating.turnBudget`: effective HP ÷ 30, +1, +1 per
  extra phase, +1 if the enemy shields, +1 for two enemies). The results
  screen lists all three objectives.

### combat.json (balance)

Every number lives in `assets/word_forge/content/combat.json` (missing keys
fall back to the defaults in `CombatConfig`): `balance` (damage, multipliers,
partial-special shares), `specialMeter` (charge per event), `pacing` (critical
chances and cooldowns), `timers`, `gates`, `archetypes` (per-archetype
`criticalChance`, `specialChance`, `specials`, `shieldStrength`, `role`),
`playerCriticals`, `playerSpecial` and `moves`. `specialMeter.start` is the
mana every battle begins with.

`playerSpecial` is the starter spell and `learnableSpecials` lists the spells
map nodes may teach. `moves: []` uses the built-in moves (`CombatConfig.defaultMoves`). Entries in
`moves` override or add moves by id:

```json
{"id": "frost_chain", "label": "Frost Chain", "kind": "special", "effect": "damage",
 "tasks": ["antonym", {"type": "synonym", "samePrompt": true, "degreeOffset": 1}],
 "timer": "enemySpecial", "timerScale": 1.1, "damagePerFailure": 0.7, "weight": 1}
```

* `kind`: `critical` (player Critical mini-game) or `special`.
* `effect`: `damage`, `shield` (Protection-style barrier, `shieldStrength`), `lock`
  (failure skips the player's next attack), `poison` (`amount` per tick,
  `duration` ticks), player-only `ward` (`charges`, `reflect`), `bind`, `multiHit`.
* player spells: `manaCost`, `cooldown` (attack turns).
* `tasks`: challenge types in order (`antonym`, `synonym`, `missingRune`,
  `incantation`, `wordMatch`) or objects with `types`, `degreeOffset`, `style`
  (`standard`/`semantic`/`mimic`), `samePrompt`, `preferFamiliar`.
* `timer`: `none`, `enemyCritical`, `playerCritical`, `enemySpecial`.
* `damagePerFailure`: share of the enemy's attack taken per failed task.

## Content (data-driven)

All content is JSON in `assets/word_forge/content/`. Invalid entries are
skipped and reported (debug builds print them and show a banner on the hub);
production never crashes on bad content. `test/features/word_forge/content_test.dart`
validates the shipped files and fuzzes challenge generation — run it after
every content change.

### words.json

```json
{"id": "cold", "text": "cold", "pos": "adjective", "degree": 1, "cefr": "A1",
 "cluster": "chill", "domain": "temperature",
 "definition": "having a low temperature",
 "synonyms": ["chilly", "freezing"], "antonyms": ["hot"],
 "examples": ["Put on a coat. It is cold outside."],
 "tags": ["temperature"], "confusables": ["gold"]}
```

* `degree`: internal difficulty (1 = very common A1 … 4 = A2–B1, 5+ = B1 and up).
* `synonyms` / `antonyms`: plain text; they may reference words that are not entries.
  Only add relationships a dictionary would accept — distractors rely on them.
* `cluster`: words sharing a core meaning (happy/glad/cheerful → `joy`). Words in the
  answer's cluster are never used as distractors, so keep clusters accurate.
* `domain`: broad topic. Opposite challenges never use distractors from the prompt's
  domain; similar-meaning challenges only allow the prompt's clear opposites from it.
* `confusables`: look-alike words used by Mimic enemies (lose/loose). Must be clearly wrong.

### runes.json (Missing Rune)

```json
{"id": "rune_001", "sentence": "She ___ to school every day.", "answer": "goes",
 "distractors": ["go", "going", "gone"], "degree": 1, "cefr": "A1",
 "topic": "present_simple", "wordIds": ["go"]}
```

Distractors are curated: each must be clearly wrong *in this sentence*.
`wordIds` link the sentence to vocabulary so weak words come back in context.

### incantations.json (Spell Construction)

```json
{"id": "inc_001", "text": "She goes to school every day.",
 "alternatives": ["Every day she goes to school."], "degree": 1, "wordIds": ["go"]}
```

List every other natural word order in `alternatives` (same words only).

### enemies.json

```json
{"id": "stone_sentinel", "name": "Stone Sentinel", "archetype": "stoneGuardian",
 "skin": "golem", "palette": {"primary": "#9AA3AE", "secondary": "#5C6470", "accent": "#5FE1FF"},
 "scale": 1.0, "maxHp": 85, "attack": 12, "tempo": 0.8,
 "distractorStyle": "standard", "traits": [],
 "behaviour": {"specialChance": 0.4, "shieldStrength": 3}}
```

* `archetype`: `goblin` (fast, criticals), `stoneGuardian` (stone skin,
  shields, slow), `rogueMage` (rune lock), `wordEater`, `mimic`, `wisp`
  (fragile, fast, wisp storm), `brute` (heavy telegraphed spell), `eliteMage`,
  `boss`. Defaults come from `archetypes` in combat.json.
* `behaviour`: optional per-enemy override of the archetype (`criticalChance`,
  `specialChance`, `specials`, `shieldStrength`, `role`, `armor`, `timerScale`,
  `element`, and for bosses `signature`: `broken_incantation`, `mirror_spell`,
  `rune_seal`, `word_storm`).
* `skin`: ogre, goblin, golem, mage, blob, chest, wisp, knight, treant, lich.
* `distractorStyle`: `standard`, `semantic` (related-but-wrong), `mimic` (+ look-alikes).
* `traits`: `wordEater` (eats a placed word once per incantation), `mimic`.
* Optional `"sprite": "stone_sentinel.png"` loads `assets/word_forge/enemies/…`
  (add the folder to pubspec) and replaces the procedural skin.

### battles.json

```json
{"id": "r1_n8", "enemies": [{"id": "goblin_raider", "hp": 45}, {"id": "goblin_scout", "hp": 40}],
 "degree": [2, 2], "rewards": {"xp": 28}}

{"id": "r1_boss", "enemies": ["gate_keeper"], "degree": [1, 2],
 "rewards": {"xp": 80, "buffs": {"hint": 2}},
 "stages": [
   {"name": "The Gate Holds", "untilHp": 0.75, "special": 0, "critical": 0.6},
   {"name": "Shield of Echoes", "untilHp": 0.5, "opensWith": "protection"},
   {"name": "Mirror of the Gate", "opensWith": "mirror_spell", "enraged": true, "grantSpecial": true}]}
```

* `enemies`: one or two (max 2) enemy ids, optionally with an `hp` override.
  The first enemy is the main one; stages follow its HP.
* Stages: every stage except the last needs `untilHp`. `critical` / `special`
  scale the enemy's chances in that stage, `opensWith` forces a move when the
  stage starts, `enraged` raises damage, `grantSpecial` fills the player's
  meter for the finale. The main enemy cannot fall before its last stage.
* Battles without `stages` are one stage. Target lengths: standard 45–90 s,
  elite 1–2 min, boss 2–4 min (`progression_test` checks this by simulation).

### regions.json

Nodes: `battle`, `elite`, `challenge`, `bonus`, `recovery`, `miniBoss`, `boss`,
`mystery`. `row` is the vertical position (0 = start), `lane` is -1…1.
`next` lists the nodes a node unlocks (several = branch; a node unlocks when
*any* predecessor is completed). `optional: true` marks side paths. Bonus and
recovery nodes grant `rewards` once; mystery nodes pick one of `outcomes`
deterministically per player.

## How to…

**Add vocabulary** — append entries to `words.json` (unique `id`/`text`, accurate
`cluster`/`domain`, dictionary-valid relations), optionally add runes/incantations
that reference them via `wordIds`, then run `flutter test test/features/word_forge`.

**Add an enemy** — add an entry to `enemies.json` (reuse a skin with a new
palette, pick an archetype, optionally tune `behaviour`), reference it from a
battle. A brand-new look needs a new `EntitySkin` in `game/entities/skins.dart`
registered in `skinFor`, or a sprite.

**Add an enemy Special** — add a move to `moves` in combat.json (or to
`CombatConfig.defaultMoves`) built from existing tasks, then list its id in an
archetype's or enemy's `specials` (or as a boss `signature`). Give it a
`label` and add that label to the translation files. A new kind of effect
(beyond damage/shield/lock) needs a `MoveEffect` value and handling in
`BattleEngine._resolveAction`.

**Add a player Special spell** — add a `kind: "special"` move with an
`effect` (`damage`, `ward` + `charges` + `reflect`, `bind` + `amount`,
`poison` + `amount` + `duration`, `multiHit` + `amount`), a `manaCost` and a
`cooldown`, list it in `learnableSpecials`, put `"teaches": "<id>"` on a
main-path node, and add its name/role/effect/origin strings to `WfStrings`
and the translation files. A new kind of effect needs a `MoveEffect` value, a branch
in `BattleEngine._resolveAction` and a choreography in
`BattleChoreographer._playerSpecial`.

**Add an enemy magic family** — add an `ElementStyle` value (projectile look
in `ElementBolt`, impact in `elementImpact`), an impact sound in
`WordForgeSfx` / `WordForgeAssets.impactFor`, and use it as `element`.

**Add a player Critical mini-game** — add a `kind: "critical"` move and its id
to `playerCriticals`. If it needs a new interaction, add a `ChallengeType`
with an input mode and a panel branch in `ChallengePanel` (see `wordMatch` /
`MatchPanel`).

**Add a region** — add battles to `battles.json`, then a region to `regions.json`
with a higher `order` and a `theme` (`road`, `forest`, `ruins`; unknown themes
fall back to `road` until art exists). The region unlocks automatically after
the previous region's boss; existing saves stay valid.

**Add a language mechanic** (definitions, word families, phrasal verbs…):
1. add a `ChallengeType` value;
2. implement a `ChallengeGenerator` and register it in `ChallengeFactory.defaultGenerators`;
3. add its content file/model if it needs new data;
4. use it in moves, e.g. `"tasks": ["definition"]`, and add it to `ContentValidator` coverage.
Choice-style mechanics reuse `ChoicePanel` and all combat visuals automatically;
a new input style adds a branch in `ChallengePanel`.

**Check the balance** — `WF_BALANCE_REPORT=1 flutter test test/features/word_forge/balance_report_test.dart`
plays every battle with strong / average / struggling learners (plus an
assisted retry, a random "masher" and a "waiter" who lets timers expire),
prints win rates, durations, Specials and mana per fight, fizzles, star
distributions, how often each spell is picked when castable, eight spell
builds (damage/defence/control/poison-first, spam one, hoard mana, never
cast), an upgrades comparison and a full progression curve.

**Test quickly by hand** — debug builds show a **QA Arena** tile on the hub:
pick any enemy, start with all spells / full mana / a ward, force enemy
Specials, halve enemy HP; the fight is played with the real engine and never
saved.

## Persistence

`LocalWordForgeSaveRepository` (behind the `WordForgeSaveRepository` port) stores **three save slots per profile**
in SharedPreferences: `word_forge.<profile>.slot<N>` plus a `.backup` (previous
good copy) and `.corrupt` (unreadable data moved aside); `.last_slot` drives
Continue. A broken slot falls back to its backup or is shown as unreadable;
other slots are never touched. The old single save (`word_forge.save.<profile>`)
moves into slot 1 automatically, and the player picks a character once.

Each save keeps its own metadata (save id, slot, character, created/last
played), level/XP, region, nodes, word mastery, buffs, upgrades and tutorial
flags and learned spells (v4: spells cost a skill point; v3 free spells are
dropped on migration and can be re-learned since their nodes stay cleared).
Saves happen at checkpoints: new game, battle end, node claim, upgrades,
spell learning, settings, region change. Unlocks are derived from completed nodes
(plus a stored "ever unlocked" set), so content changes never lock players
out. Bump `WordForgeSave.currentVersion` and add a `SaveCodec` migration when
the format changes (v1 → v2 is the slot/character/tutorial migration, v2 → v3
adds spells, v3 → v4 drops free spells).

### Cloud saves

`SyncedWordForgeSaveRepository` wraps the local repository and keeps a server
copy of each slot per student (`/students/word-forge/saves`, client
`DioWordForgeCloud` on the host Dio, so the access token is attached). Progress
therefore survives a reinstall or a new phone.

* **Offline first.** Local storage stays the working copy. `save` writes locally,
  then uploads in the background (one request at a time; a burst of saves becomes
  one upload of the newest copy). Play never waits for the network.
* **Reconcile on open.** `listSlots` (opening Word Forge / the slot screen) first
  syncs all three slots with the server, for at most 8 s, then shows local slots.
  A slot only on the server is downloaded, a slot only on the phone is uploaded,
  and Continue points at the slot played last on any device.
* **Revisions.** Per slot, `<slotKey>.sync` stores `{rev, hash}`: the server
  revision and the SHA-256 of the local JSON at the last sync. A PUT sends that
  revision as `baseRevision` (0 = create). On `409 REVISION_CONFLICT` the server
  copy in the body decides. If it has the same hash, it was our own write whose
  response was lost, so the app adopts its revision. Otherwise the copy with the
  newer `lastPlayedAtMs` wins: the app either overwrites on top of the server
  revision or replaces the local copy. If `server` is null (deleted elsewhere),
  the app recreates the slot with base 0.
* **New Game over a slot** deletes it on the server with `?revision=`. A 409
  keeps the other device's newer progress, which comes back at the next sync.
* **Failures are silent.** Offline, timeouts, 401/403, 413, 429, 5xx and a 404
  without `SLOT_EMPTY` (route not deployed) all mean "try later". Requests carry
  `skipUnauthorizedLogout` (a background sync never logs the student out) and
  bypass the host's GET cache. Headers: `X-Device-Id` (random, stored in
  `word_forge.device_id`) and `X-App-Version`.
* **Who syncs.** Only signed-in students (`canSync` in `injection_container.dart`);
  guest and `local_*` profiles stay local only.
* Downloaded data goes through `SaveCodec`, so older server copies migrate like
  local ones. `playerId`/`slot` are rewritten to the local profile and slot.

Tests: `test/features/word_forge/cloud_sync_test.dart` (sync rules against an
in-memory server) and `dio_cloud_test.dart` (HTTP mapping of the documented
responses).
