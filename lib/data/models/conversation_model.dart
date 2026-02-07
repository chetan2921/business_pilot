// Conversation models for multi-turn AI chat

/// Role of a message sender
enum MessageRole {
  user,
  assistant,
  system;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'AI Assistant';
      case MessageRole.system:
        return 'System';
    }
  }
}

/// A single chat message
class ChatMessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a user message
  factory ChatMessageModel.user(
    String content, {
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      metadata: metadata,
    );
  }

  /// Create an assistant message
  factory ChatMessageModel.assistant(
    String content, {
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      metadata: metadata,
    );
  }

  /// Create a system message
  factory ChatMessageModel.system(String content) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.system,
      content: content,
    );
  }

  /// Time ago formatter
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

/// A conversation session containing multiple messages
class ConversationModel {
  final String id;
  final String userId;
  final String? title;
  final List<ChatMessageModel> messages;
  final Map<String, dynamic> context;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.userId,
    this.title,
    this.messages = const [],
    this.context = const {},
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ConversationModel.fromSupabase(Map<String, dynamic> row) {
    final messagesJson = row['messages'] as List? ?? [];
    return ConversationModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String?,
      messages: messagesJson
          .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      context: (row['context'] as Map<String, dynamic>?) ?? {},
      isArchived: row['is_archived'] as bool? ?? false,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'context': context,
      'is_archived': isArchived,
    };
  }

  /// Create a new empty conversation
  factory ConversationModel.create(String userId) {
    return ConversationModel(id: '', userId: userId, messages: []);
  }

  /// Add a message to the conversation
  ConversationModel addMessage(ChatMessageModel message) {
    return ConversationModel(
      id: id,
      userId: userId,
      title: title,
      messages: [...messages, message],
      context: context,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Update context
  ConversationModel withContext(Map<String, dynamic> newContext) {
    return ConversationModel(
      id: id,
      userId: userId,
      title: title,
      messages: messages,
      context: {...context, ...newContext},
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a title from the first user message
  String get generatedTitle {
    if (title != null && title!.isNotEmpty) return title!;
    final firstUserMsg = messages.firstWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => ChatMessageModel.user('New Conversation'),
    );
    final content = firstUserMsg.content;
    return content.length > 40 ? '${content.substring(0, 40)}...' : content;
  }

  /// Get last message preview
  String? get lastMessagePreview {
    if (messages.isEmpty) return null;
    final last = messages.last;
    return last.content.length > 50
        ? '${last.content.substring(0, 50)}...'
        : last.content;
  }

  /// Message count
  int get messageCount => messages.length;

  /// Get recent context for AI (last N messages)
  List<ChatMessageModel> getRecentContext({int maxMessages = 10}) {
    if (messages.length <= maxMessages) return messages;
    return messages.sublist(messages.length - maxMessages);
  }
}
