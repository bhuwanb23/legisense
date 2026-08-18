import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps [SpeechToText] for the chat mic. Handles permission + init lazily
/// and streams partial transcripts to a callback.
class SpeechInputService {
  SpeechInputService._();

  static final SpeechInputService instance = SpeechInputService._();

  final SpeechToText _speech = SpeechToText();
  final ValueNotifier<bool> listening = ValueNotifier<bool>(false);

  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  /// Requests permission and initializes the recognizer. Returns whether
  /// speech recognition is available on this device.
  Future<bool> init() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize();
    } catch (_) {
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  /// Starts listening. [onPartial] is called with each transcript update.
  /// Returns false if the engine is unavailable.
  Future<bool> listen({
    required void Function(String text) onPartial,
  }) async {
    if (!await init() || _speech.isListening) return false;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult res) {
          onPartial(res.recognizedWords);
          if (!res.finalResult) return;
          listening.value = false;
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          localeId: 'en_US',
        ),
      );
      listening.value = true;
      return true;
    } catch (_) {
      listening.value = false;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Already stopped.
    }
    listening.value = false;
  }

  void dispose() {
    stop();
  }
}
