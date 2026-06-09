import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_auth_provider.dart';
import 'email_verification_screen.dart';

class SupabaseRegisterScreen extends StatefulWidget {
  const SupabaseRegisterScreen({super.key});

  @override
  State<SupabaseRegisterScreen> createState() => _SupabaseRegisterScreenState();
}

class _SupabaseRegisterScreenState extends State<SupabaseRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _email   = TextEditingController();
  final _mobile  = TextEditingController();
  final _company = TextEditingController();
  final _pass    = TextEditingController();
  final _pin     = TextEditingController();
  String _country = 'IN';
  bool _obscurePass = true;
  bool _obscurePin  = true;

  static const _countries = ['IN', 'US', 'GB', 'AE', 'SG', 'AU', 'CA', 'Other'];

  @override
  void dispose() {
    for (final c in [_name, _email, _mobile, _company, _pass, _pin]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final provider = context.read<SupabaseAuthProvider>();
    final ok = await provider.register(
      email: _email.text.trim(),
      password: _pass.text,
      fullName: _name.text.trim(),
      mobile: _mobile.text.trim(),
      country: _country,
      company: _company.text.trim().isEmpty ? null : _company.text.trim(),
      pin: _pin.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: _email.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Create Account',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('TracInvent — Inventory Management System',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 28),
                    _field(_name, 'Full Name *', validator: _required),
                    const SizedBox(height: 12),
                    _field(_email, 'Email *',
                        keyboard: TextInputType.emailAddress,
                        validator: _emailValidator),
                    const SizedBox(height: 12),
                    _field(_mobile, 'Mobile Number *',
                        keyboard: TextInputType.phone, validator: _required),
                    const SizedBox(height: 12),
                    _field(_company, 'Company Name (optional)'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: 'Country *', border: OutlineInputBorder()),
                      value: _country,
                      items: _countries
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _country = v ?? 'IN'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 8
                          ? 'Minimum 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pin,
                      obscureText: _obscurePin,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '6-digit Security PIN *',
                        border: const OutlineInputBorder(),
                        counterText: '',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length != 6) return 'Enter exactly 6 digits';
                        if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<SupabaseAuthProvider>(
                      builder: (context, p, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (p.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(p.error!,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          FilledButton(
                            onPressed: p.loading ? null : _submit,
                            child: p.loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Create Account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      validator: validator,
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Invalid email';
    return null;
  }
}
