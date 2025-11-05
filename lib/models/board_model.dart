import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';

class BoardModel {
  int? id;
  int? string;
  int? fret;
  String? note;
  String? fretSound;
  final AudioPlayer player;
  bool _isDisposed = false;

  BoardModel({
    required this.id,
    required this.string,
    required this.fret,
    required this.note,
    required this.fretSound,
  }) : player = AudioPlayer() {
    _initializePlayer();
  }

  // Initialize player settings and asset
  Future<void> _initializePlayer() async {
    try {
      await player.setVolume(1);
    } catch (e) {
      print("Error initializing player: $e");
    }
  }

  // Method to play the sound
  Future<void> playSound() async {
    if (_isDisposed) return;

    try {
      if (player.playing) {
        await player.stop();
      }

      if (kIsWeb) {
        await player.setAsset("web/$fretSound");
      } else {
        await player.setFilePath(Utils.getAsset(fretSound!).path);
      }

      await player.play();
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  // Method to dispose of the audio player
  Future<void> dispose() async {
    if (!_isDisposed) {
      try {
        await player.stop();
        await player.dispose();
        _isDisposed = true;
      } catch (e) {
        print("Error disposing player: $e");
      }
    }
  }
}
