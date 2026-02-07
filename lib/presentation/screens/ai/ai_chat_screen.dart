import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/conversation_model.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/voice_provider.dart';

/// AI Chat screen with multi-turn conversation support
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Start or load conversation on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(currentConversationProvider);
      if (!state.hasConversation) {
        ref.read(currentConversationProvider.notifier).startNewConversation();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref.read(currentConversationProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewConversation() {
    ref.read(currentConversationProvider.notifier).startNewConversation();
    Navigator.pop(context); // Close drawer
  }

  void _loadConversation(ConversationModel conversation) {
    ref
        .read(currentConversationProvider.notifier)
        .loadConversation(conversation.id);
    Navigator.pop(context); // Close drawer
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentConversationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Auto-scroll when new messages arrive
    ref.listen(currentConversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Conversation history',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.conversation?.generatedTitle ?? 'AI Assistant',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => ref
                .read(currentConversationProvider.notifier)
                .startNewConversation(),
            tooltip: 'New conversation',
          ),
        ],
      ),
      drawer: _ConversationHistoryDrawer(
        onNewConversation: _startNewConversation,
        onSelectConversation: _loadConversation,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Error banner
                if (state.error != null)
                  MaterialBanner(
                    content: Text(state.error!),
                    actions: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),

                // Chat messages
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppConstants.paddingMd),
                          itemCount:
                              state.messages.length + (state.isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.messages.length &&
                                state.isSending) {
                              return _buildTypingIndicator(context);
                            }
                            return _ChatBubble(message: state.messages[index]);
                          },
                        ),
                ),

                // Suggested prompts for empty state
                if (state.messages.isEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _SuggestedPrompt(
                          text: 'How is my business doing?',
                          onTap: () {
                            _messageController.text =
                                'How is my business doing?';
                            _sendMessage();
                          },
                        ),
                        _SuggestedPrompt(
                          text: 'Show revenue trends',
                          onTap: () {
                            _messageController.text = 'Show revenue trends';
                            _sendMessage();
                          },
                        ),
                        _SuggestedPrompt(
                          text: 'Help with invoices',
                          onTap: () {
                            _messageController.text = 'Help with invoices';
                            _sendMessage();
                          },
                        ),
                      ],
                    ),
                  ),

                // Input field
                _ChatInputField(
                  controller: _messageController,
                  isLoading: state.isSending,
                  onSend: _sendMessage,
                  onVoiceTap: _onVoiceTap,
                ),
              ],
            ),
    );
  }

  void _onVoiceTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoiceInputSheet(
        onTranscriptionComplete: (text) {
          Navigator.pop(context);
          if (text.isNotEmpty) {
            _messageController.text = text;
            _sendMessage();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hi! I\'m your AI assistant',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me about your business, analytics, or get help',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CONVERSATION HISTORY DRAWER
// ============================================================

class _ConversationHistoryDrawer extends ConsumerWidget {
  final VoidCallback onNewConversation;
  final Function(ConversationModel) onSelectConversation;

  const _ConversationHistoryDrawer({
    required this.onNewConversation,
    required this.onSelectConversation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(conversationHistoryProvider);
    final currentConversation = ref
        .watch(currentConversationProvider)
        .conversation;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: onNewConversation,
                    tooltip: 'New conversation',
                  ),
                ],
              ),
            ),

            // Conversation list
            Expanded(
              child: historyAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isSelected =
                          currentConversation?.id == conversation.id;

                      return ListTile(
                        selected: isSelected,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          conversation.generatedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${conversation.messageCount} messages',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => onSelectConversation(conversation),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAT INPUT FIELD
// ============================================================

class _ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;

  const _ChatInputField({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice input button
            IconButton(
              icon: Icon(Icons.mic_none, color: colorScheme.primary),
              onPressed: isLoading ? null : onVoiceTap,
              tooltip: 'Voice input',
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAT BUBBLE
// ============================================================

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timeAgo,
              style: TextStyle(
                fontSize: 10,
                color: isUser
                    ? colorScheme.onPrimary.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUGGESTED PROMPT
// ============================================================

class _SuggestedPrompt extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestedPrompt({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 16),
      child: ActionChip(label: Text(text), onPressed: onTap),
    );
  }
}

// ============================================================
// VOICE INPUT SHEET
// ============================================================

class _VoiceInputSheet extends ConsumerStatefulWidget {
  final Function(String) onTranscriptionComplete;

  const _VoiceInputSheet({required this.onTranscriptionComplete});

  @override
  ConsumerState<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<_VoiceInputSheet> {
  String _transcription = '';
  bool _isListening = false;
  double _soundLevel = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    setState(() {
      _isListening = true;
      _transcription = '';
      _error = null;
    });

    await voiceNotifier.startListening();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final voiceState = ref.watch(voiceInputProvider);

    // Update local state from provider
    if (voiceState.transcription != _transcription) {
      _transcription = voiceState.transcription;
    }
    if (voiceState.isListening != _isListening) {
      _isListening = voiceState.isListening;
    }
    if (voiceState.soundLevel != _soundLevel) {
      _soundLevel = voiceState.soundLevel;
    }
    if (voiceState.error != _error) {
      _error = voiceState.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Microphone indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80 + (_soundLevel * 2),
            height: 80 + (_soundLevel * 2),
            decoration: BoxDecoration(
              color: _isListening
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              size: 40,
              color: _isListening ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),

          // Status text
          Text(
            _isListening ? 'Listening...' : 'Tap microphone to speak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Transcription display
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _transcription.isEmpty
                  ? 'Your words will appear here...'
                  : _transcription,
              style: TextStyle(
                fontSize: 16,
                color: _transcription.isEmpty
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
                fontStyle: _transcription.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),

          // Error display
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(voiceInputProvider.notifier).cancelListening();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _transcription.isNotEmpty
                      ? () {
                          ref.read(voiceInputProvider.notifier).stopListening();
                          widget.onTranscriptionComplete(_transcription);
                        }
                      : null,
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
