enum AccountType {
  individual,
  family,
  business,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.individual:
        return 'Individual';
      case AccountType.family:
        return 'Family';
      case AccountType.business:
        return 'Business';
    }
  }

  String get description {
    switch (this) {
      case AccountType.individual:
        return 'Personal finance tracking';
      case AccountType.family:
        return 'Shared household expenses';
      case AccountType.business:
        return 'Business cash flow';
    }
  }
}
