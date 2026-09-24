import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool isListening = false;
  Function()? _onWakeWord;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('VoiceService error: ${val.errorMsg}'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            isListening = false;
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('VoiceService initialize failed: $e');
      return false;
    }
  }

  Future<void> startListening({required Function() onWakeWord}) async {
    _onWakeWord = onWakeWord;
    if (!_isAvailable) {
      final ok = await initialize();
      if (!ok) return;
    }

    try {
      isListening = true;
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          debugPrint('Voice recognized: $words');
          if (words.contains('start govia') ||
              words.contains('start go via') ||
              words.contains('hey govia') ||
              words.contains('govia emergency')) {
            HapticFeedback.heavyImpact();
            stopListening();
            _onWakeWord?.call();
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('VoiceService listen error: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      isListening = false;
      await _speech.stop();
    } catch (_) {}
  }
}
