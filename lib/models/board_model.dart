import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';

class BoardModel {
  int? id;
  int? string;
  int? fret;
  String? note;
  String? fretSound;
  AudioPlayer player; // Make it non-nullable

  BoardModel({
    required this.id,
    required this.string,
    required this.fret,
    required this.note,
    required this.fretSound,
  }) : player = AudioPlayer() { // Initialize the AudioPlayer for each instance
    _initializePlayer();
  }

  // Initialize player settings and asset
  void _initializePlayer() async {
    player.setVolume(1);
  }

  // Method to play the sound
  Future<void> playSound() async {
    try {
      if (player.playing) {
         player.stop(); // Stop if it's currently playing
      }
      if (kIsWeb) {
         player.setAsset("web/$fretSound");
      } else {
        await player.setFilePath(Utils.getAsset(fretSound!).path);
      }
       player.play(); // Play the audio
    } catch (e) {
      print("Error playing sound: $e");
    }
  }
}
