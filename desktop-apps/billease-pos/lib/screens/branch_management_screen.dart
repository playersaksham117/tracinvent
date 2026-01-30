import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/branch.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  _BranchManagementScreenState createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  List<Map<String, dynamic>> branches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => isLoading = true);
    final db = DatabaseHelper.instance;
    final branchList = await db.getAllBranches();
    setState(() {
      branches = branchList;
      isLoading = false;
    });
  }

  Future<void> _addOrEditBranch([Map<String, dynamic>? branch]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BranchFormDialog(branch: branch),
    );

    if (result == true) {
      _loadBranches();
    }
  }

  Future<void> _deleteBranch(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = DatabaseHelper.instance;
      await db.deleteBranch(id);
      _loadBranches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditBranch(),
            tooltip: 'Add New Branch',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : branches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No branches yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _addOrEditBranch(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Branch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final isHO = (branch['is_head_office'] as int?) == 1;
                    final isActive = (branch['is_active'] as int?) == 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isHO ? Colors.amber : Colors.indigo,
                          child: Icon(
                            isHO ? Icons.stars : Icons.store,
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              branch['branch_name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (isHO) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('HO', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.amber,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('INACTIVE', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.grey,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${branch['branch_code']}'),
                            if (branch['city'] != null)
                              Text('${branch['city']}, ${branch['state'] ?? ''}'),
                            if (branch['phone'] != null)
                              Text('📞 ${branch['phone']}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _addOrEditBranch(branch);
                            } else if (value == 'delete') {
                              _deleteBranch(
                                branch['id'] as int,
                                branch['branch_name'] as String,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            if (!isHO)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditBranch(),
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}

class BranchFormDialog extends StatefulWidget {
  final Map<String, dynamic>? branch;

  const BranchFormDialog({super.key, this.branch});

  @override
  _BranchFormDialogState createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstinController;
  late TextEditingController _managerController;
  bool isActive = true;
  bool isHeadOffice = false;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _codeController = TextEditingController(text: branch?['branch_code'] ?? '');
    _nameController = TextEditingController(text: branch?['branch_name'] ?? '');
    _addressController = TextEditingController(text: branch?['address'] ?? '');
    _cityController = TextEditingController(text: branch?['city'] ?? '');
    _stateController = TextEditingController(text: branch?['state'] ?? '');
    _postalCodeController = TextEditingController(text: branch?['postal_code'] ?? '');
    _phoneController = TextEditingController(text: branch?['phone'] ?? '');
    _emailController = TextEditingController(text: branch?['email'] ?? '');
    _gstinController = TextEditingController(text: branch?['gstin'] ?? '');
    _managerController = TextEditingController(text: branch?['manager_name'] ?? '');
    isActive = (branch?['is_active'] as int?) == 1;
    isHeadOffice = (branch?['is_head_office'] as int?) == 1;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  Future<void> _saveBranch() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper.instance;
      final branchData = Branch(
        id: widget.branch?['id'] as int?,
        tenantId: 'default',
        branchCode: _codeController.text.trim(),
        branchName: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        managerName: _managerController.text.trim().isEmpty ? null : _managerController.text.trim(),
        isActive: isActive,
        isHeadOffice: isHeadOffice,
      );

      try {
        if (widget.branch == null) {
          await db.insertBranch(branchData.toMap());
        } else {
          await db.updateBranch(widget.branch!['id'] as int, branchData.toMap());
        }
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.branch == null ? 'Add New Branch' : 'Edit Branch',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Branch Code*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Branch Name*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _managerController,
                    decoration: const InputDecoration(
                      labelText: 'Manager Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Active'),
                          value: isActive,
                          onChanged: (value) =>
                              setState(() => isActive = value ?? true),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Head Office'),
                          value: isHeadOffice,
                          onChanged: (value) =>
                              setState(() => isHeadOffice = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveBranch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('SAVE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
