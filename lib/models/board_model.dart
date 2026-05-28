import 'package:flutter/foundation.dart';
import 'package:fretboard/services/fret_sound_player.dart';

class BoardModel {
  int? id;
  int? string;
  int? fret;
  String? note;
  String? fretSound;
  final FretSoundPlayer player;
  bool _isDisposed = false;

  BoardModel({
    required this.id,
    required this.string,
    required this.fret,
    required this.note,
    required this.fretSound,
  }) : player = FretSoundPlayer(fretSound!) {
    if (kIsWeb) {
      preloadSound();
    }
  }

  Future<void> preloadSound() async {
    if (_isDisposed) return;

    try {
      await player.preload();
    } catch (e) {
      debugPrint("Error preloading player: $e");
    }
  }

  Future<void> playSound() async {
    if (_isDisposed) return;

    try {
      await player.play();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> dispose() async {
    if (!_isDisposed) {
      try {
        await player.dispose();
        _isDisposed = true;
      } catch (e) {
        debugPrint("Error disposing player: $e");
      }
    }
  }
}
