import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  List<Transaction> get expenses =>
      _transactions.where((t) => t.isExpense).toList();
  
  List<Transaction> get incomes =>
      _transactions.where((t) => !t.isExpense).toList();

  double get totalIncome =>
      incomes.fold(0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      expenses.fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  // Get transactions for current month
  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return _transactions.where((t) {
      return t.date.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          t.date.isBefore(lastDay.add(const Duration(days: 1)));
    }).toList();
  }

  double get currentMonthIncome =>
      currentMonthTransactions
          .where((t) => !t.isExpense)
          .fold(0, (sum, t) => sum + t.amount);

  double get currentMonthExpense =>
      currentMonthTransactions
          .where((t) => t.isExpense)
          .fold(0, (sum, t) => sum + t.amount);

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await DatabaseHelper.instance.readAllTransactions();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  Map<String, double> getCategoryExpenses() {
    final categoryMap = <String, double>{};
    for (var transaction in currentMonthTransactions.where((t) => t.isExpense)) {
      categoryMap[transaction.category] = 
          (categoryMap[transaction.category] ?? 0) + transaction.amount;
    }
    return categoryMap;
  }
}

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _budgets = await DatabaseHelper.instance.readAllBudgets();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBudget(Budget budget) async {
    await DatabaseHelper.instance.createBudget(budget);
    await loadBudgets();
  }

  Future<void> updateBudget(Budget budget) async {
    await DatabaseHelper.instance.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await DatabaseHelper.instance.deleteBudget(id);
    await loadBudgets();
  }
}
