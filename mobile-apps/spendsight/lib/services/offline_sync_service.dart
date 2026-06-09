import 'dart:async';
import '../models/expense.dart';

/// Service to handle offline storage and sync
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  // In-memory queue for pending expenses (replace with Hive/SQLite in production)
  final List<Expense> _pendingQueue = [];
  final List<Expense> _syncedExpenses = [];
  
  // Stream controller for sync status updates
  final _syncStatusController = StreamController<SyncStatusUpdate>.broadcast();
  Stream<SyncStatusUpdate> get syncStatusStream => _syncStatusController.stream;

  // Connectivity simulation (replace with connectivity_plus in production)
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Save expense locally (offline-first)
  Future<Expense> saveExpenseLocally(Expense expense) async {
    final savedExpense = expense.copyWith(
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
    
    _pendingQueue.add(savedExpense);
    
    // Notify listeners
    _syncStatusController.add(SyncStatusUpdate(
      expenseId: savedExpense.id,
      status: SyncStatus.pending,
      message: 'Saved locally',
    ));

    // Try to sync immediately if online
    if (_isOnline) {
      _trySyncExpense(savedExpense);
    }

    return savedExpense;
  }

  /// Get all expenses (pending + synced)
  List<Expense> getAllExpenses() {
    return [..._pendingQueue, ..._syncedExpenses]
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get pending (unsynced) expenses
  List<Expense> getPendingExpenses() => List.unmodifiable(_pendingQueue);

  /// Get pending count
  int get pendingCount => _pendingQueue.length;

  /// Simulate connectivity change
  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (online) {
      syncPendingExpenses();
    }
  }

  /// Sync all pending expenses
  Future<void> syncPendingExpenses() async {
    if (!_isOnline || _pendingQueue.isEmpty) return;

    final toSync = List<Expense>.from(_pendingQueue);
    
    for (final expense in toSync) {
      await _trySyncExpense(expense);
    }
  }

  /// Try to sync a single expense
  Future<bool> _trySyncExpense(Expense expense) async {
    try {
      // Simulate network delay (replace with actual API call)
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Simulate successful sync
      _pendingQueue.removeWhere((e) => e.id == expense.id);
      
      final syncedExpense = expense.copyWith(
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      );
      _syncedExpenses.add(syncedExpense);

      _syncStatusController.add(SyncStatusUpdate(
        expenseId: expense.id,
        status: SyncStatus.synced,
        message: 'Synced successfully',
      ));

      return true;
    } catch (e) {
      _syncStatusController.add(SyncStatusUpdate(
        expenseId: expense.id,
        status: SyncStatus.failed,
        message: 'Sync failed: $e',
      ));
      return false;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    _pendingQueue.removeWhere((e) => e.id == id);
    _syncedExpenses.removeWhere((e) => e.id == id);
  }

  /// Update an expense
  Future<Expense> updateExpense(Expense expense) async {
    await deleteExpense(expense.id);
    return saveExpenseLocally(expense.copyWith(
      syncStatus: SyncStatus.pending,
    ));
  }

  void dispose() {
    _syncStatusController.close();
  }
}

/// Sync status update for stream
class SyncStatusUpdate {
  final String expenseId;
  final SyncStatus status;
  final String message;

  SyncStatusUpdate({
    required this.expenseId,
    required this.status,
    required this.message,
  });
}
