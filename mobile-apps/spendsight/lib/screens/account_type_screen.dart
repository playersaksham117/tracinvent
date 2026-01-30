import 'package:flutter/material.dart';
import 'home_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String? _selectedType;

  final List<Map<String, dynamic>> _accountTypes = [
    {
      'id': 'personal',
      'title': 'Just Me',
      'subtitle': 'Track your personal spending',
      'icon': Icons.person_outline,
    },
    {
      'id': 'family',
      'title': 'Family',
      'subtitle': 'Manage household money together',
      'icon': Icons.people_outline,
    },
    {
      'id': 'couple',
      'title': 'Couple',
      'subtitle': 'Share finances with your partner',
      'icon': Icons.favorite_outline,
    },
  ];

  void _continue() {
    if (_selectedType != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Who\'s using SpendSight?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Choose how you\'ll track your money',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Account Type Cards
              Expanded(
                child: ListView.separated(
                  itemCount: _accountTypes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final type = _accountTypes[index];
                    final isSelected = _selectedType == type['id'];
                    
                    return Card(
                      elevation: isSelected ? 4 : 0,
                      color: isSelected 
                          ? colorScheme.primaryContainer 
                          : colorScheme.surfaceVariant,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedType = type['id'];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? colorScheme.primary 
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  type['icon'],
                                  size: 32,
                                  color: isSelected 
                                      ? colorScheme.onPrimary 
                                      : colorScheme.onSurface,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type['title'],
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['subtitle'],
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue Button
              FilledButton(
                onPressed: _selectedType != null ? _continue : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
