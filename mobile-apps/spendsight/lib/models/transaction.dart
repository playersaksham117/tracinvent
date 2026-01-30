import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class Transaction {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final IconData icon;

  Transaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
  });
  
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.food;
      case 'transportation':
      case 'transport':
        return AppColors.transport;
      case 'shopping':
        return AppColors.shopping;
      case 'bills':
        return AppColors.bills;
      case 'health':
        return AppColors.health;
      case 'entertainment':
        return AppColors.entertainment;
      case 'income':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
