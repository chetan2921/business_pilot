import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/conversation_model.dart';
import 'ai_analytics_service.dart';
import 'analytics_service.dart';

/// Service for managing AI conversations with context
class ConversationService {
  ConversationService._();
  static final ConversationService _instance = ConversationService._();
  static ConversationService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  final _analyticsService = AnalyticsService.instance;
  final _aiAnalyticsService = AiAnalyticsService.instance;

  /// Get all conversations for current user
  Future<List<ConversationModel>> getConversations({
    bool includeArchived = false,
    int limit = 20,
  }) async {
    PostgrestFilterBuilder query = _client
        .from('conversation_history')
        .select();

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final response = await query
        .order('updated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) => ConversationModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get a specific conversation
  Future<ConversationModel?> getConversation(String id) async {
    final response = await _client
        .from('conversation_history')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ConversationModel.fromSupabase(response);
  }

  /// Create a new conversation
  Future<ConversationModel> createConversation({String? title}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('conversation_history')
        .insert({
          'user_id': userId,
          'title': title,
          'messages': [],
          'context': {},
        })
        .select()
        .single();

    return ConversationModel.fromSupabase(response);
  }

  /// Add message to conversation and get AI response
  Future<ConversationModel> sendMessage(
    String conversationId,
    String userMessage,
  ) async {
    // Get current conversation
    var conversation = await getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    // Add user message
    final userMsg = ChatMessageModel.user(userMessage);
    conversation = conversation.addMessage(userMsg);

    // Generate AI response with context
    final aiResponse = await _generateContextAwareResponse(
      userMessage,
      conversation.getRecentContext(),
      conversation.context,
    );

    // Add AI response
    final assistantMsg = ChatMessageModel.assistant(aiResponse);
    conversation = conversation.addMessage(assistantMsg);

    // Update title if first message
    String? newTitle = conversation.title;
    if (conversation.messages.length == 2 && newTitle == null) {
      newTitle = _generateTitle(userMessage);
    }

    // Save to database
    await _client
        .from('conversation_history')
        .update({
          'messages': conversation.messages.map((m) => m.toJson()).toList(),
          'title': newTitle,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    return ConversationModel(
      id: conversation.id,
      userId: conversation.userId,
      title: newTitle,
      messages: conversation.messages,
      context: conversation.context,
      isArchived: conversation.isArchived,
      createdAt: conversation.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate context-aware AI response
  Future<String> _generateContextAwareResponse(
    String query,
    List<ChatMessageModel> recentMessages,
    Map<String, dynamic> context,
  ) async {
    final lowerQuery = query.toLowerCase();

    // Build context from conversation history
    final conversationContext = recentMessages
        .map((m) => '${m.role.name}: ${m.content}')
        .join('\n');

    // Check for data-related queries and fetch real data
    if (_isAnalyticsQuery(lowerQuery)) {
      return await _handleAnalyticsQuery(lowerQuery, conversationContext);
    }

    if (_isBusinessHealthQuery(lowerQuery)) {
      return await _handleBusinessHealthQuery();
    }

    if (_isInvoiceQuery(lowerQuery)) {
      return _handleInvoiceQuery(lowerQuery, conversationContext);
    }

    if (_isExpenseQuery(lowerQuery)) {
      return _handleExpenseQuery(lowerQuery, conversationContext);
    }

    if (_isFollowUpQuery(lowerQuery, recentMessages)) {
      return _handleFollowUpQuery(lowerQuery, recentMessages);
    }

    // Default contextual response
    return _generateDefaultResponse(query, conversationContext);
  }

  bool _isAnalyticsQuery(String query) {
    return query.contains('revenue') ||
        query.contains('sales') ||
        query.contains('trend') ||
        query.contains('profit') ||
        query.contains('performance');
  }

  bool _isBusinessHealthQuery(String query) {
    return query.contains('health') ||
        query.contains('how is my business') ||
        query.contains('business doing') ||
        query.contains('overview');
  }

  bool _isInvoiceQuery(String query) {
    return query.contains('invoice') || query.contains('bill');
  }

  bool _isExpenseQuery(String query) {
    return query.contains('expense') ||
        query.contains('spent') ||
        query.contains('spending');
  }

  bool _isFollowUpQuery(String query, List<ChatMessageModel> history) {
    if (history.isEmpty) return false;
    return query.contains('more') ||
        query.contains('explain') ||
        query.contains('tell me more') ||
        query.contains('what about') ||
        query.contains('and') ||
        query.length < 20; // Short responses often are follow-ups
  }

  Future<String> _handleAnalyticsQuery(String query, String context) async {
    try {
      final trend = await _analyticsService.getRevenueTrend();
      final direction = trend.isPositive ? 'up' : 'down';
      final changeStr = trend.changePercent.abs().toStringAsFixed(1);

      return "📊 **Revenue Analysis**\n\n"
          "Your revenue is **$direction $changeStr%** compared to the previous period.\n\n"
          "• Current period: ₹${trend.currentPeriodRevenue.toStringAsFixed(0)}\n"
          "• Previous period: ₹${trend.previousPeriodRevenue.toStringAsFixed(0)}\n\n"
          "${trend.isPositive ? '🎉 Great progress!' : '💡 Consider running a promotion to boost sales.'}\n\n"
          "Would you like more details on top products or customer trends?";
    } catch (e) {
      return "I'd love to show you revenue analytics, but I couldn't fetch the data right now. "
          "Please try again in a moment.";
    }
  }

  Future<String> _handleBusinessHealthQuery() async {
    try {
      final health = await _aiAnalyticsService.calculateBusinessHealth();
      final emoji = _getHealthEmoji(health.status);

      return "$emoji **Business Health: ${health.status.name.toUpperCase()}**\n\n"
          "Overall Score: **${health.overallScore}/100**\n\n"
          "**Breakdown:**\n"
          "• Revenue: ${health.revenueScore.toStringAsFixed(0)}%\n"
          "• Profit Margins: ${health.profitScore.toStringAsFixed(0)}%\n"
          "• Inventory: ${health.inventoryScore.toStringAsFixed(0)}%\n"
          "• Cash Flow: ${health.cashFlowScore.toStringAsFixed(0)}%\n\n"
          "${health.recommendations.isNotEmpty ? '**Recommendations:**\n${health.recommendations.map((r) => '• $r').join('\n')}' : 'Everything looks good!'}";
    } catch (e) {
      return "I'm having trouble calculating your business health right now. "
          "Please check back in a moment.";
    }
  }

  String _handleInvoiceQuery(String query, String context) {
    if (query.contains('create') || query.contains('new')) {
      return "📄 **Creating a New Invoice**\n\n"
          "To create an invoice:\n"
          "1. Go to the **Invoices** tab\n"
          "2. Tap the **+** button\n"
          "3. Select a customer\n"
          "4. Add line items\n"
          "5. Send or save as draft\n\n"
          "Would you like me to guide you through any specific step?";
    }

    if (query.contains('overdue') || query.contains('unpaid')) {
      return "⚠️ **Overdue Invoices**\n\n"
          "To view overdue invoices:\n"
          "1. Go to **Invoices** tab\n"
          "2. Filter by **Overdue** status\n\n"
          "I can also set up automatic follow-up reminders. "
          "Would you like me to enable that?";
    }

    return "📄 I can help you with invoices! You can:\n\n"
        "• **Create** new invoices for customers\n"
        "• **Track** invoice status (draft, sent, paid, overdue)\n"
        "• **Send** invoices via email or share\n"
        "• **Mark** invoices as paid\n\n"
        "What would you like to do?";
  }

  String _handleExpenseQuery(String query, String context) {
    if (query.contains('add') || query.contains('record')) {
      return "💸 **Recording an Expense**\n\n"
          "You can add an expense by:\n"
          "1. Going to the **Expenses** tab\n"
          "2. Tapping **Add Expense**\n"
          "3. Fill in the details or **scan a receipt**\n\n"
          "The receipt scanner will automatically extract the amount and date!";
    }

    return "💸 I can help track your expenses! Options include:\n\n"
        "• **Add** expenses manually\n"
        "• **Scan** receipts for automatic entry\n"
        "• **View** expense reports by category\n"
        "• **Export** expense data\n\n"
        "What would you like to do?";
  }

  String _handleFollowUpQuery(String query, List<ChatMessageModel> history) {
    // Get the last assistant message for context
    final lastAssistant = history.lastWhere(
      (m) => m.role == MessageRole.assistant,
      orElse: () => ChatMessageModel.assistant(''),
    );

    if (lastAssistant.content.contains('Revenue') ||
        lastAssistant.content.contains('revenue')) {
      return "📈 **More on Revenue**\n\n"
          "Here's what you can explore:\n"
          "• **Top products** - see which items sell best\n"
          "• **Customer analysis** - understand buying patterns\n"
          "• **Seasonal trends** - plan for peak times\n\n"
          "Which would you like to explore?";
    }

    if (lastAssistant.content.contains('Invoice') ||
        lastAssistant.content.contains('invoice')) {
      return "📄 **More Invoice Options**\n\n"
          "• **Templates** - customize invoice appearance\n"
          "• **Recurring** - set up automatic invoicing\n"
          "• **Reminders** - automate payment follow-ups\n\n"
          "What interests you?";
    }

    return "I'm here to help! Based on our conversation, would you like to:\n\n"
        "• Explore **analytics** and reports\n"
        "• Manage **invoices** or **expenses**\n"
        "• Check **inventory** status\n"
        "• Review **customer** insights\n\n"
        "Just let me know!";
  }

  String _generateDefaultResponse(String query, String context) {
    return "I'm your BusinessPilot AI assistant! I can help you with:\n\n"
        "📊 **Analytics** - Revenue, profits, business health\n"
        "📄 **Invoices** - Create, send, track payments\n"
        "💸 **Expenses** - Record, categorize, report\n"
        "📦 **Inventory** - Stock levels, alerts\n"
        "👥 **Customers** - Manage, analyze, engage\n\n"
        "Try asking:\n"
        "• \"How is my business doing?\"\n"
        "• \"Show me revenue trends\"\n"
        "• \"Help me create an invoice\"";
  }

  String _generateTitle(String firstMessage) {
    if (firstMessage.length <= 40) return firstMessage;
    // Find a good break point
    final words = firstMessage.split(' ');
    var title = '';
    for (final word in words) {
      if ((title + word).length > 35) break;
      title += '$word ';
    }
    return '${title.trim()}...';
  }

  String _getHealthEmoji(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return '🌟';
      case HealthStatus.good:
        return '✅';
      case HealthStatus.fair:
        return '⚠️';
      case HealthStatus.poor:
        return '🔴';
      case HealthStatus.critical:
        return '🚨';
    }
  }

  /// Archive a conversation
  Future<void> archiveConversation(String id) async {
    await _client
        .from('conversation_history')
        .update({'is_archived': true})
        .eq('id', id);
  }

  /// Delete a conversation
  Future<void> deleteConversation(String id) async {
    await _client.from('conversation_history').delete().eq('id', id);
  }

  /// Search conversations
  Future<List<ConversationModel>> searchConversations(String query) async {
    final response = await _client
        .from('conversation_history')
        .select()
        .ilike('title', '%$query%')
        .order('updated_at', ascending: false)
        .limit(10);

    return (response as List)
        .map(
          (row) => ConversationModel.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }
}
