/// Word Forge — a lightweight fantasy adventure where words are spells.
///
/// Public surface of the module. The host app only needs:
/// * [WordForgeDependencies] (repositories, analytics, audio),
/// * [WordForgeEntryPage] (the screen to open), and
/// * [WordForgeEmblem] for its menus.
///
/// Everything else (engine, content, progression, Flame runtime) is internal
/// and has no dependency on the host app, so the module can be extracted into
/// a standalone game.
library;

export 'data/asset_word_forge_content_repository.dart';
export 'data/audioplayers_word_forge_audio.dart';
export 'data/dio_word_forge_cloud.dart';
export 'data/local_word_forge_save_repository.dart';
export 'data/synced_word_forge_save_repository.dart';
export 'domain/repositories/word_forge_cloud.dart';
export 'domain/repositories/word_forge_repositories.dart';
export 'domain/services/word_forge_analytics.dart';
export 'domain/services/word_forge_audio.dart';
export 'presentation/pages/word_forge_entry_page.dart';
export 'presentation/widgets/word_forge_emblem.dart';
export 'presentation/widgets/word_forge_fade_transition.dart';
export 'word_forge_module.dart';
