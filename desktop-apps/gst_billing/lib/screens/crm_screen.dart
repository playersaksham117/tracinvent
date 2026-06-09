/// CRM Screen - Sales Pipeline and Customer Success
library;

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CRMScreen extends StatefulWidget {
  const CRMScreen({super.key});

  @override
  State<CRMScreen> createState() => _CRMScreenState();
}

class _CRMScreenState extends State<CRMScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  late Future<List<Map<String, dynamic>>> _pipelineFuture;
  late Future<List<Map<String, dynamic>>> _leadsFuture;
  late Future<List<Map<String, dynamic>>> _followupsFuture;
  late Future<List<Map<String, dynamic>>> _customersFuture;
  late Future<Map<String, dynamic>> _reportsFuture;
  late Future<List<Map<String, dynamic>>> _staffFuture;

  String _leadSearch = '';
  String _customerSearch = '';
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _loadData();
  }

  void _loadData() {
    _pipelineFuture = _api.getCrmPipeline();
    _leadsFuture = _api.getCrmLeads(search: _leadSearch);
    _followupsFuture = _api.getCrmFollowUps(status: 'PENDING');
    _customersFuture = _api.getCrmCustomers(search: _customerSearch);
    _reportsFuture = _api.getCrmReports();
    _staffFuture = _api.getCrmStaff();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('CRM'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.slate400,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.person_add_alt_1), text: 'Leads'),
            Tab(icon: Icon(Icons.workspaces), text: 'Pipeline'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Follow-ups'),
            Tab(icon: Icon(Icons.group), text: 'Customers'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
            Tab(icon: Icon(Icons.badge), text: 'Staff'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_loadData),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsTab(),
          _buildPipelineTab(),
          _buildFollowupsTab(),
          _buildCustomersTab(),
          _buildReportsTab(),
          _buildStaffTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currentTab == 5 ? _showStaffDialog : _showLeadDialog,
        icon: const Icon(Icons.add),
        label: Text(_currentTab == 5 ? 'Add Staff' : 'New Lead'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildLeadsTab() {
    return Column(
      children: [
        _buildSearchBar(
          hint: 'Search leads by name, company, phone... ',
          onChanged: (value) {
            setState(() {
              _leadSearch = value;
              _leadsFuture = _api.getCrmLeads(search: _leadSearch);
            });
          },
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _leadsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (snapshot.hasError) {
                return _buildErrorState('Failed to load leads');
              }
              final leads = snapshot.data ?? [];
              if (leads.isEmpty) {
                return _buildEmptyState('No leads yet');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: leads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildLeadCard(leads[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineTab() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_pipelineFuture, _leadsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load pipeline');
        }
        final stages = (snapshot.data?[0] as List<Map<String, dynamic>>?) ?? [];
        final leads = (snapshot.data?[1] as List<Map<String, dynamic>>?) ?? [];
        if (stages.isEmpty) {
          return _buildEmptyState('No pipeline stages');
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stages.map((stage) {
              final stageId = stage['id'] as int?;
              final stageLeads = leads.where((lead) {
                final leadStage = lead['pipeline_stage_id'];
                if (stageId == null) return leadStage == null;
                return leadStage == stageId;
              }).toList();
              return _buildStageColumn(stage, stageLeads);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStageColumn(Map<String, dynamic> stage, List<Map<String, dynamic>> leads) {
    final stageName = stage['name']?.toString() ?? 'Stage';
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stageName, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              _statusChip('${leads.length}', AppTheme.slate500),
            ],
          ),
          const SizedBox(height: 8),
          DragTarget<Map<String, dynamic>>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) async {
              final lead = details.data;
              final stageId = stage['id'];
              await _api.updateCrmLead(lead['id'], {
                'pipeline_stage_id': stageId,
                'status': stageName,
              });
              if (mounted) {
                setState(() => _leadsFuture = _api.getCrmLeads(search: _leadSearch));
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Column(
                children: leads.map((lead) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Draggable<Map<String, dynamic>>(
                      data: lead,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _buildPipelineLeadCard(lead, isDragging: true),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: _buildPipelineLeadCard(lead),
                      ),
                      child: _buildPipelineLeadCard(lead),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (leads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Drop lead here', style: TextStyle(color: Colors.grey.shade500)),
            ),
        ],
      ),
    );
  }

  Widget _buildPipelineLeadCard(Map<String, dynamic> lead, {bool isDragging = false}) {
    return InkWell(
      onTap: () => _showLeadDetails(lead),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDragging ? Colors.white : AppTheme.slate100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: isDragging
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead['name']?.toString() ?? 'Lead',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              lead['company_name']?.toString() ?? 'No company',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              'Value ₹${(lead['expected_value'] ?? 0).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowupsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _followupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load follow-ups');
        }
        final followups = snapshot.data ?? [];
        if (followups.isEmpty) {
          return _buildEmptyState('No follow-ups scheduled');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: followups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = followups[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                title: Text(item['lead_name']?.toString() ?? 'Lead'),
                subtitle: Text('Follow-up on ${item['followup_date'] ?? '-'}'),
                trailing: _statusChip(item['status']?.toString() ?? 'PENDING', AppTheme.warningColor),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return Column(
      children: [
        _buildSearchBar(
          hint: 'Search customers by name, GSTIN... ',
          onChanged: (value) {
            setState(() {
              _customerSearch = value;
              _customersFuture = _api.getCrmCustomers(search: _customerSearch);
            });
          },
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _customersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (snapshot.hasError) {
                return _buildErrorState('Failed to load customers');
              }
              final customers = snapshot.data ?? [];
              if (customers.isEmpty) {
                return _buildEmptyState('No customers found');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildCustomerCard(customers[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load CRM reports');
        }
        final data = snapshot.data ?? {};
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reportCard('Conversion Rate', '${(data['conversion_rate'] ?? 0).toStringAsFixed(1)}%', Icons.percent, Colors.green),
              const SizedBox(height: 12),
              _reportCard('Lifetime Value', '₹${(data['lifetime_value'] ?? 0).toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.blue),
              const SizedBox(height: 12),
              _reportCard('Recovery Efficiency', '${(data['recovery_efficiency'] ?? 0).toStringAsFixed(1)}%', Icons.shield, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _staffFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('Failed to load staff');
        }
        final staff = snapshot.data ?? [];
        if (staff.isEmpty) {
          return _buildEmptyState('No staff members');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: staff.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = staff[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    member['name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                title: Text(member['name']?.toString() ?? 'Staff'),
                subtitle: Text(member['email']?.toString() ?? 'No email'),
                trailing: Text(member['phone']?.toString() ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeadCard(Map<String, dynamic> lead) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showLeadDetails(lead),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead['name']?.toString() ?? 'Lead',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  _statusChip(lead['status']?.toString() ?? 'New', AppTheme.primaryColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lead['company_name']?.toString() ?? 'No company',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _metaChip('GSTIN', lead['gstin']?.toString() ?? '-'),
                  _metaChip('Assigned', lead['assigned_staff']?.toString() ?? 'Unassigned'),
                  _metaChip('Stage', lead['pipeline_stage']?.toString() ?? 'New'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showNoteDialog(lead),
                    icon: const Icon(Icons.note_add, size: 16),
                    label: const Text('Add Note'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showCallDialog(lead),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Log Call'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _showFollowupDialog(lead),
                    icon: const Icon(Icons.notifications_active, size: 16),
                    label: const Text('Follow-up'),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final risk = customer['risk_level']?.toString() ?? 'LOW';
    final riskColor = risk == 'HIGH'
        ? Colors.red
        : risk == 'MEDIUM'
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _showCustomerDrilldown(customer),
        title: Text(customer['name']?.toString() ?? 'Customer'),
        subtitle: Text('GSTIN: ${customer['gstin'] ?? '-'}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Outstanding ₹${(customer['outstanding'] ?? 0).toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            _statusChip('Risk: $risk', riskColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({required String hint, required ValueChanged<String> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: AppTheme.slate100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _reportCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: Colors.red.shade300)),
    );
  }

  Future<void> _showLeadDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _LeadCaptureDialog(api: _api),
    );
    if (created == true) {
      setState(_loadData);
    }
  }

  Future<void> _showStaffDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _StaffCreateDialog(api: _api),
    );
    if (created == true) {
      setState(() => _staffFuture = _api.getCrmStaff());
    }
  }

  Future<void> _showNoteDialog(Map<String, dynamic> lead) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add a note... ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _api.createCrmNote({
                'lead_id': lead['id'],
                'note': controller.text.trim(),
              });
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) setState(_loadData);
  }

  Future<void> _showCallDialog(Map<String, dynamic> lead) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Call'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Outcome, summary, next step... ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _api.createCrmCall({
                'lead_id': lead['id'],
                'call_type': 'OUTBOUND',
                'notes': controller.text.trim(),
              });
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) setState(_loadData);
  }

  Future<void> _showFollowupDialog(Map<String, dynamic> lead) async {
    DateTime? followupDate;
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Follow-up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                followupDate = picked;
              },
              child: const Text('Pick Date'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reminder notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (followupDate == null) return;
              await _api.createCrmFollowUp({
                'lead_id': lead['id'],
                'followup_date': followupDate!.toIso8601String().split('T')[0],
                'notes': controller.text.trim(),
              });
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) setState(_loadData);
  }

  Future<void> _showLeadDetails(Map<String, dynamic> lead) async {
    final timelineFuture = _api.getCrmLeadTimeline(lead['id']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lead['name']?.toString() ?? 'Lead Details'),
        content: SizedBox(
          width: 560,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: timelineFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (snapshot.hasError) {
                return _buildErrorState('Failed to load timeline');
              }
              final timeline = snapshot.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead['company_name']?.toString() ?? 'No company'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _metaChip('GSTIN', lead['gstin']?.toString() ?? '-'),
                      _metaChip('Stage', lead['pipeline_stage']?.toString() ?? 'New'),
                      _metaChip('Owner', lead['assigned_staff']?.toString() ?? 'Unassigned'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: timeline.isEmpty
                        ? _buildEmptyState('No activity yet')
                        : ListView.separated(
                            itemCount: timeline.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = timeline[index];
                              return _buildTimelineItem(item);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'note';
    final icon = type == 'call'
        ? Icons.phone
        : type == 'followup'
            ? Icons.notifications_active
            : Icons.note;
    final color = type == 'call'
        ? Colors.blue
        : type == 'followup'
            ? Colors.orange
            : Colors.grey;
    final title = item['title']?.toString() ?? 'Note';
    final detail = item['detail']?.toString() ?? '-';
    final meta = item['meta']?.toString();
    final createdAt = item['created_at']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(detail, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                if (meta != null && meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(createdAt.split(' ').first, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _showCustomerDrilldown(Map<String, dynamic> customer) async {
    final ledgerId = customer['ledger_id'] as int?;
    if (ledgerId == null) return;
    final detailFuture = Future.wait([
      _api.getLedger(ledgerId),
      _api.getInvoices(partyId: ledgerId),
    ]);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['name']?.toString() ?? 'Customer'),
        content: SizedBox(
          width: 640,
          child: FutureBuilder<List<dynamic>>(
            future: detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (snapshot.hasError) {
                return _buildErrorState('Failed to load customer details');
              }
              final ledger = snapshot.data?[0] as Ledger;
              final invoices = snapshot.data?[1] as List<GSTInvoice>;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GSTIN: ${ledger.gstin ?? '-'}'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _metaChip('Credit Limit', '₹${ledger.creditLimit.toStringAsFixed(0)}'),
                      _metaChip('Outstanding', '₹${ledger.currentBalance.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Sales History', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: invoices.isEmpty
                        ? _buildEmptyState('No invoices found')
                        : ListView.separated(
                            itemCount: invoices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final invoice = invoices[index];
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(invoice.invoiceNumber ?? '-')),
                                    Text('₹${invoice.grandTotal.toStringAsFixed(0)}'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _StaffCreateDialog extends StatefulWidget {
  final ApiService api;

  const _StaffCreateDialog({required this.api});

  @override
  State<_StaffCreateDialog> createState() => _StaffCreateDialogState();
}

class _StaffCreateDialogState extends State<_StaffCreateDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.api.createCrmStaff({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _LeadCaptureDialog extends StatefulWidget {
  final ApiService api;

  const _LeadCaptureDialog({required this.api});

  @override
  State<_LeadCaptureDialog> createState() => _LeadCaptureDialogState();
}

class _LeadCaptureDialogState extends State<_LeadCaptureDialog> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _creditController = TextEditingController();
  final _valueController = TextEditingController();

  int? _stageId;
  int? _staffId;
  bool _saving = false;

  late Future<List<Map<String, dynamic>>> _pipelineFuture;
  late Future<List<Map<String, dynamic>>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _pipelineFuture = widget.api.getCrmPipeline();
    _staffFuture = widget.api.getCrmStaff();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _creditController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.api.createCrmLead({
      'name': _nameController.text.trim(),
      'company_name': _companyController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'gstin': _gstinController.text.trim(),
      'credit_limit': double.tryParse(_creditController.text.trim()) ?? 0,
      'expected_value': double.tryParse(_valueController.text.trim()) ?? 0,
      'pipeline_stage_id': _stageId,
      'assigned_staff_id': _staffId,
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Lead'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Lead Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _creditController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Credit Limit',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expected Value',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _pipelineFuture,
                builder: (context, snapshot) {
                  final stages = snapshot.data ?? [];
                  return DropdownButtonFormField<int>(
                    initialValue: _stageId,
                    decoration: const InputDecoration(
                      labelText: 'Pipeline Stage',
                      border: OutlineInputBorder(),
                    ),
                    items: stages
                        .map((stage) => DropdownMenuItem<int>(
                              value: stage['id'] as int?,
                              child: Text(stage['name']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _stageId = value),
                  );
                },
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _staffFuture,
                builder: (context, snapshot) {
                  final staff = snapshot.data ?? [];
                  return DropdownButtonFormField<int>(
                    initialValue: _staffId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Staff',
                      border: OutlineInputBorder(),
                    ),
                    items: staff
                        .map((member) => DropdownMenuItem<int>(
                              value: member['id'] as int?,
                              child: Text(member['name']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _staffId = value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Lead'),
        ),
      ],
    );
  }
}
