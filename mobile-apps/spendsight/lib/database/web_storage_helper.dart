// Simple in-memory storage for web
class WebStorageHelper {
  static final List<Map<String, dynamic>> _transactions = [];
  static final List<Map<String, dynamic>> _budgets = [];

  static List<Map<String, dynamic>> getTransactions() {
    return List.from(_transactions);
  }

  static void addTransaction(Map<String, dynamic> transaction) {
    _transactions.add(transaction);
  }

  static void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t['id'] == id);
  }

  static List<Map<String, dynamic>> getBudgets() {
    return List.from(_budgets);
  }

  static void addBudget(Map<String, dynamic> budget) {
    _budgets.add(budget);
  }

  static void deleteBudget(String id) {
    _budgets.removeWhere((b) => b['id'] == id);
  }

  static void clear() {
    _transactions.clear();
    _budgets.clear();
  }
}
