import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _currency = 'USD';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Profile Card
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          'JD',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'John Doe',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'john.doe@email.com',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: colorScheme.onPrimaryContainer,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // General Settings
              Text(
                'General',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Currency'),
                      subtitle: Text(_currency),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showCurrencyPicker();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Account Settings
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Account Type'),
                      subtitle: const Text('Just Me'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Sync & Backup'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Privacy & Security'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Support
              Text(
                'Support',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help Center'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback_outlined),
                      title: const Text('Send Feedback'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('Version 1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Danger Zone
              Card(
                color: colorScheme.errorContainer,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      title: Text(
                        'Delete All Data',
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colorScheme.onErrorContainer,
                      ),
                      onTap: () {
                        _showDeleteConfirmation();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign Out Button
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
                child: const Text('Sign Out'),
              ),
              
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select Currency',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...['USD', 'EUR', 'GBP', 'JPY', 'CNY'].map((currency) {
                return ListTile(
                  title: Text(currency),
                  trailing: _currency == currency 
                      ? const Icon(Icons.check, color: Colors.green) 
                      : null,
                  onTap: () {
                    setState(() {
                      _currency = currency;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Data?'),
          content: const Text(
            'This will permanently delete all your transactions, budgets, and settings. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
