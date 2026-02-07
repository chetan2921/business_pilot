import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Service for handling voice input using speech-to-text
class VoiceService {
  VoiceService._();
  static final VoiceService _instance = VoiceService._();
  static VoiceService get instance => _instance;

  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastError = '';

  // Callbacks
  Function(String)? _onResult;
  Function(String)? _onError;
  Function(double)? _onSoundLevel;
  Function()? _onListeningComplete;

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Last error message
  String get lastError => _lastError;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: false,
      );
      return _isInitialized;
    } catch (e) {
      _lastError = 'Failed to initialize speech recognition: $e';
      return false;
    }
  }

  /// Start listening for speech input
  Future<bool> startListening({
    required Function(String transcription) onResult,
    Function(String error)? onError,
    Function(double soundLevel)? onSoundLevel,
    Function()? onComplete,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return false;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _onResult = onResult;
    _onError = onError;
    _onSoundLevel = onSoundLevel;
    _onListeningComplete = onComplete;

    try {
      _isListening = await _speech.listen(
        onResult: _handleResult,
        onSoundLevelChange: _handleSoundLevel,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      return _isListening;
    } catch (e) {
      _lastError = 'Failed to start listening: $e';
      _onError?.call(_lastError);
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _onListeningComplete?.call();
    } catch (e) {
      _lastError = 'Failed to stop listening: $e';
    }
  }

  /// Cancel listening without saving
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
    } catch (e) {
      _lastError = 'Failed to cancel listening: $e';
    }
  }

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return _speech.locales();
  }

  /// Get system default locale
  Future<String?> getSystemLocale() async {
    if (!_isInitialized) await initialize();
    final locale = await _speech.systemLocale();
    return locale?.localeId;
  }

  // Private handlers
  void _handleResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      _onResult?.call(result.recognizedWords);
    }

    if (result.finalResult) {
      _isListening = false;
      _onListeningComplete?.call();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
    _isListening = false;
    _onError?.call(error.errorMsg);
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _onListeningComplete?.call();
    }
  }

  void _handleSoundLevel(double level) {
    _onSoundLevel?.call(level);
  }

  /// Dispose of resources
  void dispose() {
    _speech.stop();
    _isListening = false;
    _onResult = null;
    _onError = null;
    _onSoundLevel = null;
    _onListeningComplete = null;
  }
}

/// Command parser for interpreting voice input
class VoiceCommandParser {
  /// Parse voice input and determine intent
  static VoiceCommand parse(String input) {
    final lowerInput = input.toLowerCase().trim();

    // Navigation commands
    if (_matchesAny(lowerInput, ['go to', 'open', 'show me', 'navigate to'])) {
      if (_matchesAny(lowerInput, ['dashboard', 'home'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/dashboard');
      }
      if (_matchesAny(lowerInput, ['invoice', 'invoices'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/invoices');
      }
      if (_matchesAny(lowerInput, ['expense', 'expenses'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/expenses');
      }
      if (_matchesAny(lowerInput, ['customer', 'customers'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/customers');
      }
      if (_matchesAny(lowerInput, ['inventory', 'products', 'stock'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/inventory');
      }
      if (_matchesAny(lowerInput, ['report', 'reports', 'analytics'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/reports');
      }
      if (_matchesAny(lowerInput, ['ai', 'assistant', 'chat'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/ai');
      }
      if (_matchesAny(lowerInput, ['settings'])) {
        return VoiceCommand(type: CommandType.navigate, target: '/settings');
      }
    }

    // Action commands
    if (_matchesAny(lowerInput, ['create', 'new', 'add'])) {
      if (_matchesAny(lowerInput, ['invoice'])) {
        return VoiceCommand(type: CommandType.action, action: 'create_invoice');
      }
      if (_matchesAny(lowerInput, ['expense'])) {
        return VoiceCommand(type: CommandType.action, action: 'create_expense');
      }
      if (_matchesAny(lowerInput, ['customer'])) {
        return VoiceCommand(
          type: CommandType.action,
          action: 'create_customer',
        );
      }
      if (_matchesAny(lowerInput, ['product'])) {
        return VoiceCommand(type: CommandType.action, action: 'create_product');
      }
    }

    // Search commands
    if (_matchesAny(lowerInput, ['search', 'find', 'look for'])) {
      // Extract search query
      final query = lowerInput
          .replaceAll(RegExp(r'(search|find|look for)\s*'), '')
          .trim();
      return VoiceCommand(type: CommandType.search, query: query);
    }

    // If no specific command, treat as chat input
    return VoiceCommand(type: CommandType.chat, query: input);
  }

  static bool _matchesAny(String input, List<String> patterns) {
    return patterns.any((pattern) => input.contains(pattern));
  }
}

/// Voice command types
enum CommandType { navigate, action, search, chat }

/// Parsed voice command
class VoiceCommand {
  final CommandType type;
  final String? target;
  final String? action;
  final String? query;

  VoiceCommand({required this.type, this.target, this.action, this.query});

  @override
  String toString() {
    return 'VoiceCommand(type: $type, target: $target, action: $action, query: $query)';
  }
}
