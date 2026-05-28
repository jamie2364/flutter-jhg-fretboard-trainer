import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';

class FretSoundPlayer {
  FretSoundPlayer(this.assetPath);

  final String assetPath;
  final AudioPlayer _player = AudioPlayer();
  Future<void>? _loadFuture;
  bool _isDisposed = false;

  Future<void> preload() => _loadFuture ??= _load();

  Future<void> _load() async {
    await _player.setVolume(1);
    await _player.setFilePath(Utils.getAsset(assetPath).path);
  }

  Future<void> play() async {
    if (_isDisposed) {
      return;
    }

    try {
      await preload();
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
      _loadFuture = null;
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    try {
      await _player.stop();
      await _player.dispose();
    } catch (e) {
      debugPrint('Error disposing player: $e');
    } finally {
      _isDisposed = true;
    }
  }
}
