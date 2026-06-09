import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/data_import_service.dart';
import '../services/data_export_service.dart';
import '../models/import_models.dart';

class DataImportExportScreen extends StatefulWidget {
  const DataImportExportScreen({super.key});

  @override
  State<DataImportExportScreen> createState() => _DataImportExportScreenState();
}

class _DataImportExportScreenState extends State<DataImportExportScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Import state
  String? _selectedImportFile;
  String _selectedImportType = 'sales';
  ImportSourceFormat _selectedSourceFormat = ImportSourceFormat.csv;
  bool _isImporting = false;
  ImportResult? _lastImportResult;
  
  // Export state
  String _selectedExportType = 'sales';
  String _selectedTargetApp = 'generic';
  ExportFormat _selectedExportFormat = ExportFormat.csv;
  DateTime? _exportFromDate;
  DateTime? _exportToDate;
  bool _isExporting = false;
  List<ExportResult> _lastExportResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Data Import / Export'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(icon: Icon(Icons.download_rounded), text: 'Import Data'),
            Tab(icon: Icon(Icons.upload_rounded), text: 'Export Data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // IMPORT TAB
  // ============================================================================

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImportTypeSelector(),
          const SizedBox(height: 20),
          _buildSourceFormatSelector(),
          const SizedBox(height: 20),
          _buildFileSelector(),
          const SizedBox(height: 20),
          _buildImportButton(),
          if (_lastImportResult != null) ...[
            const SizedBox(height: 24),
            _buildImportResultCard(),
          ],
          const SizedBox(height: 24),
          _buildImportTemplates(),
        ],
      ),
    );
  }

  Widget _buildImportTypeSelector() {
    return _buildCard(
      title: 'Import Type',
      icon: Icons.category_rounded,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildImportTypeChip('sales', 'Sales Data', Icons.point_of_sale),
          _buildImportTypeChip('stock', 'Stock Opening', Icons.inventory_2),
          _buildImportTypeChip('debtors', 'Debtors', Icons.people),
          _buildImportTypeChip('creditors', 'Creditors', Icons.business),
        ],
      ),
    );
  }

  Widget _buildImportTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedImportType == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedImportType = value),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildSourceFormatSelector() {
    return _buildCard(
      title: 'Source Format',
      icon: Icons.description_rounded,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildFormatChip(ImportSourceFormat.csv, 'CSV', Icons.table_chart),
          _buildFormatChip(ImportSourceFormat.xlsx, 'Excel (XLSX)', Icons.grid_on),
          _buildFormatChip(ImportSourceFormat.json, 'JSON', Icons.data_object),
          _buildFormatChip(ImportSourceFormat.tally, 'Tally XML', Icons.integration_instructions),
          _buildFormatChip(ImportSourceFormat.genericPos, 'Generic POS', Icons.point_of_sale),
        ],
      ),
    );
  }

  Widget _buildFormatChip(ImportSourceFormat format, String label, IconData icon) {
    final isSelected = _selectedSourceFormat == format;
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedSourceFormat = format),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return _buildCard(
      title: 'Select File',
      icon: Icons.folder_open_rounded,
      child: Column(
        children: [
          InkWell(
            onTap: _pickImportFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedImportFile != null 
                      ? const Color(0xFF10B981) 
                      : const Color(0xFFE2E8F0),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedImportFile != null 
                        ? Icons.check_circle_rounded 
                        : Icons.cloud_upload_rounded,
                    size: 48,
                    color: _selectedImportFile != null 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedImportFile != null 
                        ? _getFileName(_selectedImportFile!)
                        : 'Click to select file or drag and drop',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedImportFile != null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedImportFile != null 
                          ? const Color(0xFF10B981) 
                          : const Color(0xFF64748B),
                    ),
                  ),
                  if (_selectedImportFile == null)
                    const Text(
                      'Supports CSV, XLSX, JSON, XML files',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),
          if (_selectedImportFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedImportFile!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedImportFile = null),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedImportFile == null || _isImporting ? null : _performImport,
        icon: _isImporting 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download_rounded),
        label: Text(_isImporting ? 'Importing...' : 'Start Import'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildImportResultCard() {
    final result = _lastImportResult!;
    final isSuccess = result.successCount > 0 && result.errorCount == 0;
    final hasErrors = result.errorCount > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFECFDF5) : hasErrors ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? const Color(0xFF10B981) : hasErrors ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Import ${isSuccess ? "Completed" : "Completed with Issues"}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow('Total Records', result.totalRows.toString()),
          _buildResultRow('Imported', result.successCount.toString(), isSuccess: true),
          if (result.errorCount > 0)
            _buildResultRow('Errors', result.errorCount.toString(), isError: true),
          _buildResultRow('Success Rate', '${result.successRate.toStringAsFixed(1)}%'),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...result.errors.take(5).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• Row ${e.rowNumber}: ${e.message}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
              ),
            )),
            if (result.errors.length > 5)
              Text(
                '... and ${result.errors.length - 5} more errors',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isSuccess = false, bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF374151))),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSuccess ? const Color(0xFF10B981) : isError ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTemplates() {
    return _buildCard(
      title: 'Download Sample Templates',
      icon: Icons.file_download_rounded,
      child: Column(
        children: [
          const Text(
            'Download sample CSV templates to understand the expected data format for each import type.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTemplateButton('Sales', Icons.point_of_sale, () => _downloadTemplate('sales')),
              _buildTemplateButton('Stock', Icons.inventory_2, () => _downloadTemplate('stock')),
              _buildTemplateButton('Debtors', Icons.people, () => _downloadTemplate('debtors')),
              _buildTemplateButton('Creditors', Icons.business, () => _downloadTemplate('creditors')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3B82F6),
        side: const BorderSide(color: Color(0xFF3B82F6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ============================================================================
  // EXPORT TAB
  // ============================================================================

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExportTypeSelector(),
          const SizedBox(height: 20),
          _buildTargetAppSelector(),
          const SizedBox(height: 20),
          _buildExportFormatSelector(),
          const SizedBox(height: 20),
          _buildDateRangeSelector(),
          const SizedBox(height: 20),
          _buildExportButton(),
          if (_lastExportResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildExportResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildExportTypeSelector() {
    return _buildCard(
      title: 'Export Type',
      icon: Icons.category_rounded,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildExportTypeChip('sales', 'Sales', Icons.point_of_sale),
          _buildExportTypeChip('stock', 'Stock/Inventory', Icons.inventory_2),
          _buildExportTypeChip('customers', 'Customers', Icons.people),
          _buildExportTypeChip('all', 'Export All', Icons.select_all),
        ],
      ),
    );
  }

  Widget _buildExportTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedExportType == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedExportType = value),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildTargetAppSelector() {
    return _buildCard(
      title: 'Target Accounting Software',
      icon: Icons.apps_rounded,
      child: Column(
        children: [
          const Text(
            'Select the accounting software you want to import this data into.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: DataExportService.exportConfigs.entries.map((entry) {
              final isSelected = _selectedTargetApp == entry.key;
              return InkWell(
                onTap: () => setState(() => _selectedTargetApp = entry.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getAppIcon(entry.key),
                        size: 32,
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.value.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getAppIcon(String appKey) {
    switch (appKey) {
      case 'tally': return Icons.account_balance;
      case 'busy': return Icons.business_center;
      case 'zoho': return Icons.cloud;
      case 'quickbooks': return Icons.auto_stories;
      case 'marg': return Icons.shopping_bag;
      case 'generic': return Icons.file_copy;
      default: return Icons.apps;
    }
  }

  Widget _buildExportFormatSelector() {
    final config = DataExportService.exportConfigs[_selectedTargetApp];
    final supportedFormats = config?.supportedFormats ?? [ExportFormat.csv];
    
    return _buildCard(
      title: 'Export Format',
      icon: Icons.description_rounded,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: supportedFormats.map((format) {
          final isSelected = _selectedExportFormat == format;
          return FilterChip(
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedExportFormat = format),
            label: Text(_getFormatLabel(format)),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF10B981),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFormatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv: return 'CSV';
      case ExportFormat.json: return 'JSON';
      case ExportFormat.tally: return 'Tally XML';
      case ExportFormat.excel: return 'Excel';
    }
  }

  Widget _buildDateRangeSelector() {
    if (_selectedExportType == 'stock' || _selectedExportType == 'customers') {
      return const SizedBox.shrink();
    }
    
    return _buildCard(
      title: 'Date Range (Optional)',
      icon: Icons.date_range_rounded,
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(
              label: 'From Date',
              value: _exportFromDate,
              onTap: () => _pickDate(true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateField(
              label: 'To Date',
              value: _exportToDate,
              onTap: () => _pickDate(false),
            ),
          ),
          if (_exportFromDate != null || _exportToDate != null)
            IconButton(
              onPressed: () => setState(() {
                _exportFromDate = null;
                _exportToDate = null;
              }),
              icon: const Icon(Icons.clear),
              tooltip: 'Clear dates',
            ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              value != null 
                  ? DateFormat('dd MMM yyyy').format(value) 
                  : label,
              style: TextStyle(
                color: value != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _performExport,
        icon: _isExporting 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.upload_rounded),
        label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildExportResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
              SizedBox(width: 12),
              Text(
                'Export Completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._lastExportResults.map((result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getExportTypeIcon(result.exportType), size: 16, color: const Color(0xFF059669)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.exportType} - ${result.recordCount} records',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        result.filePath,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openExportFolder(result.filePath),
                  icon: const Icon(Icons.folder_open, size: 20),
                  tooltip: 'Open folder',
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  IconData _getExportTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sales': return Icons.point_of_sale;
      case 'stock': return Icons.inventory_2;
      case 'customers': return Icons.people;
      default: return Icons.file_copy;
    }
  }

  // ============================================================================
  // COMMON WIDGETS
  // ============================================================================

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'json', 'xml'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImportFile = result.files.first.path;
        // Auto-detect format based on extension
        final ext = result.files.first.extension?.toLowerCase();
        switch (ext) {
          case 'csv':
            _selectedSourceFormat = ImportSourceFormat.csv;
            break;
          case 'xlsx':
          case 'xls':
            _selectedSourceFormat = ImportSourceFormat.xlsx;
            break;
          case 'json':
            _selectedSourceFormat = ImportSourceFormat.json;
            break;
          case 'xml':
            _selectedSourceFormat = ImportSourceFormat.tally;
            break;
        }
      });
    }
  }

  Future<void> _performImport() async {
    if (_selectedImportFile == null) return;
    
    setState(() => _isImporting = true);
    
    try {
      final importService = DataImportService.instance;
      ImportResult result;
      
      switch (_selectedImportType) {
        case 'sales':
          result = await importService.importSales(
            _selectedImportFile!,
            format: _selectedSourceFormat,
          );
          break;
        case 'stock':
          result = await importService.importStockOpening(
            _selectedImportFile!,
            format: _selectedSourceFormat,
          );
          break;
        case 'debtors':
          result = await importService.importLedgerOpeningBalances(
            _selectedImportFile!,
            'debtor',
            format: _selectedSourceFormat,
          );
          break;
        case 'creditors':
          result = await importService.importLedgerOpeningBalances(
            _selectedImportFile!,
            'creditor',
            format: _selectedSourceFormat,
          );
          break;
        default:
          throw Exception('Unknown import type');
      }
      
      setState(() {
        _lastImportResult = result;
        _selectedImportFile = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import completed: ${result.successCount} of ${result.totalRows} records imported'),
            backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);
    
    try {
      final exportService = DataExportService.instance;
      List<ExportResult> results = [];
      
      switch (_selectedExportType) {
        case 'sales':
          results.add(await exportService.exportSales(
            targetApp: _selectedTargetApp,
            format: _selectedExportFormat,
            fromDate: _exportFromDate,
            toDate: _exportToDate,
          ));
          break;
        case 'stock':
          results.add(await exportService.exportStock(
            targetApp: _selectedTargetApp,
            format: _selectedExportFormat,
          ));
          break;
        case 'customers':
          results.add(await exportService.exportCustomers(
            targetApp: _selectedTargetApp,
            format: _selectedExportFormat,
          ));
          break;
        case 'all':
          results.add(await exportService.exportSales(
            targetApp: _selectedTargetApp,
            format: _selectedExportFormat,
            fromDate: _exportFromDate,
            toDate: _exportToDate,
          ));
          results.add(await exportService.exportStock(
            targetApp: _selectedTargetApp,
            format: _selectedExportFormat,
          ));
          results.add(await exportService.exportCustomers(
            targetApp: _selectedTargetApp,
            format: _selectedExportFormat,
          ));
          break;
      }
      
      setState(() => _lastExportResults = results);
      
      if (mounted) {
        final totalRecords = results.fold<int>(0, (sum, r) => sum + r.recordCount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export completed: $totalRecords records exported'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _downloadTemplate(String type) async {
    try {
      final importService = DataImportService.instance;
      String content;
      String filename;
      
      switch (type) {
        case 'sales':
          content = importService.generateSalesTemplate();
          filename = 'sales_import_template.csv';
          break;
        case 'stock':
          content = importService.generateStockOpeningTemplate();
          filename = 'stock_opening_template.csv';
          break;
        case 'debtors':
          content = importService.generateLedgerTemplate('debtor');
          filename = 'debtors_template.csv';
          break;
        case 'creditors':
          content = importService.generateLedgerTemplate('creditor');
          filename = 'creditors_template.csv';
          break;
        default:
          throw Exception('Unknown template type');
      }
      
      // Save to user's Documents folder
      String templateDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        templateDir = '$userProfile\\Documents\\BillEase Templates';
      } else {
        templateDir = '/tmp/BillEase Templates';
      }
      
      final dir = Directory(templateDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final filePath = Platform.isWindows 
          ? '$templateDir\\$filename' 
          : '$templateDir/$filename';
      final file = File(filePath);
      await file.writeAsString(content);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template saved to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openExportFolder(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (_exportFromDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_exportToDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _exportFromDate = picked;
        } else {
          _exportToDate = picked;
        }
      });
    }
  }

  Future<void> _openExportFolder(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      }
    } catch (e) {
      debugPrint('Failed to open folder: $e');
    }
  }

  String _getFileName(String path) {
    return path.split(Platform.isWindows ? '\\' : '/').last;
  }
}
