import 'package:flutter/material.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text(
            'Budgets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ],
        ),
        
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Overall Budget Card
              Card(
                color: colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$1,143',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                                Text(
                                  'of \$3,000 spent',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onTertiaryContainer.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircularProgressIndicator(
                            value: 0.38,
                            strokeWidth: 8,
                            backgroundColor: colorScheme.onTertiaryContainer.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.38,
                          minHeight: 8,
                          backgroundColor: colorScheme.onTertiaryContainer.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Category Budgets
              Text(
                'By Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _BudgetItem(
                title: 'Food',
                icon: Icons.restaurant,
                spent: 385,
                budget: 800,
                color: Colors.orange,
              ),
              
              const SizedBox(height: 12),
              
              _BudgetItem(
                title: 'Shopping',
                icon: Icons.shopping_bag,
                spent: 250,
                budget: 500,
                color: Colors.purple,
              ),
              
              const SizedBox(height: 12),
              
              _BudgetItem(
                title: 'Transport',
                icon: Icons.directions_car,
                spent: 180,
                budget: 400,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 12),
              
              _BudgetItem(
                title: 'Bills',
                icon: Icons.receipt_long,
                spent: 328,
                budget: 600,
                color: Colors.red,
              ),
              
              const SizedBox(height: 12),
              
              _BudgetItem(
                title: 'Entertainment',
                icon: Icons.movie,
                spent: 0,
                budget: 300,
                color: Colors.teal,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _BudgetItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final double spent;
  final double budget;
  final Color color;

  const _BudgetItem({
    required this.title,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = spent / budget;
    final isOverBudget = percentage > 1.0;
    
    return Card(
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
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${spent.toStringAsFixed(0)} of \$${budget.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red[700] : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
