/// Settings Screen - BillEase Accounts+
/// Application settings and master data management
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'party_master_screen.dart';
import 'settings_subscreens.dart';
import 'data_import_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Masters Section
          _buildSectionHeader(context, 'Masters', Icons.folder_special),
          const SizedBox(height: 8),
          _buildMastersCard(context),
          
          const SizedBox(height: 24),
          
          // Company Settings Section
          _buildSectionHeader(context, 'Company', Icons.business),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                icon: Icons.business_center,
                title: 'Company Profile',
                subtitle: 'Business name, GSTIN, PAN, Pincode, address',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyProfileScreen())),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.print,
                title: 'Invoice Settings',
                subtitle: 'Templates, numbering, terms',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen())),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.image,
                title: 'Logo & Branding',
                subtitle: 'Invoice logo, signature',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogoBrandingScreen())),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // GST Settings Section
          _buildSectionHeader(context, 'GST & Tax', Icons.account_balance),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                icon: Icons.percent,
                title: 'GST Rates',
                subtitle: 'Default tax slabs configuration',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GSTRatesScreen())),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.category,
                title: 'HSN/SAC Codes',
                subtitle: 'Manage product codes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HSNCodesScreen())),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Backup & Sync Section
          _buildSectionHeader(context, 'Backup & Sync', Icons.cloud),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                icon: Icons.upload_file,
                title: 'Import Data',
                subtitle: 'Import from POS, Tally, or CSV files',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataImportScreen())),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.backup,
                title: 'Backup Data',
                subtitle: 'Export data to file',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen())),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.restore,
                title: 'Restore Data',
                subtitle: 'Import from backup file',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen())),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader(context, 'About', Icons.info),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About BillEase',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMastersCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildMasterTile(
            context,
            icon: Icons.groups,
            title: 'Party Master',
            subtitle: 'Customers, Suppliers, Employees',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PartyMasterScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMasterTile(
            context,
            icon: Icons.inventory_2,
            title: 'Item Master',
            subtitle: 'Products, Services, Stock Items',
            color: Colors.green,
            onTap: () => _showComingSoon(context, 'Item Master'),
          ),
          const Divider(height: 1),
          _buildMasterTile(
            context,
            icon: Icons.account_tree,
            title: 'Ledger Groups',
            subtitle: 'Account groups hierarchy',
            color: Colors.orange,
            onTap: () => _showComingSoon(context, 'Ledger Groups'),
          ),
          const Divider(height: 1),
          _buildMasterTile(
            context,
            icon: Icons.straighten,
            title: 'Units of Measure',
            subtitle: 'Pcs, Kg, Box, Dozen, etc.',
            color: Colors.purple,
            onTap: () => _showComingSoon(context, 'Units'),
          ),
          const Divider(height: 1),
          _buildMasterTile(
            context,
            icon: Icons.warehouse,
            title: 'Godowns / Locations',
            subtitle: 'Stock storage locations',
            color: Colors.teal,
            onTap: () => _showComingSoon(context, 'Godowns'),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.slate600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BillEase Accounts+',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.receipt_long, color: Colors.white, size: 32),
      ),
      children: [
        const SizedBox(height: 16),
        const Text('Complete GST Billing & Accounting Solution'),
        const SizedBox(height: 8),
        Text(
          '© 2026 Vyoumix Technologies',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
