import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:reg_page/reg_page.dart' show StringsDownloadService;

import '../utils/app_strings.dart';

/// Summary of how much of the server note-sample pack is present on disk.
class AudioLibraryStatus {
  final bool isComplete;
  final int totalBanks;
  final int installedBanks;

  const AudioLibraryStatus({
    required this.isComplete,
    required this.totalBanks,
    required this.installedBanks,
  });
}

/// Download + verification helper for the Fretboard Trainer note-sample pack
/// (`mt-fretboard-trainer`, folder `audio`). The pack is small so it downloads
/// in a single request — no chunking — but we add a real structural check so a
/// missing or half-extracted pack is detected and re-downloaded instead of the
/// old "any one mp3 exists = done" gate.
class AudioPackService {
  /// Rotating "while you wait" lines for the first-run download dialog. Content
  /// only — presentation/timing live in the shared `JhgRotatingTips` element.
  static const List<String> downloadTips = [
    'Knowing the notes on the neck unlocks the whole fretboard.',
    'Start on one string, then add the next when it feels easy.',
    'Say each note out loud as you find it.',
    'A few minutes a day and the neck starts to feel like home.',
    'Learn the fret dots first, then fill in the notes between.',
    'The low and high E strings share the same notes. Learn one, get one free.',
    'Do not rush. Finding notes quickly comes with time.',
    'Soon you will spot any note without even thinking.',
  ];

  /// The six per-string sample banks that make up a complete pack. Each must be
  /// present AND non-empty for the library to count as installed.
  static const List<String> _stringBanks = [
    'audio/str_1',
    'audio/str_2',
    'audio/str_3',
    'audio/str_4',
    'audio/str_5',
    'audio/str_6',
  ];

  static Future<bool> verifyPack(String assetsRoot) async {
    if (kIsWeb) return true;
    for (final bank in _stringBanks) {
      if (!await _hasAudioIn(Directory('$assetsRoot/$bank'))) return false;
    }
    return true;
  }

  static Future<bool> _hasAudioIn(Directory dir) async {
    if (!await dir.exists()) return false;
    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) {
          final p = e.path.toLowerCase();
          if ((p.endsWith('.mp3') || p.endsWith('.wav')) &&
              await e.length() > 0) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Ensures the pack is present and verified; downloads (or repairs) otherwise.
  static Future<bool> ensureAudioPack({
    bool force = false,
    BuildContext? context,
  }) async {
    if (kIsWeb) return true;
    return StringsDownloadService().isStringsDownloaded(
      AppStrings.appName,
      packVersion: 1,
      packValidator: verifyPack,
      force: force,
      tips: downloadTips,
      context: context,
    );
  }

  static Future<AudioLibraryStatus> getLibraryStatus() async {
    const total = 6;
    if (kIsWeb) {
      return const AudioLibraryStatus(
          isComplete: true, totalBanks: total, installedBanks: total);
    }
    if (StringsDownloadService().dir == null) {
      await StringsDownloadService().init();
    }
    final base = StringsDownloadService().assetsPath;
    if (base == null) {
      return const AudioLibraryStatus(
          isComplete: false, totalBanks: total, installedBanks: 0);
    }
    int installed = 0;
    for (final bank in _stringBanks) {
      if (await _hasAudioIn(Directory('$base/$bank'))) installed++;
    }
    return AudioLibraryStatus(
      isComplete: installed == _stringBanks.length,
      totalBanks: _stringBanks.length,
      installedBanks: installed,
    );
  }
}
