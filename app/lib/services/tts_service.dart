import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] so pages can speak/stop text without
/// each managing its own engine. Exposes a [speaking] notifier for the
/// shared play/stop button state.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<String?> speakingText = ValueNotifier<String?>(null);

  bool _available = true;

  /// Engines like the web SpeechSynthesis API are async to start; calling
  /// speak before ready is fine, the platform queues it.
  Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() => speakingText.value = null);
      _tts.setCancelHandler(() => speakingText.value = null);
    } catch (_) {
      _available = false;
    }
  }

  bool get isAvailable => _available;

  bool isSpeaking(String text) => speakingText.value == text;

  /// Toggles speech for [text]. If [text] is already being spoken, stops it.
  Future<void> toggle(String text) async {
    if (text.trim().isEmpty) return;
    if (isSpeaking(text)) {
      await stop();
      return;
    }
    await stop();
    try {
      speakingText.value = text;
      await _tts.speak(text);
    } catch (_) {
      speakingText.value = null;
      _available = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Engine may not be ready; ignore.
    }
    speakingText.value = null;
  }
}
