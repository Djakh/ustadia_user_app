import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/content/word_forge_content.dart';
import '../domain/repositories/word_forge_repositories.dart';
import '../word_forge_assets.dart';
import 'content_parser.dart';

/// Loads bundled JSON content once and caches the validated catalog.
class AssetWordForgeContentRepository implements WordForgeContentRepository {
  final AssetBundle? _bundle;
  final ContentParser parser;
  Future<WordForgeContent>? _cache;

  AssetWordForgeContentRepository({AssetBundle? bundle, this.parser = const ContentParser()})
      : _bundle = bundle;

  @override
  Future<WordForgeContent> load() => _cache ??= _load();

  Future<WordForgeContent> _load() async {
    final bundle = _bundle ?? rootBundle;
    final files = await Future.wait([
      bundle.loadString(WordForgeAssets.words),
      bundle.loadString(WordForgeAssets.runes),
      bundle.loadString(WordForgeAssets.incantations),
      bundle.loadString(WordForgeAssets.enemies),
      bundle.loadString(WordForgeAssets.battles),
      bundle.loadString(WordForgeAssets.regions),
      bundle.loadString(WordForgeAssets.combat),
    ]);
    final content = await compute(
      _parse,
      ContentDocuments(
        words: files[0],
        runes: files[1],
        incantations: files[2],
        enemies: files[3],
        battles: files[4],
        regions: files[5],
        combat: files[6],
      ),
    );
    if (kDebugMode) {
      for (final issue in content.issues) {
        debugPrint('[WordForge content] $issue');
      }
    }
    return content;
  }

  static WordForgeContent _parse(ContentDocuments documents) => const ContentParser().parse(documents);
}
