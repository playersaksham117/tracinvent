import 'package:uuid/uuid.dart';

/// Budget type based on account
enum BudgetType {
  category,    // Individual - per category
  shared,      // Family - shared household
  member,      // Family - per member
  department,  // Business - per department
}

/// Budget period
enum BudgetPeriod {
  weekly,
  monthly,
  quarterly,
  yearly;

  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  int get days {
    switch (this) {
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.monthly:
        return 30;
      case BudgetPeriod.quarterly:
        return 90;
      case BudgetPeriod.yearly:
        return 365;
    }
  }
}

/// Alert threshold status
enum BudgetAlertStatus {
  safe,       // < 80%
  warning,    // >= 80% && < 100%
  exceeded,   // >= 100%
}

/// Budget model with alerts and progress tracking
class BudgetItem {
  final String id;
  final String name;
  final BudgetType type;
  final BudgetPeriod period;
  final double limit;
  final double spent;
  final String? category;
  final String? memberId;
  final String? memberName;
  final String? departmentId;
  final String? departmentName;
  final DateTime startDate;
  final DateTime endDate;
  final bool alertEnabled;
  final double alertThreshold; // Default 0.8 (80%)
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetItem({
    String? id,
    required this.name,
    required this.type,
    this.period = BudgetPeriod.monthly,
    required this.limit,
    this.spent = 0,
    this.category,
    this.memberId,
    this.memberName,
    this.departmentId,
    this.departmentName,
    DateTime? startDate,
    DateTime? endDate,
    this.alertEnabled = true,
    this.alertThreshold = 0.8,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now().add(Duration(days: period.days)),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate progress (0.0 to 1.0+)
  double get progress => limit > 0 ? spent / limit : 0;

  /// Calculate percentage (0 to 100+)
  double get percentage => progress * 100;

  /// Remaining budget
  double get remaining => limit - spent;

  /// Check if over budget
  bool get isOverBudget => spent > limit;

  /// Get alert status
  BudgetAlertStatus get alertStatus {
    if (progress >= 1.0) return BudgetAlertStatus.exceeded;
    if (progress >= alertThreshold) return BudgetAlertStatus.warning;
    return BudgetAlertStatus.safe;
  }

  /// Check if should show alert
  bool get shouldAlert => alertEnabled && alertStatus != BudgetAlertStatus.safe;

  /// Days remaining in period
  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays.clamp(0, period.days);
  }

  /// Daily budget remaining
  double get dailyBudgetRemaining {
    if (daysRemaining <= 0) return 0;
    return remaining / daysRemaining;
  }

  /// Copy with method
  BudgetItem copyWith({
    String? id,
    String? name,
    BudgetType? type,
    BudgetPeriod? period,
    double? limit,
    double? spent,
    String? category,
    String? memberId,
    String? memberName,
    String? departmentId,
    String? departmentName,
    DateTime? startDate,
    DateTime? endDate,
    bool? alertEnabled,
    double? alertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      period: period ?? this.period,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      category: category ?? this.category,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'period': period.name,
      'limit': limit,
      'spent': spent,
      'category': category,
      'memberId': memberId,
      'memberName': memberName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'alertEnabled': alertEnabled ? 1 : 0,
      'alertThreshold': alertThreshold,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map
  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'],
      name: map['name'],
      type: BudgetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BudgetType.category,
      ),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      limit: (map['limit'] as num).toDouble(),
      spent: (map['spent'] as num?)?.toDouble() ?? 0,
      category: map['category'],
      memberId: map['memberId'],
      memberName: map['memberName'],
      departmentId: map['departmentId'],
      departmentName: map['departmentName'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      alertEnabled: map['alertEnabled'] == 1,
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

/// Default expense categories with icons
class BudgetCategory {
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': '🍔', 'color': 0xFFFF9800},
    {'name': 'Transport', 'icon': '🚗', 'color': 0xFF2196F3},
    {'name': 'Shopping', 'icon': '🛍️', 'color': 0xFF9C27B0},
    {'name': 'Bills', 'icon': '📄', 'color': 0xFF009688},
    {'name': 'Health', 'icon': '🏥', 'color': 0xFFE91E63},
    {'name': 'Entertainment', 'icon': '🎬', 'color': 0xFF00BCD4},
    {'name': 'Groceries', 'icon': '🛒', 'color': 0xFF8BC34A},
    {'name': 'Education', 'icon': '📚', 'color': 0xFF3F51B5},
    {'name': 'Other', 'icon': '💰', 'color': 0xFF607D8B},
  ];

  static const List<Map<String, dynamic>> departments = [
    {'name': 'Operations', 'icon': '⚙️', 'color': 0xFF2196F3},
    {'name': 'Marketing', 'icon': '📢', 'color': 0xFFE91E63},
    {'name': 'Sales', 'icon': '💼', 'color': 0xFF4CAF50},
    {'name': 'HR', 'icon': '👥', 'color': 0xFF9C27B0},
    {'name': 'IT', 'icon': '💻', 'color': 0xFF00BCD4},
    {'name': 'Finance', 'icon': '💰', 'color': 0xFFFF9800},
    {'name': 'Admin', 'icon': '🏢', 'color': 0xFF607D8B},
  ];

  static const List<Map<String, dynamic>> familyMembers = [
    {'name': 'Self', 'icon': '👤', 'color': 0xFF2196F3},
    {'name': 'Spouse', 'icon': '👤', 'color': 0xFFE91E63},
    {'name': 'Child 1', 'icon': '👦', 'color': 0xFF4CAF50},
    {'name': 'Child 2', 'icon': '👧', 'color': 0xFF9C27B0},
    {'name': 'Parent', 'icon': '👴', 'color': 0xFFFF9800},
  ];
}
