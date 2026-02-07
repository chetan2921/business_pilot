import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/conversation_model.dart';
import '../../data/services/conversation_service.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Conversation Service provider
final conversationServiceProvider = Provider<ConversationService>((ref) {
  return ConversationService.instance;
});

// ============================================================
// CONVERSATION PROVIDERS
// ============================================================

/// All conversations list
final conversationsProvider = FutureProvider<List<ConversationModel>>((
  ref,
) async {
  final service = ref.watch(conversationServiceProvider);
  return service.getConversations();
});

/// Current active conversation
final currentConversationProvider =
    StateNotifierProvider<CurrentConversationNotifier, ConversationState>((
      ref,
    ) {
      final service = ref.watch(conversationServiceProvider);
      return CurrentConversationNotifier(service);
    });

/// Conversation state
class ConversationState {
  final ConversationModel? conversation;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ConversationState({
    this.conversation,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ConversationState copyWith({
    ConversationModel? conversation,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ConversationState(
      conversation: conversation ?? this.conversation,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }

  bool get hasConversation => conversation != null;
  List<ChatMessageModel> get messages => conversation?.messages ?? [];
}

/// Notifier for managing current conversation
class CurrentConversationNotifier extends StateNotifier<ConversationState> {
  final ConversationService _service;

  CurrentConversationNotifier(this._service) : super(const ConversationState());

  /// Start a new conversation
  Future<void> startNewConversation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversation = await _service.createConversation();
      state = state.copyWith(conversation: conversation, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load an existing conversation
  Future<void> loadConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversation = await _service.getConversation(id);
      state = state.copyWith(conversation: conversation, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a message in the current conversation
  Future<void> sendMessage(String message) async {
    if (!state.hasConversation) {
      // Auto-create a conversation if none exists
      await startNewConversation();
    }

    if (!state.hasConversation) return;

    // Optimistically add user message
    final userMsg = ChatMessageModel.user(message);
    state = state.copyWith(
      conversation: state.conversation!.addMessage(userMsg),
      isSending: true,
      error: null,
    );

    try {
      final updatedConversation = await _service.sendMessage(
        state.conversation!.id,
        message,
      );
      state = state.copyWith(
        conversation: updatedConversation,
        isSending: false,
      );
    } catch (e) {
      // Remove the optimistically added message on error
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  /// Clear current conversation
  void clearConversation() {
    state = const ConversationState();
  }

  /// Archive current conversation
  Future<void> archiveCurrentConversation() async {
    if (!state.hasConversation) return;
    await _service.archiveConversation(state.conversation!.id);
    state = const ConversationState();
  }
}

// ============================================================
// CONVERSATION HISTORY PROVIDER
// ============================================================

/// Provider for conversation history sidebar
final conversationHistoryProvider = FutureProvider<List<ConversationModel>>((
  ref,
) async {
  final service = ref.watch(conversationServiceProvider);
  return service.getConversations(limit: 50);
});

/// Search conversations
final conversationSearchProvider =
    FutureProvider.family<List<ConversationModel>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final service = ref.watch(conversationServiceProvider);
      return service.searchConversations(query);
    });
