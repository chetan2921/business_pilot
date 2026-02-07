import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/voice_service.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Voice Service provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService.instance;
});

// ============================================================
// VOICE STATE
// ============================================================

/// Voice input state
class VoiceInputState {
  final bool isAvailable;
  final bool isListening;
  final String transcription;
  final double soundLevel;
  final String? error;

  const VoiceInputState({
    this.isAvailable = false,
    this.isListening = false,
    this.transcription = '',
    this.soundLevel = 0,
    this.error,
  });

  VoiceInputState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? transcription,
    double? soundLevel,
    String? error,
  }) {
    return VoiceInputState(
      isAvailable: isAvailable ?? this.isAvailable,
      isListening: isListening ?? this.isListening,
      transcription: transcription ?? this.transcription,
      soundLevel: soundLevel ?? this.soundLevel,
      error: error,
    );
  }

  bool get hasError => error != null;
  bool get hasTranscription => transcription.isNotEmpty;
}

// ============================================================
// VOICE NOTIFIER
// ============================================================

/// State notifier for voice input
class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final VoiceService _voiceService;

  VoiceInputNotifier(this._voiceService) : super(const VoiceInputState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _voiceService.initialize();
    state = state.copyWith(isAvailable: available);
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!state.isAvailable) {
      state = state.copyWith(error: 'Voice input not available');
      return;
    }

    state = state.copyWith(isListening: true, transcription: '', error: null);

    await _voiceService.startListening(
      onResult: (transcription) {
        state = state.copyWith(transcription: transcription);
      },
      onError: (error) {
        state = state.copyWith(isListening: false, error: error);
      },
      onSoundLevel: (level) {
        state = state.copyWith(soundLevel: level);
      },
      onComplete: () {
        state = state.copyWith(isListening: false);
      },
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _voiceService.stopListening();
    state = state.copyWith(isListening: false);
  }

  /// Cancel and clear transcription
  Future<void> cancelListening() async {
    await _voiceService.cancelListening();
    state = state.copyWith(isListening: false, transcription: '');
  }

  /// Clear transcription
  void clearTranscription() {
    state = state.copyWith(transcription: '');
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Parse the current transcription as a command
  VoiceCommand parseCommand() {
    return VoiceCommandParser.parse(state.transcription);
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Voice input state provider
final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
      final service = ref.watch(voiceServiceProvider);
      return VoiceInputNotifier(service);
    });

/// Check if voice is available
final voiceAvailableProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).isAvailable;
});

/// Check if currently listening
final isListeningProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).isListening;
});

/// Current transcription
final transcriptionProvider = Provider<String>((ref) {
  return ref.watch(voiceInputProvider).transcription;
});
