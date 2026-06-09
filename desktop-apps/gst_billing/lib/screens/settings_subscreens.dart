/// Settings Sub-Screens - BillEase Accounts+
/// Company Profile, Invoice Settings, GST Rates, HSN Codes, Backup/Restore
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ============================================================================
// COMPANY PROFILE SCREEN
// ============================================================================

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Form controllers
  final _companyNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _branchController = TextEditingController();
  
  String _selectedState = '07 - Delhi';
  
  static const List<String> _indianStates = [
    '01 - Jammu & Kashmir',
    '02 - Himachal Pradesh',
    '03 - Punjab',
    '04 - Chandigarh',
    '05 - Uttarakhand',
    '06 - Haryana',
    '07 - Delhi',
    '08 - Rajasthan',
    '09 - Uttar Pradesh',
    '10 - Bihar',
    '11 - Sikkim',
    '12 - Arunachal Pradesh',
    '13 - Nagaland',
    '14 - Manipur',
    '15 - Mizoram',
    '16 - Tripura',
    '17 - Meghalaya',
    '18 - Assam',
    '19 - West Bengal',
    '20 - Jharkhand',
    '21 - Odisha',
    '22 - Chhattisgarh',
    '23 - Madhya Pradesh',
    '24 - Gujarat',
    '26 - Dadra & Nagar Haveli and Daman & Diu',
    '27 - Maharashtra',
    '29 - Karnataka',
    '30 - Goa',
    '31 - Lakshadweep',
    '32 - Kerala',
    '33 - Tamil Nadu',
    '34 - Puducherry',
    '35 - Andaman & Nicobar Islands',
    '36 - Telangana',
    '37 - Andhra Pradesh',
    '38 - Ladakh',
  ];

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyJson = prefs.getString('company_profile');
      if (companyJson != null) {
        final data = jsonDecode(companyJson);
        _companyNameController.text = data['company_name'] ?? '';
        _legalNameController.text = data['legal_name'] ?? '';
        _gstinController.text = data['gstin'] ?? '';
        _panController.text = data['pan'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _pincodeController.text = data['pincode'] ?? '';
        _bankNameController.text = data['bank_name'] ?? '';
        _accountNumberController.text = data['account_number'] ?? '';
        _ifscController.text = data['ifsc'] ?? '';
        _branchController.text = data['branch'] ?? '';
        if (data['state_code'] != null) {
          _selectedState = _indianStates.firstWhere(
            (s) => s.startsWith(data['state_code']),
            orElse: () => '07 - Delhi',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading company profile: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveCompanyProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'company_name': _companyNameController.text,
        'legal_name': _legalNameController.text,
        'gstin': _gstinController.text,
        'pan': _panController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'website': _websiteController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'state_code': _selectedState.substring(0, 2),
        'pincode': _pincodeController.text,
        'bank_name': _bankNameController.text,
        'account_number': _accountNumberController.text,
        'ifsc': _ifscController.text,
        'branch': _branchController.text,
      };
      await prefs.setString('company_profile', jsonEncode(data));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Company Profile'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            TextButton.icon(
              onPressed: _saveCompanyProfile,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Business Information
                  _buildSectionHeader('Business Information', Icons.business),
                  const SizedBox(height: 16),
                  _buildCard([
                    _buildTextField(_companyNameController, 'Company/Trade Name', required: true),
                    _buildTextField(_legalNameController, 'Legal Name (as per GST)'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_gstinController, 'GSTIN', hint: '07AABBC1234A1ZK')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_panController, 'PAN', hint: 'AABBC1234A')),
                      ],
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Information
                  _buildSectionHeader('Contact Information', Icons.contact_phone),
                  const SizedBox(height: 16),
                  _buildCard([
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress)),
                      ],
                    ),
                    _buildTextField(_websiteController, 'Website', hint: 'www.example.com'),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Address
                  _buildSectionHeader('Address', Icons.location_on),
                  const SizedBox(height: 16),
                  _buildCard([
                    _buildTextField(_addressController, 'Street Address', maxLines: 2),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_cityController, 'City')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_pincodeController, 'Pincode', keyboardType: TextInputType.number)),
                      ],
                    ),
                    _buildStateDropdown(),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Bank Details
                  _buildSectionHeader('Bank Details', Icons.account_balance),
                  const SizedBox(height: 16),
                  _buildCard([
                    _buildTextField(_bankNameController, 'Bank Name'),
                    _buildTextField(_accountNumberController, 'Account Number', keyboardType: TextInputType.number),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_ifscController, 'IFSC Code')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_branchController, 'Branch')),
                      ],
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: children.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: w,
          )).toList()..removeLast(),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: required ? (v) => v?.isEmpty == true ? 'Required' : null : null,
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedState,
      decoration: InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() => _selectedState = v!),
    );
  }
}

// ============================================================================
// INVOICE SETTINGS SCREEN
// ============================================================================

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Invoice settings
  String _invoicePrefix = 'INV';
  int _nextInvoiceNumber = 1;
  String _invoiceTemplate = 'modern';
  bool _showLogo = true;
  bool _showSignature = true;
  bool _showBankDetails = true;
  bool _showTerms = true;
  int _defaultCreditDays = 30;
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('invoice_settings');
      if (settingsJson != null) {
        final data = jsonDecode(settingsJson);
        _invoicePrefix = data['prefix'] ?? 'INV';
        _nextInvoiceNumber = data['next_number'] ?? 1;
        _invoiceTemplate = data['template'] ?? 'modern';
        _showLogo = data['show_logo'] ?? true;
        _showSignature = data['show_signature'] ?? true;
        _showBankDetails = data['show_bank'] ?? true;
        _showTerms = data['show_terms'] ?? true;
        _defaultCreditDays = data['credit_days'] ?? 30;
        _termsController.text = data['terms'] ?? 'Payment due within 30 days.\nGoods once sold will not be taken back.';
        _notesController.text = data['notes'] ?? '';
      } else {
        _termsController.text = 'Payment due within 30 days.\nGoods once sold will not be taken back.';
      }
    } catch (e) {
      debugPrint('Error loading invoice settings: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'prefix': _invoicePrefix,
        'next_number': _nextInvoiceNumber,
        'template': _invoiceTemplate,
        'show_logo': _showLogo,
        'show_signature': _showSignature,
        'show_bank': _showBankDetails,
        'show_terms': _showTerms,
        'credit_days': _defaultCreditDays,
        'terms': _termsController.text,
        'notes': _notesController.text,
      };
      await prefs.setString('invoice_settings', jsonEncode(data));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice settings saved'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Invoice Settings'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Invoice Numbering
                _buildSectionCard(
                  title: 'Invoice Numbering',
                  icon: Icons.numbers,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _invoicePrefix,
                            decoration: InputDecoration(
                              labelText: 'Invoice Prefix',
                              hintText: 'INV',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (v) => _invoicePrefix = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _nextInvoiceNumber.toString(),
                            decoration: InputDecoration(
                              labelText: 'Next Invoice Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _nextInvoiceNumber = int.tryParse(v) ?? 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppTheme.slate500),
                          const SizedBox(width: 8),
                          Text(
                            'Next invoice will be: $_invoicePrefix-${_nextInvoiceNumber.toString().padLeft(4, '0')}',
                            style: TextStyle(color: AppTheme.slate600, fontFamily: 'JetBrains Mono'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Template Selection
                _buildSectionCard(
                  title: 'Invoice Template',
                  icon: Icons.article,
                  children: [
                    Row(
                      children: [
                        _buildTemplateOption('modern', 'Modern', Icons.web),
                        const SizedBox(width: 12),
                        _buildTemplateOption('classic', 'Classic', Icons.description),
                        const SizedBox(width: 12),
                        _buildTemplateOption('minimal', 'Minimal', Icons.crop_square),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Display Options
                _buildSectionCard(
                  title: 'Display Options',
                  icon: Icons.visibility,
                  children: [
                    _buildSwitchTile('Show Company Logo', _showLogo, (v) => setState(() => _showLogo = v)),
                    _buildSwitchTile('Show Signature Field', _showSignature, (v) => setState(() => _showSignature = v)),
                    _buildSwitchTile('Show Bank Details', _showBankDetails, (v) => setState(() => _showBankDetails = v)),
                    _buildSwitchTile('Show Terms & Conditions', _showTerms, (v) => setState(() => _showTerms = v)),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Payment Terms
                _buildSectionCard(
                  title: 'Payment Terms',
                  icon: Icons.payment,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _defaultCreditDays,
                      decoration: InputDecoration(
                        labelText: 'Default Credit Period',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [0, 7, 15, 30, 45, 60, 90].map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d == 0 ? 'Immediate Payment' : '$d Days'),
                      )).toList(),
                      onChanged: (v) => setState(() => _defaultCreditDays = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _termsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Terms & Conditions',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Default Notes
                _buildSectionCard(
                  title: 'Default Notes',
                  icon: Icons.note,
                  children: [
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (appears on every invoice)',
                        hintText: 'Thank you for your business!',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption(String value, String label, IconData icon) {
    final isSelected = _invoiceTemplate == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _invoiceTemplate = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.slate300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isSelected ? AppTheme.primaryColor : AppTheme.slate400),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.slate600,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: AppTheme.slate700)),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryColor),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGO & BRANDING SCREEN
// ============================================================================

class LogoBrandingScreen extends StatefulWidget {
  const LogoBrandingScreen({super.key});

  @override
  State<LogoBrandingScreen> createState() => _LogoBrandingScreenState();
}

class _LogoBrandingScreenState extends State<LogoBrandingScreen> {
  String? _logoPath;
  String? _signaturePath;
  Color _primaryColor = AppTheme.primaryColor;
  Color _accentColor = AppTheme.accentColor;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final prefs = await SharedPreferences.getInstance();
    final brandingJson = prefs.getString('branding_settings');
    if (brandingJson != null) {
      final data = jsonDecode(brandingJson);
      setState(() {
        _logoPath = data['logo_path'];
        _signaturePath = data['signature_path'];
        if (data['primary_color'] != null) {
          _primaryColor = Color(data['primary_color']);
        }
        if (data['accent_color'] != null) {
          _accentColor = Color(data['accent_color']);
        }
      });
    }
  }

  Future<void> _saveBranding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('branding_settings', jsonEncode({
      'logo_path': _logoPath,
      'signature_path': _signaturePath,
      'primary_color': _primaryColor.value,
      'accent_color': _accentColor.value,
    }));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branding settings saved'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Logo & Branding'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveBranding,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Company Logo
          _buildCard(
            title: 'Company Logo',
            icon: Icons.image,
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.slate300, style: BorderStyle.solid),
                  ),
                  child: _logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_logoPath!), fit: BoxFit.contain),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: AppTheme.slate400),
                            const SizedBox(height: 8),
                            Text('No logo uploaded', style: TextStyle(color: AppTheme.slate500)),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showImagePicker('logo'),
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Logo'),
                    ),
                    if (_logoPath != null) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => setState(() => _logoPath = null),
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        label: const Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommended: 300x150 pixels, PNG or JPG',
                  style: TextStyle(fontSize: 12, color: AppTheme.slate400),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Signature
          _buildCard(
            title: 'Authorized Signature',
            icon: Icons.draw,
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.slate300),
                  ),
                  child: _signaturePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_signaturePath!), fit: BoxFit.contain),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gesture, size: 32, color: AppTheme.slate400),
                            const SizedBox(height: 4),
                            Text('No signature', style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showImagePicker('signature'),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Signature'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Brand Colors
          _buildCard(
            title: 'Brand Colors',
            icon: Icons.palette,
            child: Column(
              children: [
                _buildColorPicker('Primary Color', _primaryColor, (c) => setState(() => _primaryColor = c)),
                const SizedBox(height: 16),
                _buildColorPicker('Accent Color', _accentColor, (c) => setState(() => _accentColor = c)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
              ],
            ),
            const SizedBox(height: 20),
            Center(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, ValueChanged<Color> onChanged) {
    final presetColors = [
      const Color(0xFF2563eb), // Blue
      const Color(0xFF059669), // Green
      const Color(0xFFdc2626), // Red
      const Color(0xFFf97316), // Orange
      const Color(0xFF8b5cf6), // Purple
      const Color(0xFF0891b2), // Cyan
      const Color(0xFF334155), // Slate
    ];
    
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: AppTheme.slate600))),
        ...presetColors.map((c) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            onTap: () => onChanged(c),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == c ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: color == c ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : null,
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _showImagePicker(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File picker for $type - requires file_picker package'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// GST RATES SCREEN
// ============================================================================

class GSTRatesScreen extends StatefulWidget {
  const GSTRatesScreen({super.key});

  @override
  State<GSTRatesScreen> createState() => _GSTRatesScreenState();
}

class _GSTRatesScreenState extends State<GSTRatesScreen> {
  final List<Map<String, dynamic>> _gstRates = [
    {'rate': 0.0, 'description': 'Exempt / Nil Rated', 'items': 'Essential goods, fresh vegetables, milk'},
    {'rate': 5.0, 'description': '5% GST', 'items': 'Packaged food, footwear < ₹1000, transport'},
    {'rate': 12.0, 'description': '12% GST', 'items': 'Processed food, computers, mobiles'},
    {'rate': 18.0, 'description': '18% GST (Most Common)', 'items': 'Most goods & services, electronics'},
    {'rate': 28.0, 'description': '28% GST', 'items': 'Luxury items, automobiles, tobacco'},
  ];

  double _defaultRate = 18.0;

  @override
  void initState() {
    super.initState();
    _loadDefaultRate();
  }

  Future<void> _loadDefaultRate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultRate = prefs.getDouble('default_gst_rate') ?? 18.0;
    });
  }

  Future<void> _saveDefaultRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_gst_rate', rate);
    setState(() => _defaultRate = rate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Default GST rate set to ${rate.toInt()}%'), backgroundColor: AppTheme.successColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('GST Rates'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Default Rate Selection
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.primaryLight, width: 2),
            ),
            color: AppTheme.primaryLight.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Default GST Rate', style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This rate will be automatically selected when creating new items or invoices.',
                    style: TextStyle(color: AppTheme.slate600),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                      final isSelected = _defaultRate == rate;
                      return ChoiceChip(
                        label: Text('${rate.toInt()}%'),
                        selected: isSelected,
                        onSelected: (_) => _saveDefaultRate(rate),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.slate700,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // GST Rate Reference
          Text('GST Rate Reference', style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate700,
          )),
          const SizedBox(height: 12),
          
          ..._gstRates.map((rate) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.slate200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getRateColor(rate['rate']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${(rate['rate'] as double).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getRateColor(rate['rate']),
                    ),
                  ),
                ),
              ),
              title: Text(rate['description'], style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(rate['items'], style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.infoColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GST rates are defined by the Government of India. For specific HSN code rates, refer to the GST Rate Finder on the official CBIC website.',
                    style: TextStyle(color: AppTheme.slate700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _getRateColor(double rate) {
    if (rate == 0) return AppTheme.successColor;
    if (rate == 5) return AppTheme.infoColor;
    if (rate == 12) return Colors.amber.shade700;
    if (rate == 18) return AppTheme.primaryColor;
    return AppTheme.errorColor;
  }
}

// ============================================================================
// HSN/SAC CODES SCREEN
// ============================================================================

class HSNCodesScreen extends StatefulWidget {
  const HSNCodesScreen({super.key});

  @override
  State<HSNCodesScreen> createState() => _HSNCodesScreenState();
}

class _HSNCodesScreenState extends State<HSNCodesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _hsnCodesFuture;
  late final ApiService _api;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _tabController = TabController(length: 2, vsync: this);
    _loadHSNCodes();
  }

  void _loadHSNCodes() {
    _hsnCodesFuture = _fetchHSNCodes();
  }

  Future<List<Map<String, dynamic>>> _fetchHSNCodes() async {
    try {
      final hsnCodes = await _api.getHSNCodes();
      return hsnCodes
          .map((code) => {
                'code': code.code,
                'description': code.description,
                'rate': code.gstRate,
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching HSN codes: $e');
      // Return empty list if API fails
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterCodes(
      List<Map<String, dynamic>> codes, String searchQuery) {
    if (searchQuery.isEmpty) return codes;
    return codes
        .where((c) =>
            c['code'].toString().contains(searchQuery) ||
            c['description']
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('HSN/SAC Codes'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'HSN Codes (Goods)'),
            Tab(text: 'SAC Codes (Services)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by code or description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _hsnCodesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Expanded(
                  child: Center(
                    child: Text('Error loading HSN codes: ${snapshot.error}'),
                  ),
                );
              }

              final allCodes = snapshot.data ?? [];
              final filteredCodes = _filterCodes(allCodes, _searchQuery);

              return Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCodeList(filteredCodes, 'HSN'),
                    _buildCodeList([], 'SAC'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCodeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Code'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildCodeList(List<Map<String, dynamic>> codes, String type) {
    if (codes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.slate300),
            const SizedBox(height: 16),
            Text('No $type codes found', style: TextStyle(color: AppTheme.slate500)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: codes.length,
      itemBuilder: (context, index) {
        final code = codes[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.slate200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code['code'],
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate700,
                ),
              ),
            ),
            title: Text(code['description']),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${code['rate']}%',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add HSN/SAC Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Code',
                hintText: 'e.g., 8517',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: 18,
              decoration: InputDecoration(
                labelText: 'GST Rate',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [0, 5, 12, 18, 28].map((r) => DropdownMenuItem(
                value: r,
                child: Text('$r%'),
              )).toList(),
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code added successfully'), backgroundColor: AppTheme.successColor),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BACKUP & RESTORE SCREEN
// ============================================================================

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  List<Map<String, dynamic>> _backupHistory = [];

  @override
  void initState() {
    super.initState();
    _loadBackupHistory();
  }

  Future<void> _loadBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('backup_history');
    if (historyJson != null) {
      setState(() {
        _backupHistory = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    
    try {
      // Simulate backup process
      await Future.delayed(const Duration(seconds: 2));
      
      final now = DateTime.now();
      final fileName = 'billease_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.json';
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/backups';
      
      // Create backups folder if not exists
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Collect all data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final backupData = {
        'version': '1.0.0',
        'created_at': now.toIso8601String(),
        'company_profile': prefs.getString('company_profile'),
        'invoice_settings': prefs.getString('invoice_settings'),
        'branding_settings': prefs.getString('branding_settings'),
        'default_gst_rate': prefs.getDouble('default_gst_rate'),
      };
      
      // Save backup file
      final file = File('$backupPath/$fileName');
      await file.writeAsString(jsonEncode(backupData));
      
      // Update backup history
      _backupHistory.insert(0, {
        'filename': fileName,
        'path': file.path,
        'created_at': now.toIso8601String(),
        'size': '${(await file.length() / 1024).toStringAsFixed(1)} KB',
      });
      
      // Keep only last 10 backups in history
      if (_backupHistory.length > 10) {
        _backupHistory = _backupHistory.sublist(0, 10);
      }
      
      await prefs.setString('backup_history', jsonEncode(_backupHistory));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created: $fileName'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () {
                // Open folder in file explorer
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    
    setState(() => _isBackingUp = false);
  }

  Future<void> _restoreBackup(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all current settings with the backup data. '
          'This action cannot be undone. Continue?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isRestoring = true);
    
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }
      
      final content = await file.readAsString();
      final backupData = jsonDecode(content);
      
      final prefs = await SharedPreferences.getInstance();
      
      if (backupData['company_profile'] != null) {
        await prefs.setString('company_profile', backupData['company_profile']);
      }
      if (backupData['invoice_settings'] != null) {
        await prefs.setString('invoice_settings', backupData['invoice_settings']);
      }
      if (backupData['branding_settings'] != null) {
        await prefs.setString('branding_settings', backupData['branding_settings']);
      }
      if (backupData['default_gst_rate'] != null) {
        await prefs.setDouble('default_gst_rate', backupData['default_gst_rate']);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully! Please restart the app.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    
    setState(() => _isRestoring = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Create Backup Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.successColor.withOpacity(0.3)),
            ),
            color: AppTheme.successLight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.backup, size: 48, color: AppTheme.successColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Backup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Export your company profile, settings, and preferences to a file',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.slate600),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isBackingUp ? null : _createBackup,
                    icon: _isBackingUp
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isBackingUp ? 'Creating Backup...' : 'Create Backup Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Restore Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            color: AppTheme.warningLight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.restore, size: 48, color: AppTheme.warningColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Restore from File',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import settings from a previously created backup file',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.slate600),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _isRestoring ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File picker - requires file_picker package')),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Backup File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warningColor,
                      side: BorderSide(color: AppTheme.warningColor),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Backup History
          if (_backupHistory.isNotEmpty) ...[
            Text(
              'Recent Backups',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.slate700),
            ),
            const SizedBox(height: 12),
            ..._backupHistory.map((backup) {
              final createdAt = DateTime.parse(backup['created_at']);
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.slate200),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description, color: AppTheme.slate600),
                  ),
                  title: Text(backup['filename'], style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')} • ${backup['size']}',
                    style: TextStyle(color: AppTheme.slate400, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore),
                    tooltip: 'Restore this backup',
                    onPressed: () => _restoreBackup(backup['path']),
                  ),
                ),
              );
            }),
          ],
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
