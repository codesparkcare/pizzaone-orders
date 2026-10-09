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

  // On web/iOS, audio requires a user interaction to unlock.
  // This flag tracks whether the audio context has been unlocked.
  bool _isWebAudioUnlocked = false;

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;

  void init() {
    try {
      _player = AudioPlayer();
      _player?.setReleaseMode(ReleaseMode.stop);

      // On Web, configure low latency mode for faster response
      if (kIsWeb) {
        _player?.setPlayerMode(PlayerMode.lowLatency);
      }
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

  /// Called from web JavaScript after first user interaction to unlock audio.
  /// This must be called before startRingtone() will work on iOS Safari.
  void markWebAudioUnlocked() {
    _isWebAudioUnlocked = true;
    debugPrint('[AudioAlertService] iOS/Web audio context unlocked ✅');
  }

  /// Start repeating order ringtone (rings every 3.5s until stopped)
  Future<void> startRingtone() async {
    if (_isMuted || _isPlaying) return;

    // On web/iOS, skip if audio context hasn't been unlocked yet
    // (audio unlock happens on first user touch via index.html JS)
    if (kIsWeb && !_isWebAudioUnlocked) {
      debugPrint('[AudioAlertService] iOS Web: audio not yet unlocked by user interaction, skipping chime');
      return;
    }

    _isPlaying = true;
    await _playChime();

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
    if (kIsWeb && !_isWebAudioUnlocked) {
      debugPrint('[AudioAlertService] Web: cannot play until user interacts with page first');
      return;
    }
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
