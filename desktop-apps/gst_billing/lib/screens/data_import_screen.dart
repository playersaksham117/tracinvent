/// Data Import Screen - POS Data Import Wizard
/// Multi-step wizard: Upload → Map → Validate → Preview → Import
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/import_models.dart';
import '../services/import_service.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({super.key});

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  int _currentStep = 0;
  
  // Step 1: Import Type & File
  ImportType _selectedType = ImportType.sales;
  SourceFormat _selectedFormat = SourceFormat.csv;
  String? _fileName;
  String? _fileContent;
  
  // Step 2: Parsed Data
  ParseResult? _parseResult;
  
  // Step 3: Field Mappings
  Map<String, FieldMapping> _mappings = {};
  
  // Step 4: Validation
  ValidationResult? _validationResult;
  bool _isValidating = false;
  
  // Step 5: Dry Run Preview
  DryRunPreview? _dryRunPreview;
  
  // Step 6: Import
  ImportResult? _importResult;
  bool _isImporting = false;
  
  // Batch tracking
  String? _batchId;

  final List<String> _stepTitles = [
    'Select Import Type',
    'Upload File',
    'Map Fields',
    'Validate Data',
    'Preview Changes',
    'Import',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Import Data'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        actions: [
          if (_batchId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Batch: $_batchId',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Stepper
          _buildProgressStepper(),
          
          // Step Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(),
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppTheme.successColor : AppTheme.slate200,
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppTheme.successColor
                        : isCurrent
                            ? AppTheme.primaryColor
                            : AppTheme.slate200,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : AppTheme.slate500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (index < _stepTitles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppTheme.successColor : AppTheme.slate200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildSelectTypeStep();
      case 1:
        return _buildUploadStep();
      case 2:
        return _buildMappingStep();
      case 3:
        return _buildValidationStep();
      case 4:
        return _buildPreviewStep();
      case 5:
        return _buildImportStep();
      default:
        return const SizedBox();
    }
  }

  // =========================================================================
  // STEP 1: SELECT IMPORT TYPE
  // =========================================================================

  Widget _buildSelectTypeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to import?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of data you want to import from your existing system.',
            style: TextStyle(color: AppTheme.slate500),
          ),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: ImportType.values.map((type) {
              final isSelected = _selectedType == type;
              return InkWell(
                onTap: () => setState(() => _selectedType = type),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.slate200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : AppTheme.slate100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          type.icon,
                          size: 28,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.slate500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.slate700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeDescription(type),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Source Format Selection
          Text(
            'Source Format',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate700,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            children: SourceFormat.values.map((format) {
              final isSelected = _selectedFormat == format;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(format.icon, size: 16),
                    const SizedBox(width: 8),
                    Text(format.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFormat = format),
                selectedColor: AppTheme.primaryLight,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getTypeDescription(ImportType type) {
    switch (type) {
      case ImportType.sales:
        return 'Import sales invoices with customer details, items, and tax';
      case ImportType.purchase:
        return 'Import purchase bills with supplier info and inventory';
      case ImportType.openingStock:
        return 'Import opening stock with SKU, quantity, and rates';
      case ImportType.ledgerOpening:
        return 'Import debtor/creditor opening balances';
    }
  }

  // =========================================================================
  // STEP 2: UPLOAD FILE
  // =========================================================================

  Widget _buildUploadStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Your Data File',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a ${_selectedFormat.label} file containing your ${_selectedType.label.toLowerCase()}.',
            style: TextStyle(color: AppTheme.slate500),
          ),
          const SizedBox(height: 32),
          
          // Upload Area
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.slate300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _fileName != null ? Icons.check_circle : Icons.cloud_upload,
                      size: 48,
                      color: _fileName != null ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_fileName != null) ...[
                    Text(
                      _fileName!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate700,
                      ),
                    ),
                    if (_parseResult != null)
                      Text(
                        '${_parseResult!.totalRows} rows detected',
                        style: TextStyle(color: AppTheme.slate500),
                      ),
                  ] else ...[
                    Text(
                      'Click to select a file',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slate700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or drag and drop here',
                      style: TextStyle(color: AppTheme.slate400),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Supported: ${_selectedFormat.extension}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sample Data Preview
          if (_parseResult != null) ...[
            const SizedBox(height: 24),
            Text(
              'Preview (first ${_parseResult!.sampleData.length} rows)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.slate200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.slate100),
                  columns: _parseResult!.headers.map((h) => 
                    DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.w600)))
                  ).toList(),
                  rows: _parseResult!.sampleData.take(5).map((row) =>
                    DataRow(
                      cells: _parseResult!.headers.map((h) =>
                        DataCell(Text(row[h]?.toString() ?? '', 
                          style: TextStyle(color: AppTheme.slate600, fontSize: 13)))
                      ).toList(),
                    )
                  ).toList(),
                ),
              ),
            ),
          ],
          
          // Required Fields Info
          const SizedBox(height: 24),
          _buildRequiredFieldsInfo(),
        ],
      ),
    );
  }

  Widget _buildRequiredFieldsInfo() {
    final fields = ImportFieldDefinitions.getFieldsForType(_selectedType);
    final requiredFields = fields.entries
        .where((e) => e.value['required'] == true)
        .map((e) => e.value['label'] as String)
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Required Fields',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.infoColor),
                ),
                const SizedBox(height: 4),
                Text(
                  requiredFields.join(', '),
                  style: TextStyle(color: AppTheme.slate600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    // For demo, show a dialog to paste CSV content
    final content = await showDialog<String>(
      context: context,
      builder: (context) => _FileContentDialog(format: _selectedFormat),
    );
    
    if (content != null && content.isNotEmpty) {
      try {
        final result = ImportService.parseCSVLocally(content);
        setState(() {
          _fileName = 'imported_data${_selectedFormat.extension}';
          _fileContent = content;
          _parseResult = result;
        });
      } catch (e) {
        _showError('Failed to parse file: $e');
      }
    }
  }

  // =========================================================================
  // STEP 3: FIELD MAPPING
  // =========================================================================

  Widget _buildMappingStep() {
    if (_mappings.isEmpty && _parseResult != null) {
      _mappings = ImportService.getFieldSuggestionsLocally(
        importType: _selectedType,
        headers: _parseResult!.headers,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Map Your Fields',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Match your file columns to the required fields. We\'ve auto-detected some mappings.',
            style: TextStyle(color: AppTheme.slate500),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: _mappings.length,
              itemBuilder: (context, index) {
                final entry = _mappings.entries.elementAt(index);
                return _buildMappingRow(entry.key, entry.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(String targetField, FieldMapping mapping) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mapping.required && mapping.sourceField == null
              ? AppTheme.errorColor.withOpacity(0.5)
              : AppTheme.slate200,
        ),
      ),
      child: Row(
        children: [
          // Target Field
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mapping.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (mapping.required)
                      Text(' *', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
                Text(
                  mapping.type,
                  style: TextStyle(fontSize: 12, color: AppTheme.slate400),
                ),
              ],
            ),
          ),
          
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.arrow_back, color: AppTheme.slate400),
          ),
          
          // Source Field Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              initialValue: mapping.sourceField,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.slate50,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Not Mapped --', style: TextStyle(color: Colors.grey)),
                ),
                ..._parseResult!.headers.map((h) => DropdownMenuItem(
                  value: h,
                  child: Text(h),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _mappings[targetField] = FieldMapping(
                    sourceField: value,
                    targetField: targetField,
                    required: mapping.required,
                    label: mapping.label,
                    type: mapping.type,
                    defaultValue: mapping.defaultValue,
                    options: mapping.options,
                  );
                });
              },
            ),
          ),
          
          // Default Value (if not mapped)
          if (mapping.sourceField == null && mapping.defaultValue != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Chip(
                label: Text('Default: ${mapping.defaultValue}'),
                backgroundColor: AppTheme.slate100,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 4: VALIDATION
  // =========================================================================

  Widget _buildValidationStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validate Your Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll check your data for errors and warnings before importing.',
            style: TextStyle(color: AppTheme.slate500),
          ),
          const SizedBox(height: 24),
          
          if (_isValidating)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Validating data...'),
                ],
              ),
            )
          else if (_validationResult == null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.fact_check, size: 64, color: AppTheme.slate300),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _runValidation,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Validation'),
                  ),
                ],
              ),
            )
          else
            Expanded(child: _buildValidationResults()),
        ],
      ),
    );
  }

  Widget _buildValidationResults() {
    final result = _validationResult!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            _buildSummaryCard(
              'Total Records',
              result.totalRecords.toString(),
              Icons.list_alt,
              AppTheme.slate500,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Valid',
              result.validRecords.toString(),
              Icons.check_circle,
              AppTheme.successColor,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Errors',
              (result.issuesSummary['errors'] ?? 0).toString(),
              Icons.error,
              AppTheme.errorColor,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Warnings',
              (result.issuesSummary['warnings'] ?? 0).toString(),
              Icons.warning,
              AppTheme.warningColor,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Issues List
        if (result.issues.isNotEmpty) ...[
          Text(
            'Issues Found (${result.issues.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: result.issues.length,
              itemBuilder: (context, index) {
                final issue = result.issues[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: issue.severity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: issue.severity.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(issue.severity.icon, color: issue.severity.color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Row ${issue.row}: ${issue.message}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (issue.suggestion != null)
                              Text(
                                issue.suggestion!,
                                style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        issue.field,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: AppTheme.successColor),
                  const SizedBox(height: 16),
                  const Text(
                    'All records are valid!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runValidation() async {
    if (_parseResult == null || _fileContent == null) return;
    
    setState(() => _isValidating = true);
    
    try {
      // Parse all rows
      final allRows = _parseAllRows();
      final mappingsList = _mappings.values.toList();
      
      final result = ImportService.validateDataLocally(
        dataRows: allRows,
        mappings: mappingsList,
        importType: _selectedType,
      );
      
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    } catch (e) {
      setState(() => _isValidating = false);
      _showError('Validation failed: $e');
    }
  }

  List<Map<String, dynamic>> _parseAllRows() {
    if (_fileContent == null || _parseResult == null) return [];
    
    final lines = _fileContent!.trim().split('\n');
    
    final rows = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final values = ImportService.parseCSVLocally(lines[i]).sampleData.isNotEmpty
          ? ImportService.parseCSVLocally('${lines[0]}\n${lines[i]}').sampleData.first
          : <String, dynamic>{};
      rows.add(values);
    }
    
    return rows;
  }

  // =========================================================================
  // STEP 5: DRY RUN PREVIEW
  // =========================================================================

  Widget _buildPreviewStep() {
    if (_dryRunPreview == null) {
      _generateDryRun();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Changes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review the vouchers that will be created. No data has been imported yet.',
            style: TextStyle(color: AppTheme.slate500),
          ),
          const SizedBox(height: 24),
          
          if (_dryRunPreview == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildPreviewStat('Vouchers', _dryRunPreview!.totalVouchers.toString()),
                  const SizedBox(width: 32),
                  _buildPreviewStat('Total Amount', '₹${_dryRunPreview!.totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(width: 32),
                  _buildPreviewStat('Parties', _dryRunPreview!.partiesAffected.length.toString()),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Voucher List
            Text(
              'Vouchers to Create',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate700,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                itemCount: _dryRunPreview!.vouchersToCreate.length,
                itemBuilder: (context, index) {
                  final voucher = _dryRunPreview!.vouchersToCreate[index];
                  return _buildVoucherPreviewCard(voucher);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
            color: AppTheme.primaryColor,
          ),
        ),
        Text(label, style: TextStyle(color: AppTheme.slate600)),
      ],
    );
  }

  Widget _buildVoucherPreviewCard(VoucherPreview voucher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getVoucherIcon(voucher.voucherType),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          voucher.voucherNumber ?? voucher.partyName ?? 'Voucher',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${voucher.voucherType} • ${voucher.date ?? ""}',
          style: TextStyle(color: AppTheme.slate500, fontSize: 12),
        ),
        trailing: Text(
          '₹${voucher.total.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        children: [
          if (voucher.items != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: voucher.items!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(item['item_name'] ?? '')),
                      Text('${item['qty']} x ₹${item['rate']}'),
                      const SizedBox(width: 16),
                      Text(
                        '₹${(item['amount'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getVoucherIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sales invoice':
        return Icons.receipt_long;
      case 'purchase invoice':
        return Icons.shopping_cart;
      case 'stock journal':
        return Icons.inventory;
      case 'opening balance':
        return Icons.account_balance_wallet;
      default:
        return Icons.description;
    }
  }

  void _generateDryRun() {
    if (_parseResult == null) return;
    
    final allRows = _parseAllRows();
    final preview = ImportService.generateDryRunLocally(
      dataRows: allRows,
      mappings: _mappings.values.toList(),
      importType: _selectedType,
    );
    
    setState(() => _dryRunPreview = preview);
  }

  // =========================================================================
  // STEP 6: IMPORT
  // =========================================================================

  Widget _buildImportStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _isImporting
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    'Importing data...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we create the vouchers.',
                    style: TextStyle(color: AppTheme.slate500),
                  ),
                ],
              )
            : _importResult != null
                ? _buildImportResults()
                : _buildImportConfirmation(),
      ),
    );
  }

  Widget _buildImportConfirmation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.warningLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.upload_file, size: 64, color: AppTheme.warningColor),
        ),
        const SizedBox(height: 32),
        const Text(
          'Ready to Import',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'You are about to import ${_validationResult?.validRecords ?? 0} records.\n'
          'This will create vouchers and update ledgers & inventory.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.slate600),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _executeImport,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Import'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppTheme.slate400, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImportResults() {
    final result = _importResult!;
    final isSuccess = result.isSuccess;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSuccess ? AppTheme.successLight : AppTheme.warningLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSuccess ? Icons.check_circle : Icons.warning,
            size: 64,
            color: isSuccess ? AppTheme.successColor : AppTheme.warningColor,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          isSuccess ? 'Import Completed!' : 'Import Completed with Issues',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildResultStat('Imported', result.imported.toString(), AppTheme.successColor),
            const SizedBox(width: 32),
            _buildResultStat('Failed', result.failed.toString(), AppTheme.errorColor),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.done),
              label: const Text('Done'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _startNewImport,
              icon: const Icon(Icons.add),
              label: const Text('New Import'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: AppTheme.slate600)),
      ],
    );
  }

  Future<void> _executeImport() async {
    setState(() => _isImporting = true);
    
    // Simulate import for demo (in production, call ImportService.executeImport)
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _importResult = ImportResult(
        imported: _validationResult?.validRecords ?? 0,
        failed: _validationResult?.invalidRecords ?? 0,
        results: [],
      );
      _isImporting = false;
    });
  }

  void _startNewImport() {
    setState(() {
      _currentStep = 0;
      _fileName = null;
      _fileContent = null;
      _parseResult = null;
      _mappings = {};
      _validationResult = null;
      _dryRunPreview = null;
      _importResult = null;
      _batchId = null;
    });
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          if (_currentStep > 0 && _importResult == null)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          else
            const SizedBox(width: 100),
          
          // Step indicator
          Text(
            _stepTitles[_currentStep],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.slate600,
            ),
          ),
          
          // Next Button
          if (_currentStep < _stepTitles.length - 1)
            FilledButton.icon(
              onPressed: _canProceed() ? () => setState(() => _currentStep++) : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // Type selection always valid
      case 1:
        return _parseResult != null;
      case 2:
        // Check required mappings
        return _mappings.values
            .where((m) => m.required)
            .every((m) => m.sourceField != null || m.defaultValue != null);
      case 3:
        return _validationResult != null && _validationResult!.validRecords > 0;
      case 4:
        return _dryRunPreview != null;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

// ============================================================================
// FILE CONTENT DIALOG (for demo without file_picker)
// ============================================================================

class _FileContentDialog extends StatefulWidget {
  final SourceFormat format;
  
  const _FileContentDialog({required this.format});

  @override
  State<_FileContentDialog> createState() => _FileContentDialogState();
}

class _FileContentDialogState extends State<_FileContentDialog> {
  final _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Pre-fill with sample data
    if (widget.format == SourceFormat.csv) {
      _controller.text = '''Invoice No,Date,Customer,GSTIN,Item,HSN,Qty,Rate,Tax %,Total,Payment
INV001,2024-01-15,ABC Traders,07AABBC1234A1ZK,Laptop,8471,2,50000,18,118000,cash
INV001,2024-01-15,ABC Traders,07AABBC1234A1ZK,Mouse,8471,5,500,18,2950,cash
INV002,2024-01-16,XYZ Corp,07XYZD5678B2ZL,Monitor,8528,1,25000,18,29500,upi
INV003,2024-01-17,Tech Solutions,,Keyboard,8471,10,1500,18,17700,credit''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Paste ${widget.format.label} Content'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your CSV data below (with headers):',
              style: TextStyle(color: AppTheme.slate600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Header1,Header2,Header3\nValue1,Value2,Value3\n...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppTheme.slate50,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Import'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
