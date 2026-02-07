import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/communication_log_model.dart';
import '../../../data/models/customer_reminder_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../data/services/communication_log_service.dart';
import '../../../data/services/customer_reminder_service.dart';
import '../../../data/services/ai_customer_service.dart';

/// Customer detail screen with tabs for overview, purchases, communications, reminders
class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CustomerModel? _customer;
  bool _isLoading = true;
  CustomerInsightsSummary? _insights;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final customer = await CustomerService.instance.getCustomerById(
        widget.customerId,
      );
      if (customer != null) {
        final insights = await AiCustomerService.instance.getCustomerInsights(
          customer,
        );
        setState(() {
          _customer = customer;
          _insights = insights;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCustomer(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCustomer),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Overview'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Purchases'),
            Tab(icon: Icon(Icons.chat), text: 'Comms'),
            Tab(icon: Icon(Icons.alarm), text: 'Reminders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(customer: _customer!, insights: _insights),
          _PurchasesTab(customerId: widget.customerId),
          _CommunicationsTab(
            customerId: widget.customerId,
            customer: _customer!,
          ),
          _RemindersTab(customerId: widget.customerId, customer: _customer!),
        ],
      ),
    );
  }

  void _editCustomer(BuildContext context) {
    // Navigate to edit screen
    context.push('/edit-customer/${widget.customerId}');
  }
}

// ============================================================
// OVERVIEW TAB
// ============================================================

class _OverviewTab extends StatelessWidget {
  final CustomerModel customer;
  final CustomerInsightsSummary? insights;

  const _OverviewTab({required this.customer, this.insights});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          customer.initials,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    customer.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    customer.segment.label,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (customer.companyName != null)
                              Text(
                                customer.companyName!,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Contact info
                  if (customer.email != null)
                    _InfoRow(icon: Icons.email, label: customer.email!),
                  if (customer.phone != null)
                    _InfoRow(icon: Icons.phone, label: customer.phone!),
                  if (customer.address != null)
                    _InfoRow(icon: Icons.location_on, label: customer.address!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Spent',
                  value: currencyFormat.format(customer.totalSpent),
                  icon: Icons.account_balance_wallet,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Last Purchase',
                  value: customer.lastPurchaseDate != null
                      ? '${customer.daysSinceLastPurchase}d ago'
                      : 'Never',
                  icon: Icons.shopping_bag,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Communications',
                  value: '${insights?.totalCommunications ?? 0}',
                  icon: Icons.chat_bubble,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Pending Reminders',
                  value: '${insights?.pendingReminders ?? 0}',
                  icon: Icons.alarm,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Insights Card
          if (insights != null) _AiInsightsCard(insights: insights!),

          // Tags
          if (customer.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Tags',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: customer.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: colorScheme.secondaryContainer,
                    ),
                  )
                  .toList(),
            ),
          ],

          // Notes
          if (customer.notes != null && customer.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMd),
                child: Text(customer.notes!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightsCard extends StatelessWidget {
  final CustomerInsightsSummary insights;

  const _AiInsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final churnRisk = insights.churnRisk;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Churn risk
            Row(
              children: [
                Text(churnRisk.riskEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Churn Risk: ${churnRisk.riskLabel}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Score: ${churnRisk.riskScore}/100',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Health: ${insights.healthScore}%',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (insights.nextBestActions.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Recommended Actions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...insights.nextBestActions
                  .take(3)
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(action.icon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              action.priority.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PURCHASES TAB
// ============================================================

class _PurchasesTab extends StatefulWidget {
  final String customerId;

  const _PurchasesTab({required this.customerId});

  @override
  State<_PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends State<_PurchasesTab> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final purchases = await CustomerService.instance
          .getCustomerPurchaseHistory(widget.customerId);
      setState(() => _purchases = purchases);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('No purchase history'),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        final purchase = _purchases[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.receipt, color: colorScheme.primary),
            ),
            title: Text(purchase['invoice_number'] ?? 'Invoice'),
            subtitle: Text(
              purchase['issue_date']?.toString().substring(0, 10) ?? '',
            ),
            trailing: Text(
              currencyFormat.format(purchase['total'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // View invoice details
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// COMMUNICATIONS TAB
// ============================================================

class _CommunicationsTab extends StatefulWidget {
  final String customerId;
  final CustomerModel customer;

  const _CommunicationsTab({required this.customerId, required this.customer});

  @override
  State<_CommunicationsTab> createState() => _CommunicationsTabState();
}

class _CommunicationsTabState extends State<_CommunicationsTab> {
  List<CommunicationLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await CommunicationLogService.instance.getLogsForCustomer(
        widget.customerId,
      );
      setState(() => _logs = logs);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No communication history'),
                  const SizedBox(height: 8),
                  const Text('Add your first note or log'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              log.type.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.subject ?? log.type.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(log.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log.direction.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(log.content, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCommunication(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Future<void> _addCommunication(BuildContext context) async {
    final result = await showModalBottomSheet<CommunicationLogModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddCommunicationSheet(
        customerId: widget.customerId,
        customer: widget.customer,
      ),
    );
    if (result != null) {
      _loadLogs();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}

class _AddCommunicationSheet extends StatefulWidget {
  final String customerId;
  final CustomerModel customer;

  const _AddCommunicationSheet({
    required this.customerId,
    required this.customer,
  });

  @override
  State<_AddCommunicationSheet> createState() => _AddCommunicationSheetState();
}

class _AddCommunicationSheetState extends State<_AddCommunicationSheet> {
  CommunicationType _selectedType = CommunicationType.note;
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Communication',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Type selector
          Wrap(
            spacing: 8,
            children: CommunicationType.values
                .map(
                  (type) => ChoiceChip(
                    label: Text(type.label),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final log = await CommunicationLogService.instance.createLog(
        CommunicationLogModel(
          id: '',
          userId: '',
          customerId: widget.customerId,
          type: _selectedType,
          subject: _subjectController.text.isNotEmpty
              ? _subjectController.text
              : null,
          content: _contentController.text,
        ),
      );
      if (mounted) Navigator.of(context).pop(log);
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

// ============================================================
// REMINDERS TAB
// ============================================================

class _RemindersTab extends StatefulWidget {
  final String customerId;
  final CustomerModel customer;

  const _RemindersTab({required this.customerId, required this.customer});

  @override
  State<_RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<_RemindersTab> {
  List<CustomerReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await CustomerReminderService.instance
          .getRemindersForCustomer(widget.customerId);
      setState(() => _reminders = reminders);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No reminders set'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Card(
                  color: reminder.isCompleted
                      ? Colors.grey[100]
                      : reminder.isOverdue
                      ? Colors.red[50]
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: reminder.isCompleted
                          ? Colors.grey[300]
                          : reminder.isOverdue
                          ? Colors.red[100]
                          : colorScheme.primaryContainer,
                      child: Text(
                        reminder.reminderType.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(reminder.reminderDate),
                      style: TextStyle(
                        color: reminder.isOverdue ? Colors.red : null,
                      ),
                    ),
                    trailing: reminder.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => _completeReminder(reminder.id),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Future<void> _completeReminder(String id) async {
    await CustomerReminderService.instance.completeReminder(id);
    _loadReminders();
  }

  Future<void> _addReminder(BuildContext context) async {
    final result = await showModalBottomSheet<CustomerReminderModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddReminderSheet(customerId: widget.customerId),
    );
    if (result != null) {
      _loadReminders();
    }
  }
}

class _AddReminderSheet extends StatefulWidget {
  final String customerId;

  const _AddReminderSheet({required this.customerId});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  ReminderType _selectedType = ReminderType.followUp;
  final _titleController = TextEditingController();
  DateTime _reminderDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Reminder',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Type selector
          Wrap(
            spacing: 8,
            children: ReminderType.values
                .map(
                  (type) => ChoiceChip(
                    label: Text(type.label),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Reminder Date'),
            subtitle: Text(
              DateFormat('MMM d, yyyy • h:mm a').format(_reminderDate),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _reminderDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_reminderDate),
                );
                if (time != null) {
                  setState(() {
                    _reminderDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final reminder = await CustomerReminderService.instance.createReminder(
        CustomerReminderModel(
          id: '',
          userId: '',
          customerId: widget.customerId,
          title: _titleController.text,
          reminderDate: _reminderDate,
          reminderType: _selectedType,
        ),
      );
      if (mounted) Navigator.of(context).pop(reminder);
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
