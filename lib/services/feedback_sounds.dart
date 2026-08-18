// services/feedback_sounds.dart
//
// Short answer-feedback SFX (correct / wrong), mirroring the Ear Training app.
// These are bundled assets played through just_audio — separate from the
// remote-loaded fret sounds. Each cue has its own preloaded player so a rapid
// answer streak doesn't cut off the previous cue.

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class FeedbackSounds {
  FeedbackSounds._();
  static final FeedbackSounds instance = FeedbackSounds._();

  final AudioPlayer _correct = AudioPlayer();
  final AudioPlayer _wrong = AudioPlayer();
  bool _ready = false;

  /// Preloads both cues into memory. Safe to call more than once.
  Future<void> init() async {
    if (_ready) return;
    try {
      await _correct.setAsset('assets/sounds/correct.wav');
      await _wrong.setAsset('assets/sounds/wrong.mp3');
      _ready = true;
    } catch (e) {
      debugPrint('FeedbackSounds init failed: $e');
    }
  }

  Future<void> playCorrect() => _play(_correct);
  Future<void> playWrong() => _play(_wrong);

  Future<void> _play(AudioPlayer p) async {
    try {
      if (!_ready) await init();
      await p.seek(Duration.zero);
      await p.play();
    } catch (e) {
      debugPrint('FeedbackSounds play failed: $e');
    }
  }
}
