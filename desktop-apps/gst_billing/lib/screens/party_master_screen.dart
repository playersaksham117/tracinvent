import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ledger.dart';

void showSuccessToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showErrorToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

const Map<String, String> _accountHeadLabels = {
  'ASSETS': 'Assets',
  'LIABILITIES': 'Liabilities',
  'CAPITAL': 'Capital / Equity',
  'INCOME': 'Income',
  'EXPENSES': 'Expenses',
};

const Map<String, String> _accountHeadPurpose = {
  'ASSETS': 'Resources owned by the business.',
  'LIABILITIES': 'Obligations the business must pay.',
  'CAPITAL': 'Owner\'s interest in business.',
  'INCOME': 'Revenue earned by business.',
  'EXPENSES': 'Cost incurred to earn revenue.',
};

const Map<String, String> _accountHeadBehavior = {
  'ASSETS': 'Debit increases • Credit decreases',
  'LIABILITIES': 'Credit increases • Debit decreases',
  'CAPITAL': 'Credit increases • Debit decreases',
  'INCOME': 'Credit increases income',
  'EXPENSES': 'Debit increases expense',
};

const Map<String, List<MapEntry<String, List<String>>>> _accountSubGroups = {
  'ASSETS': [
    MapEntry('Current Assets', [
      'Cash in Hand',
      'Bank Accounts',
      'Sundry Debtors',
      'Loans & Advances Given',
      'Input GST (CGST/SGST/IGST)',
      'TDS Receivable',
      'Closing Stock',
    ]),
    MapEntry('Fixed Assets', [
      'Furniture & Fixtures',
      'Plant & Machinery',
      'Vehicles',
      'Computers',
      'Office Equipment',
      'Intangible Assets',
    ]),
    MapEntry('Investments', ['FDs', 'Shares', 'Mutual Funds']),
  ],
  'LIABILITIES': [
    MapEntry('Current Liabilities', [
      'Sundry Creditors',
      'Outstanding Expenses',
      'GST Payable',
      'TDS Payable',
      'Advances from Customers',
      'Provisions',
    ]),
    MapEntry('Loans', ['Secured Loans', 'Unsecured Loans']),
  ],
  'CAPITAL': [
    MapEntry('Capital / Equity', [
      'Capital Account',
      'Partner Capital',
      'Share Capital',
      'Reserves & Surplus',
      'Drawings',
    ]),
  ],
  'INCOME': [
    MapEntry('Income', [
      'Sales',
      'Service Income',
      'Other Income',
      'Interest Income',
      'Commission Income',
      'Discount Received',
    ]),
  ],
  'EXPENSES': [
    MapEntry('Direct Expenses', [
      'Purchase',
      'Freight Inward',
      'Manufacturing Cost',
    ]),
    MapEntry('Indirect Expenses', [
      'Salary',
      'Rent',
      'Electricity',
      'Internet',
      'Office Expenses',
      'Marketing',
      'Insurance',
      'Bank Charges',
      'Depreciation',
    ]),
  ],
};

const Set<String> _capitalSubGroupNames = {
  'Capital Account',
  'Partner Capital',
  'Share Capital',
  'Reserves & Surplus',
  'Drawings',
};

String _normalizeGroupKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class PartyMasterScreen extends StatefulWidget {
  const PartyMasterScreen({super.key});

  @override
  State<PartyMasterScreen> createState() => _PartyMasterScreenState();
}

class _PartyMasterScreenState extends State<PartyMasterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  List<Map<String, dynamic>> parties = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedPartyType = 'ALL';

  // View Ledgers tab
  List<Map<String, dynamic>> ledgerPartiesForView = [];
  List<LedgerGroup> ledgerGroupsForView = [];
  bool ledgersLoading = false;
  String selectedLedgerNature = 'ALL';
  int? selectedLedgerGroupFilter;
  String ledgerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _apiService = ApiService();
    _loadParties();
    _tabController.addListener(() {
      if (_tabController.index == 2 &&
          ledgerPartiesForView.isEmpty &&
          !ledgersLoading) {
        _loadLedgers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    try {
      setState(() => isLoading = true);
      final partyType = selectedPartyType == 'ALL' ? null : selectedPartyType;
      final data = await _apiService.getParties(
        partyType: partyType,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      setState(() {
        parties = data;
        isLoading = false;
      });
    } catch (e) {
      showErrorToast(context, 'Failed to load parties: $e');
      setState(() => isLoading = false);
    }
  }

  void _showPartyForm({Map<String, dynamic>? party}) {
    showDialog(
      context: context,
      builder: (dialogContext) => PartyFormDialog(
        apiService: _apiService,
        party: party,
        onSuccess: () {
          _loadParties();
          Navigator.pop(dialogContext);
          showSuccessToast(
            context,
            party == null
                ? 'Party created successfully'
                : 'Party updated successfully',
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int partyId, String partyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Party'),
        content: Text('Are you sure you want to deactivate $partyName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deactivateParty(
                  partyId,
                  reason: 'Deactivated from party master',
                );
                _loadParties();
                showSuccessToast(context, 'Party deactivated');
                Navigator.pop(context);
              } catch (e) {
                showErrorToast(context, 'Failed to deactivate party: $e');
              }
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Party / Firm'),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Parties'),
            Tab(icon: Icon(Icons.group_add), text: 'New Party'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'View Ledgers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPartiesList(),
          _buildNewPartyTab(),
          _buildViewLedgersTab(),
        ],
      ),
    );
  }

  Widget _buildPartiesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, GSTIN, phone...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => searchQuery = '');
                            _loadParties();
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                  _loadParties();
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedPartyType == 'ALL',
                      onSelected: (selected) {
                        setState(() => selectedPartyType = 'ALL');
                        _loadParties();
                      },
                    ),
                    ...[
                      'SUPPLIER',
                      'CUSTOMER',
                      'EMPLOYEE',
                      'BANK',
                      'OTHER',
                    ].map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: selectedPartyType == type,
                          onSelected: (selected) {
                            setState(() => selectedPartyType = type);
                            _loadParties();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : parties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No parties found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new party to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: parties.length,
                  itemBuilder: (context, index) {
                    final party = parties[index];
                    return _buildPartyCard(party);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPartyCard(Map<String, dynamic> party) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(party['name']![0].toUpperCase())),
        title: Text(party['name'] ?? 'N/A'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${party['party_type']} • ${party['phone'] ?? 'N/A'}'),
            if (party['gstin'] != null)
              Text(
                'GSTIN: ${party['gstin']}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showPartyForm(party: party),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    _showDeleteConfirmation(party['id'], party['name']),
                tooltip: 'Deactivate',
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.orange),
                onPressed: () => _showChangeHistory(party['id'], party['name']),
                tooltip: 'History',
              ),
            ],
          ),
        ),
        isThreeLine: true,
        onTap: () => _showPartyDetails(party),
      ),
    );
  }

  void _showPartyDetails(Map<String, dynamic> party) {
    showDialog(
      context: context,
      builder: (context) =>
          PartyDetailsDialog(party: party, apiService: _apiService),
    );
  }

  void _showChangeHistory(int partyId, String partyName) {
    showDialog(
      context: context,
      builder: (context) => PartyHistoryDialog(
        partyId: partyId,
        partyName: partyName,
        apiService: _apiService,
      ),
    );
  }

  Widget _buildNewPartyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PartyFormContent(
        apiService: _apiService,
        onSuccess: () {
          _loadParties();
          _tabController.animateTo(0);
          showSuccessToast(context, 'Party created successfully');
        },
      ),
    );
  }

  Future<void> _loadLedgers() async {
    setState(() => ledgersLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getLedgerGroups(),
        _apiService.getParties(
          search: ledgerSearchQuery.isEmpty ? null : ledgerSearchQuery,
        ),
      ]);
      setState(() {
        ledgerGroupsForView = results[0] as List<LedgerGroup>;
        final groupById = {for (final g in ledgerGroupsForView) g.id: g};
        ledgerPartiesForView = (results[1] as List<Map<String, dynamic>>).where(
          (p) {
            final groupIdVal = p['ledger_group_id'];
            int? groupId;
            if (groupIdVal is int) {
              groupId = groupIdVal;
            } else if (groupIdVal is double) {
              groupId = groupIdVal.toInt();
            } else if (groupIdVal is String) {
              groupId = int.tryParse(groupIdVal);
            }
            final group = groupId != null ? groupById[groupId] : null;
            if (group == null) return selectedLedgerNature == 'ALL';
            final head = _displayNature(group);
            if (selectedLedgerNature != 'ALL' && head != selectedLedgerNature) {
              return false;
            }
            if (selectedLedgerGroupFilter != null &&
                group.id != selectedLedgerGroupFilter) {
              return false;
            }
            return true;
          },
        ).toList();
        ledgersLoading = false;
      });
    } catch (e) {
      showErrorToast(context, 'Failed to load ledgers: $e');
      setState(() => ledgersLoading = false);
    }
  }

  String _displayNature(LedgerGroup g) {
    return _capitalSubGroupNames.contains(g.name)
        ? _accountHeadLabels['CAPITAL']!
        : _natureLabel(g.nature);
  }

  String _natureLabel(String n) {
    switch (n) {
      case 'ASSETS':
        return _accountHeadLabels['ASSETS']!;
      case 'LIABILITIES':
        return _accountHeadLabels['LIABILITIES']!;
      case 'INCOME':
        return _accountHeadLabels['INCOME']!;
      case 'EXPENSES':
        return _accountHeadLabels['EXPENSES']!;
      default:
        return n;
    }
  }

  Widget _buildViewLedgersTab() {
    if (ledgerGroupsForView.isEmpty && !ledgersLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLedgers());
    }
    final natureOrder = [
      _accountHeadLabels['ASSETS']!,
      _accountHeadLabels['LIABILITIES']!,
      _accountHeadLabels['CAPITAL']!,
      _accountHeadLabels['INCOME']!,
      _accountHeadLabels['EXPENSES']!,
    ];
    final Map<String, Map<String, List<Map<String, dynamic>>>> hierarchy = {};
    for (final n in natureOrder) hierarchy[n] = {};
    final groupById = {for (final g in ledgerGroupsForView) g.id: g};
    for (final party in ledgerPartiesForView) {
      final groupIdVal = party['ledger_group_id'];
      int? groupId;
      if (groupIdVal is int) {
        groupId = groupIdVal;
      } else if (groupIdVal is double) {
        groupId = groupIdVal.toInt();
      } else if (groupIdVal is String) {
        groupId = int.tryParse(groupIdVal);
      }
      final g = groupId != null ? groupById[groupId] : null;
      if (g == null) continue;
      final nature = _displayNature(g);
      hierarchy[nature] ??= {};
      hierarchy[nature]![g.name] ??= [];
      hierarchy[nature]![g.name]!.add(party);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedLedgerNature,
                      decoration: InputDecoration(
                        labelText: 'Nature of Account',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['ALL', ...natureOrder]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedLedgerNature = v ?? 'ALL';
                          _loadLedgers();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: selectedLedgerGroupFilter,
                      decoration: InputDecoration(
                        labelText: 'Group',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...ledgerGroupsForView.map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          selectedLedgerGroupFilter = v;
                          _loadLedgers();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search ledgers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (v) {
                  setState(() => ledgerSearchQuery = v);
                  _loadLedgers();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ledgersLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: natureOrder
                      .where(
                        (n) => (hierarchy[n]?.values ?? []).any(
                          (x) => x.isNotEmpty,
                        ),
                      )
                      .length,
                  itemBuilder: (context, idx) {
                    final nature = natureOrder
                        .where(
                          (n) => (hierarchy[n]?.values ?? []).any(
                            (x) => x.isNotEmpty,
                          ),
                        )
                        .elementAt(idx);
                    final groups = hierarchy[nature]!;
                    return ExpansionTile(
                      title: Text(
                        nature,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        for (final e in groups.entries)
                          if (e.value.isNotEmpty)
                            ExpansionTile(
                              title: Text(e.key),
                              children: e.value
                                  .map(
                                    (party) => ListTile(
                                      title: Text(
                                        party['name']?.toString() ?? 'N/A',
                                      ),
                                      subtitle: Text(
                                        '${party['party_type'] ?? 'OTHER'} • ${party['balance_type'] ?? 'DR'} ₹${((party['current_balance'] as num?) ?? (party['opening_balance'] as num?) ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// PARTY FORM DIALOG
// ============================================================================

class PartyFormDialog extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic>? party;
  final VoidCallback onSuccess;

  const PartyFormDialog({
    super.key,
    required this.apiService,
    this.party,
    required this.onSuccess,
  });

  @override
  State<PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<PartyFormDialog> {
  late PartyFormContent _formContent;

  @override
  void initState() {
    super.initState();
    _formContent = PartyFormContent(
      apiService: widget.apiService,
      party: widget.party,
      onSuccess: widget.onSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.party == null ? 'New Party' : 'Edit Party'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: _formContent,
      ),
    );
  }
}

// ============================================================================
// PARTY FORM CONTENT
// ============================================================================

class PartyFormContent extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic>? party;
  final VoidCallback onSuccess;

  const PartyFormContent({
    super.key,
    required this.apiService,
    this.party,
    required this.onSuccess,
  });

  @override
  State<PartyFormContent> createState() => _PartyFormContentState();
}

class _PartyFormContentState extends State<PartyFormContent> {
  late TextEditingController nameController;
  late TextEditingController contactPersonController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController websiteController;
  late TextEditingController gstinController;
  late TextEditingController panController;
  late TextEditingController tanController;
  late TextEditingController aadhaarController;
  late TextEditingController billingAddressController;
  late TextEditingController billingCityController;
  late TextEditingController billingPincodeController;
  late TextEditingController shippingAddressController;
  late TextEditingController shippingCityController;
  late TextEditingController shippingPincodeController;
  late TextEditingController creditLimitController;
  late TextEditingController creditDaysController;
  late TextEditingController openingBalanceController;

  String selectedPartyType = 'SUPPLIER';
  int? selectedLedgerGroupId;
  List<LedgerGroup> ledgerGroups = [];
  bool groupsLoading = true;
  String selectedBillingState = '';
  String selectedShippingState = '';
  String selectedGSTType = 'UNREGISTERED';
  String selectedBalanceType = 'DR';
  String selectedAccountHead = 'LIABILITIES';
  String? selectedSubGroup;
  bool isSubmitting = false;

  final List<String> states = [
    'AN',
    'AP',
    'AR',
    'AS',
    'BR',
    'CG',
    'CH',
    'CT',
    'DD',
    'DL',
    'DN',
    'GA',
    'GJ',
    'HR',
    'HP',
    'JK',
    'JH',
    'KA',
    'KL',
    'LA',
    'LD',
    'MH',
    'ML',
    'MN',
    'MZ',
    'NL',
    'OD',
    'OR',
    'PB',
    'PY',
    'RJ',
    'SK',
    'TG',
    'TR',
    'TN',
    'TR',
    'UT',
    'UP',
    'WB',
  ];

  static const _defaultGroupByType = {
    'SUPPLIER': 'Sundry Creditors',
    'CUSTOMER': 'Sundry Debtors',
    'EMPLOYEE': 'Loans & Advances Given',
    'BANK': 'Bank Accounts',
    'OTHER': 'Current Assets',
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadLedgerGroups();
  }

  Future<void> _loadLedgerGroups() async {
    try {
      final groups = await widget.apiService.getLedgerGroups();
      setState(() {
        ledgerGroups = groups;
        groupsLoading = false;
        if (selectedLedgerGroupId == null && groups.isNotEmpty) {
          _applyDefaultGroup();
        } else if (selectedLedgerGroupId != null) {
          LedgerGroup? current;
          for (final g in groups) {
            if (g.id == selectedLedgerGroupId) {
              current = g;
              break;
            }
          }
          if (current != null) {
            _syncAccountSelectionFromLedgerGroup(current);
          }
        }
      });
    } catch (_) {
      setState(() => groupsLoading = false);
    }
  }

  void _applyDefaultGroup() {
    final defaultName = _defaultGroupByType[selectedPartyType];
    if (defaultName == null || ledgerGroups.isEmpty) return;
    LedgerGroup? g = _findLedgerGroupByName(defaultName);
    g ??= ledgerGroups.first;
    selectedLedgerGroupId = g.id;
    _syncAccountSelectionFromLedgerGroup(g);
  }

  String _balanceTypeFromAccountHead(String accountHead) {
    return (accountHead == 'ASSETS' || accountHead == 'EXPENSES') ? 'DR' : 'CR';
  }

  String _accountHeadFromLedgerGroup(LedgerGroup group) {
    if (_capitalSubGroupNames.contains(group.name)) return 'CAPITAL';
    switch (group.nature) {
      case 'ASSETS':
        return 'ASSETS';
      case 'LIABILITIES':
        return 'LIABILITIES';
      case 'INCOME':
        return 'INCOME';
      case 'EXPENSES':
        return 'EXPENSES';
      default:
        return 'LIABILITIES';
    }
  }

  LedgerGroup? _findLedgerGroupByName(String subgroupName) {
    final target = _normalizeGroupKey(subgroupName);
    for (final g in ledgerGroups) {
      if (_normalizeGroupKey(g.name) == target) {
        return g;
      }
    }
    for (final g in ledgerGroups) {
      final normalizedName = _normalizeGroupKey(g.name);
      if (normalizedName.contains(target) || target.contains(normalizedName)) {
        return g;
      }
    }
    return null;
  }

  void _syncAccountSelectionFromLedgerGroup(LedgerGroup group) {
    final head = _accountHeadFromLedgerGroup(group);
    selectedAccountHead = head;
    selectedBalanceType = _balanceTypeFromAccountHead(head);
    final available = _availableSubGroupsForHead(
      head,
    ).map((e) => e.value).toSet();
    if (available.contains(group.name)) {
      selectedSubGroup = group.name;
      return;
    }
    selectedSubGroup = null;
  }

  void _tryResolveLedgerGroupFromSubGroup() {
    if (selectedSubGroup == null) return;
    final group = _findLedgerGroupByName(selectedSubGroup!);
    if (group == null) return;
    selectedLedgerGroupId = group.id;
    selectedAccountHead = _accountHeadFromLedgerGroup(group);
    selectedBalanceType = _balanceTypeFromAccountHead(selectedAccountHead);
  }

  List<MapEntry<String, String>> _availableSubGroupsForHead(
    String accountHead,
  ) {
    final sections = _accountSubGroups[accountHead] ?? const [];
    final output = <MapEntry<String, String>>[];
    for (final section in sections) {
      for (final subgroup in section.value) {
        output.add(MapEntry(section.key, subgroup));
      }
    }
    return output;
  }

  String _natureDisplay(String nature) {
    switch (nature) {
      case 'ASSETS':
        return _accountHeadLabels['ASSETS']!;
      case 'LIABILITIES':
        return _accountHeadLabels['LIABILITIES']!;
      case 'INCOME':
        return _accountHeadLabels['INCOME']!;
      case 'EXPENSES':
        return _accountHeadLabels['EXPENSES']!;
      default:
        return nature;
    }
  }

  void _initializeControllers() {
    final party = widget.party;
    nameController = TextEditingController(text: party?['name'] ?? '');
    contactPersonController = TextEditingController(
      text: party?['contact_person'] ?? '',
    );
    phoneController = TextEditingController(text: party?['phone'] ?? '');
    emailController = TextEditingController(text: party?['email'] ?? '');
    websiteController = TextEditingController(text: party?['website'] ?? '');
    gstinController = TextEditingController(text: party?['gstin'] ?? '');
    panController = TextEditingController(text: party?['pan'] ?? '');
    tanController = TextEditingController(text: party?['tan'] ?? '');
    aadhaarController = TextEditingController(text: party?['aadhaar_no'] ?? '');
    billingAddressController = TextEditingController(
      text: party?['billing_address'] ?? '',
    );
    billingCityController = TextEditingController(
      text: party?['billing_city'] ?? '',
    );
    billingPincodeController = TextEditingController(
      text: party?['billing_pincode'] ?? '',
    );
    shippingAddressController = TextEditingController(
      text: party?['shipping_address'] ?? '',
    );
    shippingCityController = TextEditingController(
      text: party?['shipping_city'] ?? '',
    );
    shippingPincodeController = TextEditingController(
      text: party?['shipping_pincode'] ?? '',
    );
    creditLimitController = TextEditingController(
      text: (party?['credit_limit'] ?? 0).toString(),
    );
    creditDaysController = TextEditingController(
      text: (party?['credit_days'] ?? 0).toString(),
    );
    openingBalanceController = TextEditingController(
      text: (party?['opening_balance'] ?? 0).toString(),
    );

    if (party != null) {
      selectedPartyType = party['party_type'] ?? 'SUPPLIER';
      selectedBillingState = party['billing_state_code'] ?? '';
      selectedShippingState = party['shipping_state_code'] ?? '';
      selectedGSTType = party['gst_registration_type'] ?? 'UNREGISTERED';
      selectedBalanceType = party['balance_type'] ?? 'DR';
      final groupIdVal = party['ledger_group_id'];
      if (groupIdVal is int) {
        selectedLedgerGroupId = groupIdVal;
      } else if (groupIdVal is double) {
        selectedLedgerGroupId = groupIdVal.toInt();
      } else if (groupIdVal is String) {
        selectedLedgerGroupId = int.tryParse(groupIdVal);
      }
      selectedAccountHead = selectedBalanceType == 'DR'
          ? 'ASSETS'
          : 'LIABILITIES';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contactPersonController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    gstinController.dispose();
    panController.dispose();
    tanController.dispose();
    aadhaarController.dispose();
    billingAddressController.dispose();
    billingCityController.dispose();
    billingPincodeController.dispose();
    shippingAddressController.dispose();
    shippingCityController.dispose();
    shippingPincodeController.dispose();
    creditLimitController.dispose();
    creditDaysController.dispose();
    openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      showErrorToast(context, 'Name and Phone are required');
      return;
    }

    if (gstinController.text.isNotEmpty && gstinController.text.length != 15) {
      showErrorToast(context, 'GSTIN must be 15 characters');
      return;
    }

    if (panController.text.isNotEmpty && panController.text.length != 10) {
      showErrorToast(context, 'PAN must be 10 characters');
      return;
    }

    if (selectedLedgerGroupId == null && widget.party == null) {
      showErrorToast(context, 'Please select a Ledger Group');
      return;
    }

    try {
      setState(() => isSubmitting = true);

      final payload = {
        'party_type': selectedPartyType,
        if (selectedLedgerGroupId != null)
          'ledger_group_id': selectedLedgerGroupId,
        'name': nameController.text,
        'contact_person': contactPersonController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'website': websiteController.text,
        'gstin': gstinController.text.isNotEmpty ? gstinController.text : null,
        'pan': panController.text.isNotEmpty ? panController.text : null,
        'tan': tanController.text.isNotEmpty ? tanController.text : null,
        'aadhaar_no': aadhaarController.text.isNotEmpty
            ? aadhaarController.text
            : null,
        'billing_address': billingAddressController.text,
        'billing_city': billingCityController.text,
        'billing_state_code': selectedBillingState,
        'billing_pincode': billingPincodeController.text,
        'shipping_address': shippingAddressController.text,
        'shipping_city': shippingCityController.text,
        'shipping_state_code': selectedShippingState,
        'shipping_pincode': shippingPincodeController.text,
        'gst_registration_type': selectedGSTType,
        'credit_limit': double.tryParse(creditLimitController.text) ?? 0,
        'credit_days': int.tryParse(creditDaysController.text) ?? 0,
        'opening_balance': double.tryParse(openingBalanceController.text) ?? 0,
        'balance_type': selectedBalanceType,
      };

      if (widget.party != null) {
        await widget.apiService.updateParty(widget.party!['id'], payload);
      } else {
        // Check GSTIN exists
        if (gstinController.text.isNotEmpty) {
          final exists = await widget.apiService.checkGstinExists(
            gstinController.text,
          );
          if (exists) {
            showErrorToast(context, 'GSTIN already registered');
            return;
          }
        }

        await widget.apiService.createParty(payload);
      }

      widget.onSuccess();
    } catch (e) {
      showErrorToast(context, 'Error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ledger Type (Customer / Supplier / Bank etc.)
          DropdownButtonFormField<String>(
            initialValue: selectedPartyType,
            decoration: InputDecoration(
              labelText: 'Ledger Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: [
              'SUPPLIER',
              'CUSTOMER',
              'EMPLOYEE',
              'BANK',
              'OTHER',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              setState(() {
                selectedPartyType = value ?? 'SUPPLIER';
                _applyDefaultGroup();
              });
            },
          ),
          const SizedBox(height: 16),

          // Ledger Group (mandatory)
          if (groupsLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            )
          else
            DropdownButtonFormField<int>(
              value: selectedLedgerGroupId,
              decoration: InputDecoration(
                labelText: 'Group *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.account_tree),
              ),
              items: ledgerGroups
                  .map(
                    (g) => DropdownMenuItem(
                      value: g.id,
                      child: Text('${g.name} (${_natureDisplay(g.nature)})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLedgerGroupId = value;
                  LedgerGroup? g;
                  for (final x in ledgerGroups) {
                    if (x.id == value) {
                      g = x;
                      break;
                    }
                  }
                  if (g != null) {
                    _syncAccountSelectionFromLedgerGroup(g);
                  }
                });
              },
            ),
          if (selectedLedgerGroupId != null) ...[
            const SizedBox(height: 12),
            // Nature (read-only, from group)
            Builder(
              builder: (context) {
                String nature = 'ASSETS';
                for (final x in ledgerGroups) {
                  if (x.id == selectedLedgerGroupId) {
                    nature = x.nature;
                    break;
                  }
                }
                return TextFormField(
                  initialValue: _natureDisplay(nature),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Nature of Account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.info_outline),
                    filled: true,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedAccountHead,
            decoration: InputDecoration(
              labelText: 'Balance Head',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.account_balance),
            ),
            items: _accountHeadLabels.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedAccountHead = value;
                selectedSubGroup = null;
                selectedBalanceType = _balanceTypeFromAccountHead(value);
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedSubGroup,
            decoration: InputDecoration(
              labelText: 'Sub Group',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.account_tree),
            ),
            items: _availableSubGroupsForHead(selectedAccountHead)
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.value,
                    child: Text('${entry.key} • ${entry.value}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedSubGroup = value;
                selectedBalanceType = _balanceTypeFromAccountHead(
                  selectedAccountHead,
                );
                _tryResolveLedgerGroupFromSubGroup();
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _accountHeadLabels[selectedAccountHead] ??
                      selectedAccountHead,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(_accountHeadPurpose[selectedAccountHead] ?? ''),
                const SizedBox(height: 4),
                Text(_accountHeadBehavior[selectedAccountHead] ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Basic Information Section
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Party Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: contactPersonController,
            decoration: InputDecoration(
              labelText: 'Contact Person',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: websiteController,
            decoration: InputDecoration(
              labelText: 'Website',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 20),

          // GST & Tax Information
          Text(
            'GST & Tax Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: gstinController,
                  decoration: InputDecoration(
                    labelText: 'GSTIN (15 chars)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.verified_user),
                  ),
                  maxLength: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: panController,
                  decoration: InputDecoration(
                    labelText: 'PAN (10 chars)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.verified),
                  ),
                  maxLength: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: tanController,
                  decoration: InputDecoration(
                    labelText: 'TAN',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.receipt),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: aadhaarController,
                  decoration: InputDecoration(
                    labelText: 'Aadhaar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.credit_card),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: selectedGSTType,
            decoration: InputDecoration(
              labelText: 'GST Registration Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.list),
            ),
            items: [
              'REGULAR',
              'COMPOSITION',
              'UNREGISTERED',
              'EXEMPTED',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) =>
                setState(() => selectedGSTType = value ?? 'UNREGISTERED'),
          ),
          const SizedBox(height: 20),

          // Billing Address
          Text(
            'Billing Address',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: billingAddressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: billingCityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedBillingState.isNotEmpty
                      ? selectedBillingState
                      : null,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: states
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedBillingState = value ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: billingPincodeController,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shipping Address
          Text(
            'Shipping Address',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: shippingAddressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: shippingCityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedShippingState.isNotEmpty
                      ? selectedShippingState
                      : null,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: states
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedShippingState = value ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: shippingPincodeController,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Credit Terms
          Text('Credit Terms', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: creditLimitController,
                  decoration: InputDecoration(
                    labelText: 'Credit Limit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: creditDaysController,
                  decoration: InputDecoration(
                    labelText: 'Credit Days',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Opening Balance
          Text(
            'Opening Balance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: openingBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: selectedLedgerGroupId != null
                    ? TextFormField(
                        initialValue: selectedBalanceType == 'DR'
                            ? 'Debit (Dr) — Increases'
                            : 'Credit (Cr) — Increases',
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Balance Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: selectedBalanceType,
                        decoration: InputDecoration(
                          labelText: 'Balance Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'DR',
                            child: Text('Debit (Dr) — Increases'),
                          ),
                          DropdownMenuItem(
                            value: 'CR',
                            child: Text('Credit (Cr) — Increases'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedBalanceType = value ?? 'DR'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.party == null ? 'Create Party' : 'Update Party',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PARTY DETAILS DIALOG
// ============================================================================

class PartyDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> party;
  final ApiService apiService;

  const PartyDetailsDialog({
    super.key,
    required this.party,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Party Details'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailSection('Party Information', [
                _buildDetailRow('Type', party['party_type']),
                _buildDetailRow('Name', party['name']),
                _buildDetailRow('Contact Person', party['contact_person']),
                _buildDetailRow('Phone', party['phone']),
                _buildDetailRow('Email', party['email']),
              ]),
              const SizedBox(height: 20),
              _buildDetailSection('Tax Information', [
                _buildDetailRow('GSTIN', party['gstin']),
                _buildDetailRow('PAN', party['pan']),
                _buildDetailRow('TAN', party['tan']),
                _buildDetailRow('Aadhaar', party['aadhaar_no']),
                _buildDetailRow(
                  'GST Registration',
                  party['gst_registration_type'],
                ),
              ]),
              const SizedBox(height: 20),
              _buildDetailSection('Billing Address', [
                _buildDetailRow('Address', party['billing_address']),
                _buildDetailRow('City', party['billing_city']),
                _buildDetailRow('State', party['billing_state_code']),
                _buildDetailRow('Pincode', party['billing_pincode']),
              ]),
              const SizedBox(height: 20),
              _buildDetailSection('Credit Terms', [
                _buildDetailRow(
                  'Credit Limit',
                  '₹${(party['credit_limit'] ?? 0).toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Credit Days',
                  '${party['credit_days'] ?? 0} days',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PARTY HISTORY DIALOG
// ============================================================================

class PartyHistoryDialog extends StatefulWidget {
  final int partyId;
  final String partyName;
  final ApiService apiService;

  const PartyHistoryDialog({
    super.key,
    required this.partyId,
    required this.partyName,
    required this.apiService,
  });

  @override
  State<PartyHistoryDialog> createState() => _PartyHistoryDialogState();
}

class _PartyHistoryDialogState extends State<PartyHistoryDialog> {
  late Future<List<Map<String, dynamic>>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = widget.apiService
        .getPartyHistory(widget.partyId)
        .then((value) => value.cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Change History - ${widget.partyName}'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const Center(child: Text('No change history found'));
            }

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final change = history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: _getChangeIcon(change['change_type']),
                    title: Text(change['change_type']),
                    subtitle: Text(change['change_date'] ?? 'N/A'),
                    trailing: Text(
                      change['reason'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _getChangeIcon(String changeType) {
    switch (changeType) {
      case 'CREATE':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.add, color: Colors.white),
        );
      case 'UPDATE':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.edit, color: Colors.white),
        );
      case 'DEACTIVATE':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.close, color: Colors.white),
        );
      case 'REACTIVATE':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.refresh, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.info, color: Colors.white),
        );
    }
  }
}
