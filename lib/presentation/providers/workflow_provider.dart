import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/workflow_service.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Workflow Service provider
final workflowServiceProvider = Provider<WorkflowService>((ref) {
  return WorkflowService.instance;
});

// ============================================================
// WORKFLOW STATE
// ============================================================

/// Workflow state for managing settings and runs
class WorkflowState {
  final WorkflowSettings settings;
  final List<WorkflowRun> recentRuns;
  final bool isLoading;
  final String? error;
  final WorkflowRun? lastRun;

  const WorkflowState({
    this.settings = const WorkflowSettings(),
    this.recentRuns = const [],
    this.isLoading = false,
    this.error,
    this.lastRun,
  });

  WorkflowState copyWith({
    WorkflowSettings? settings,
    List<WorkflowRun>? recentRuns,
    bool? isLoading,
    String? error,
    WorkflowRun? lastRun,
  }) {
    return WorkflowState(
      settings: settings ?? this.settings,
      recentRuns: recentRuns ?? this.recentRuns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRun: lastRun ?? this.lastRun,
    );
  }
}

// ============================================================
// WORKFLOW NOTIFIER
// ============================================================

/// State notifier for workflow management
class WorkflowNotifier extends StateNotifier<WorkflowState> {
  final WorkflowService _service;

  WorkflowNotifier(this._service) : super(const WorkflowState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = await _service.loadSettings();
      final runs = await _service.getWorkflowHistory();
      state = state.copyWith(
        settings: settings,
        recentRuns: runs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update workflow settings
  Future<void> updateSettings(WorkflowSettings settings) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.saveSettings(settings);
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggle a specific workflow setting
  Future<void> toggleWorkflow(WorkflowType type, bool enabled) async {
    final currentSettings = state.settings;
    WorkflowSettings newSettings;

    switch (type) {
      case WorkflowType.invoiceFollowUp:
        newSettings = WorkflowSettings(
          invoiceFollowUpEnabled: enabled,
          invoiceFollowUpDays: currentSettings.invoiceFollowUpDays,
          weeklyReviewEnabled: currentSettings.weeklyReviewEnabled,
          weeklyReviewDay: currentSettings.weeklyReviewDay,
          lowStockAlertEnabled: currentSettings.lowStockAlertEnabled,
          lowStockThreshold: currentSettings.lowStockThreshold,
        );
      case WorkflowType.weeklyBusinessReview:
        newSettings = WorkflowSettings(
          invoiceFollowUpEnabled: currentSettings.invoiceFollowUpEnabled,
          invoiceFollowUpDays: currentSettings.invoiceFollowUpDays,
          weeklyReviewEnabled: enabled,
          weeklyReviewDay: currentSettings.weeklyReviewDay,
          lowStockAlertEnabled: currentSettings.lowStockAlertEnabled,
          lowStockThreshold: currentSettings.lowStockThreshold,
        );
      case WorkflowType.lowStockAlert:
        newSettings = WorkflowSettings(
          invoiceFollowUpEnabled: currentSettings.invoiceFollowUpEnabled,
          invoiceFollowUpDays: currentSettings.invoiceFollowUpDays,
          weeklyReviewEnabled: currentSettings.weeklyReviewEnabled,
          weeklyReviewDay: currentSettings.weeklyReviewDay,
          lowStockAlertEnabled: enabled,
          lowStockThreshold: currentSettings.lowStockThreshold,
        );
      case WorkflowType.customerFollowUp:
        // Not yet implemented
        return;
    }

    await updateSettings(newSettings);
  }

  /// Run a workflow manually
  Future<void> runWorkflow(WorkflowType type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final run = await _service.triggerWorkflow(type);
      final runs = [run, ...state.recentRuns.take(19)];
      state = state.copyWith(recentRuns: runs, lastRun: run, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh workflow history
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = await _service.loadSettings();
      final runs = await _service.getWorkflowHistory();
      state = state.copyWith(
        settings: settings,
        recentRuns: runs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Main workflow state provider
final workflowProvider = StateNotifierProvider<WorkflowNotifier, WorkflowState>(
  (ref) {
    final service = ref.watch(workflowServiceProvider);
    return WorkflowNotifier(service);
  },
);

/// Workflow settings provider
final workflowSettingsProvider = Provider<WorkflowSettings>((ref) {
  return ref.watch(workflowProvider).settings;
});

/// Recent workflow runs provider
final recentWorkflowRunsProvider = Provider<List<WorkflowRun>>((ref) {
  return ref.watch(workflowProvider).recentRuns;
});

/// Is workflow loading
final workflowLoadingProvider = Provider<bool>((ref) {
  return ref.watch(workflowProvider).isLoading;
});
