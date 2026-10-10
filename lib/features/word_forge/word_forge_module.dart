import 'domain/repositories/word_forge_repositories.dart';
import 'domain/sandbox/sandbox_progression.dart';
import 'domain/services/word_forge_analytics.dart';
import 'domain/services/word_forge_audio.dart';

/// The only things Word Forge needs from its host. The Ustadia app builds
/// one in its service locator; a standalone game would build its own.
class WordForgeDependencies {
  final WordForgeContentRepository contentRepository;
  final WordForgeSaveRepository saveRepository;
  final WordForgeAnalytics analytics;

  /// Creates a fresh audio service per Word Forge session (disposed on exit).
  final WordForgeAudio Function() audioFactory;
  final SandboxProgression progression;

  const WordForgeDependencies({
    required this.contentRepository,
    required this.saveRepository,
    this.analytics = const NoopWordForgeAnalytics(),
    required this.audioFactory,
    this.progression = const SandboxProgression(),
  });
}
