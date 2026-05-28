import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class FretSoundPlayer {
  FretSoundPlayer(this.assetPath);

  static web.AudioContext? _context;
  static web.GainNode? _gainNode;
  static final Map<String, Future<web.AudioBuffer>> _bufferCache = {};

  final String assetPath;
  Future<web.AudioBuffer>? _loadFuture;
  bool _isDisposed = false;

  static web.AudioContext get _audioContext {
    final existingContext = _context;
    if (existingContext != null) {
      return existingContext;
    }

    final context = web.AudioContext(
      web.AudioContextOptions(latencyHint: 'interactive'.toJS),
    );
    final gainNode = context.createGain();
    gainNode.gain.value = 1;
    gainNode.connect(context.destination);

    _context = context;
    _gainNode = gainNode;
    return context;
  }

  Future<void> preload() async {
    _loadFuture ??= _bufferCache.putIfAbsent(assetPath, () {
      return _loadBuffer(assetPath);
    });
    await _loadFuture;
  }

  Future<void> play() async {
    if (_isDisposed) {
      return;
    }

    try {
      final context = _audioContext;
      if (context.state == 'suspended') {
        await context.resume().toDart;
      }

      _loadFuture ??= _bufferCache.putIfAbsent(assetPath, () {
        return _loadBuffer(assetPath);
      });

      final buffer = await _loadFuture!;
      final source = context.createBufferSource();
      source.buffer = buffer;
      source.connect(_gainNode ?? context.destination);
      source.start(0);
    } catch (e) {
      debugPrint('Error playing web sound: $e');
      _loadFuture = null;
      _bufferCache.remove(assetPath);
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
  }

  static Future<web.AudioBuffer> _loadBuffer(String assetPath) async {
    final context = _audioContext;
    final response = await web.window
        .fetch(Uri.encodeFull('assets/web/$assetPath').toJS)
        .toDart;

    if (!response.ok) {
      throw StateError(
        'Failed to fetch audio asset $assetPath (${response.status})',
      );
    }

    final data = await response.arrayBuffer().toDart;
    return context.decodeAudioData(data).toDart;
  }
}
