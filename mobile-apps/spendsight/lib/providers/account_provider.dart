import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_type.dart';

class AccountProvider with ChangeNotifier {
  AccountType _accountType = AccountType.individual;
  String? _currentMember; // For family accounts

  AccountType get accountType => _accountType;
  String? get currentMember => _currentMember;

  Future<void> loadAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt('account_type') ?? 0;
    _accountType = AccountType.values[typeIndex];
    _currentMember = prefs.getString('current_member');
    notifyListeners();
  }

  Future<void> setAccountType(AccountType type) async {
    _accountType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('account_type', type.index);
    notifyListeners();
  }

  Future<void> setCurrentMember(String member) async {
    _currentMember = member;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_member', member);
    notifyListeners();
  }

  bool get isIndividual => _accountType == AccountType.individual;
  bool get isFamily => _accountType == AccountType.family;
  bool get isBusiness => _accountType == AccountType.business;
}
