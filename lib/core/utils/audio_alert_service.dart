import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioAlertService {
  static final AudioAlertService _instance = AudioAlertService._internal();
  factory AudioAlertService() => _instance;
  AudioAlertService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isMuted = false;
  Timer? _loopTimer;

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;

  void init() {
    try {
      _player = AudioPlayer();
      _player?.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('[AudioAlertService] init error: $e');
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted && _isPlaying) {
      stopRingtone();
    }
  }

  /// Start repeating order ringtone (rings every 3.5s until stopped)
  Future<void> startRingtone() async {
    if (_isMuted || _isPlaying) return;

    _isPlaying = true;
    _playChime();

    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!_isPlaying || _isMuted) {
        timer.cancel();
        return;
      }
      _playChime();
    });
  }

  /// Stop repeating ringtone
  Future<void> stopRingtone() async {
    _isPlaying = false;
    _loopTimer?.cancel();
    _loopTimer = null;
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('[AudioAlertService] stop error: $e');
    }
  }

  /// Play a single chime (for preview or manual test)
  Future<void> playSingleChime() async {
    await _playChime();
  }

  Future<void> _playChime() async {
    try {
      if (_player == null) init();
      await _player?.stop();
      await _player?.play(AssetSource('sounds/order_alert.wav'), volume: 1.0);
    } catch (e) {
      debugPrint('[AudioAlertService] playChime error: $e');
    }
  }

  void dispose() {
    stopRingtone();
    _player?.dispose();
    _player = null;
  }
}
