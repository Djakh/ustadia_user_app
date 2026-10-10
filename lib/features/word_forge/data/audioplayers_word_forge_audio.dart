import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../domain/services/word_forge_audio.dart';
import '../word_forge_assets.dart';

/// Short sound effects through the app's existing audioplayers dependency.
///
/// * **Android** uses low-latency players (one shared `SoundPool`, sounds
///   decoded once into memory) with a fixed number of voices per sound that
///   are reused round-robin. The default `MediaPlayer` mode created a heavy
///   native player per overlapping sound; in busy fights that exhausted the
///   system's player limit, crashed the app and stalled frames. Voices also
///   skip audio focus, so our own overlapping sounds no longer pause each
///   other.
/// * **iOS and others** keep small `AudioPool`s, which work well there.
///
/// Identical sounds fired within [_minGap] are throttled, a sound whose asset
/// is missing is silently disabled, and the iOS audio session is never
/// touched so the rest of the app keeps its configuration.
class AudioplayersWordForgeAudio implements WordForgeAudio {
  static const _minGap = Duration(milliseconds: 45);

  /// Sounds that often overlap with themselves get a second voice.
  static const Set<WordForgeSfx> _busy = {
    WordForgeSfx.tap,
    WordForgeSfx.hit,
    WordForgeSfx.runeComplete,
    WordForgeSfx.fizzle,
    WordForgeSfx.criticalHit,
    WordForgeSfx.enemyImpact,
    WordForgeSfx.combo,
    WordForgeSfx.reward,
    WordForgeSfx.poisonTick,
  };

  static final AudioContext _androidContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  final bool _lowLatency = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final Map<WordForgeSfx, AudioPool> _pools = {};
  final Map<WordForgeSfx, _Voices> _voices = {};
  final Map<WordForgeSfx, DateTime> _lastPlayed = {};
  final AudioCache _cache = AudioCache(prefix: 'assets/');
  Future<void>? _loading;
  bool _paused = false;
  bool _disposed = false;

  @override
  bool muted = false;

  @override
  Future<void> preload() => _loading ??= _preload();

  Future<void> _preload() async {
    for (final sfx in WordForgeSfx.values) {
      if (_disposed) return;
      final source = AssetSource(WordForgeAssets.sfx(sfx));
      try {
        if (_lowLatency) {
          final players = <AudioPlayer>[];
          for (var i = 0; i < (_busy.contains(sfx) ? 2 : 1); i++) {
            players.add(await _createVoice(source));
          }
          if (_disposed) {
            for (final player in players) {
              unawaited(player.dispose());
            }
            return;
          }
          _voices[sfx] = _Voices(players);
        } else {
          _pools[sfx] = await AudioPool.create(
            source: source,
            maxPlayers: _busy.contains(sfx) ? 3 : 2,
            audioCache: _cache,
          );
        }
      } on Object catch (error) {
        if (kDebugMode) debugPrint('[WordForge audio] ${sfx.name} unavailable: $error');
      }
    }
  }

  Future<AudioPlayer> _createVoice(Source source) async {
    final player = AudioPlayer()..audioCache = _cache;
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setAudioContext(_androidContext);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(source);
    return player;
  }

  @override
  void play(WordForgeSfx sfx, {double volume = 1}) {
    if (muted || _paused || _disposed) return;
    final now = DateTime.now();
    final last = _lastPlayed[sfx];
    if (last != null && now.difference(last) < _minGap) return;
    final level = volume.clamp(0.0, 1.0);
    final voices = _voices[sfx];
    if (voices != null) {
      _lastPlayed[sfx] = now;
      unawaited(voices.play(level).then((_) {}, onError: (Object _) {}));
      return;
    }
    final pool = _pools[sfx];
    if (pool == null) return;
    _lastPlayed[sfx] = now;
    unawaited(pool.start(volume: level).then((_) {}, onError: (Object _) {}));
  }

  @override
  void pauseAll() => _paused = true;

  @override
  void resumeAll() => _paused = false;

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _loading;
    final pools = _pools.values.toList();
    final voices = _voices.values.toList();
    _pools.clear();
    _voices.clear();
    for (final pool in pools) {
      try {
        await pool.dispose();
      } on Object {
        // Disposal failures are harmless.
      }
    }
    for (final voice in voices) {
      await voice.dispose();
    }
    await _cache.clearAll();
  }
}

/// A fixed set of low-latency players for one sound, used round-robin.
/// Retriggering a voice restarts it instead of creating a new player.
class _Voices {
  final List<AudioPlayer> players;
  int _next = 0;

  _Voices(this.players);

  Future<void> play(double volume) async {
    final player = players[_next];
    _next = (_next + 1) % players.length;
    await player.stop();
    await player.setVolume(volume);
    await player.resume();
  }

  Future<void> dispose() async {
    for (final player in players) {
      try {
        await player.dispose();
      } on Object {
        // Disposal failures are harmless.
      }
    }
  }
}
