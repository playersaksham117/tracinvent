import 'package:flutter/material.dart';
import 'account_type_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Navigate to account type setup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AccountTypeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.insights,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                _isSignIn ? 'Welcome back' : 'Get started',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _isSignIn 
                    ? 'Sign in to see your finances' 
                    : 'Create your account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'your@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    if (_isSignIn) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    FilledButton(
                      onPressed: _submit,
                      child: Text(_isSignIn ? 'Sign In' : 'Create Account'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Toggle Sign In/Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignIn 
                              ? "Don't have an account? " 
                              : "Already have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignIn = !_isSignIn;
                            });
                          },
                          child: Text(_isSignIn ? 'Sign Up' : 'Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
