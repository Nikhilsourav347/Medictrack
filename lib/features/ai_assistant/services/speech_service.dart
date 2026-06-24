// lib/features/ai_assistant/services/speech_service.dart

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status changed: $status');
        },
        onError: (errorVal) {
          debugPrint('Speech error: ${errorVal.errorMsg} - permanent: ${errorVal.permanent}');
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String status)? onStatusChanged,
    VoidCallback? onError,
  }) async {
    if (!_isInitialized) {
      bool ok = await initSpeech();
      if (!ok) {
        if (onError != null) onError();
        return;
      }
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
