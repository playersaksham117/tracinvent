import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text(
            'Reports',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
          ],
        ),
        
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Summary Card
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'January 2026',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$5,400',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expenses',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$1,143',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$4,257',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Monthly Reports
              Text(
                'Monthly Reports',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _ReportItem(
                month: 'December 2025',
                income: 5400,
                expenses: 1302,
                saved: 4098,
                icon: Icons.description,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 12),
              
              _ReportItem(
                month: 'November 2025',
                income: 5400,
                expenses: 1456,
                saved: 3944,
                icon: Icons.description,
                color: Colors.green,
              ),
              
              const SizedBox(height: 12),
              
              _ReportItem(
                month: 'October 2025',
                income: 5400,
                expenses: 1678,
                saved: 3722,
                icon: Icons.description,
                color: Colors.orange,
              ),
              
              const SizedBox(height: 24),
              
              // Export Button
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export All Reports'),
              ),
              
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share),
                label: const Text('Share Current Report'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String month;
  final double income;
  final double expenses;
  final double saved;
  final IconData icon;
  final Color color;

  const _ReportItem({
    required this.month,
    required this.income,
    required this.expenses,
    required this.saved,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          month,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saved \$${saved.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${income.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${expenses.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saving Rate',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((saved / income) * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
