class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? note;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.isExpense,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'isExpense': isExpense ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      isExpense: map['isExpense'] == 1,
    );
  }
}

class Budget {
  final String id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
