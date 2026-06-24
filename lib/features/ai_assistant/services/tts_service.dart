// lib/features/ai_assistant/services/tts_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  VoidCallback? _onComplete;

  TtsService() {
    _init();
  }

  bool get isSpeaking => _isSpeaking;

  void _init() {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      if (_onComplete != null) {
        _onComplete!();
      }
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
      debugPrint("TTS error: $message");
    });
  }

  Future<void> speak(String text, {double rate = 0.5, VoidCallback? onComplete}) async {
    _onComplete = onComplete;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }
}
