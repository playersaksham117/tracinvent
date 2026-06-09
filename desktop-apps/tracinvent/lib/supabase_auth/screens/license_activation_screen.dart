import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_auth_provider.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() =>
      _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final _keyCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyCtrl.text.trim().toUpperCase();
    if (key.isEmpty) return;
    final ok =
        await context.read<SupabaseAuthProvider>().activateLicense(key);
    if (ok && mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Consumer<SupabaseAuthProvider>(
                builder: (context, p, _) =>
                    _submitted ? _successView(p) : _formView(p),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView(SupabaseAuthProvider p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vpn_key, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activate License',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Enter your license key to unlock TracInvent',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('License Key',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _keyCtrl,
          decoration: const InputDecoration(
            hintText: 'TRINV-XXXX-XXXX-XXXX',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            // Auto-format as TRINV-XXXX-XXXX-XXXX
            final digits = v.replaceAll('-', '').replaceAll(' ', '');
            if (digits.length > 5 && !v.startsWith('TRINV-')) return;
          },
        ),
        const SizedBox(height: 8),
        Text('Format: TRINV-XXXXXXXX-XXXXXXXX-XXXXXXXX',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        _licenseComparisonTable(),
        const SizedBox(height: 24),
        if (p.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(p.error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          ),
        FilledButton.icon(
          onPressed: p.loading ? null : _activate,
          icon: p.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: Text(p.loading ? 'Activating...' : 'Activate'),
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.read<SupabaseAuthProvider>().logout(),
          child:
              const Text('Sign out', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _successView(SupabaseAuthProvider p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified, color: Colors.green, size: 60),
        const SizedBox(height: 16),
        const Text('License Activated!',
            style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Plan: ${p.profile?.licenseType.toUpperCase() ?? 'Pro'}',
          style: const TextStyle(fontSize: 16, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 8),
        Text(
          'This device is now registered and bound to your license.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () {},  // AuthGate will redirect automatically
          child: const Text('Open TracInvent'),
        ),
      ],
    );
  }

  Widget _licenseComparisonTable() {
    final plans = [
      {'name': 'Free', 'devices': '1', 'price': 'Free'},
      {'name': 'Basic', 'devices': '2', 'price': '₹999/yr'},
      {'name': 'Pro', 'devices': '5', 'price': '₹2,499/yr'},
      {'name': 'Lifetime', 'devices': '10', 'price': '₹9,999'},
    ];
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('License Plans',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade200),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration:
                  BoxDecoration(color: Colors.grey.shade50),
              children: ['Plan', 'Devices', 'Price']
                  .map((h) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(h,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ))
                  .toList(),
            ),
            ...plans.map(
              (p) => TableRow(
                children: [
                  _cell(p['name']!),
                  _cell(p['devices']!),
                  _cell(p['price']!),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );
}
