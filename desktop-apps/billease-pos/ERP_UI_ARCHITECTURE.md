# Try Sarthi Admin - ERP UI Architecture

A stable, modern, enterprise-grade Desktop ERP UI system inspired by Linear and Stripe dashboards.

## 📁 File Structure

```
lib/
├── theme/
│   └── app_theme.dart          # Complete design system
├── layouts/
│   └── main_layout.dart        # App shell with sidebar & topbar
├── widgets/
│   └── modern_components.dart  # Reusable UI components
└── screens/
    └── sample_screens.dart     # Example implementations
```

## 🎨 Design System (`app_theme.dart`)

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `AppColors.primary` | `#2563EB` | Primary buttons, links, active states |
| `AppColors.navyDark` | `#0F172A` | Sidebar background |
| `AppColors.slate900` | `#0F172A` | Headings, primary text |
| `AppColors.slate500` | `#64748B` | Body text, descriptions |
| `AppColors.background` | `#F3F4F6` | Page background |
| `AppColors.surface` | `#FFFFFF` | Cards, inputs |
| `AppColors.border` | `#E5E7EB` | Borders, dividers |
| `AppColors.success` | `#10B981` | Success states |
| `AppColors.warning` | `#F59E0B` | Warning states |
| `AppColors.error` | `#EF4444` | Error states |

### Spacing

```dart
AppSpacing.xs   = 4px
AppSpacing.sm   = 8px
AppSpacing.md   = 12px
AppSpacing.lg   = 16px
AppSpacing.xl   = 20px
AppSpacing.xxl  = 24px
AppSpacing.xxxl = 32px
```

### Border Radius

```dart
AppRadius.sm   = 6px
AppRadius.md   = 8px
AppRadius.lg   = 12px
AppRadius.xl   = 16px
AppRadius.full = 9999px  // Pill shape
```

### Typography

All text uses **Inter** font family via `google_fonts`.

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayLarge` | 32px | w700 | Page titles |
| `headlineMedium` | 18px | w600 | Section headers |
| `titleMedium` | 14px | w600 | Card titles |
| `bodyMedium` | 14px | w400 | Body text |
| `labelSmall` | 11px | w500 | Uppercase labels |

---

## 🏠 App Shell (`main_layout.dart`)

### Structure

```
┌─────────────────────────────────────────────────────────┐
│                    TOP BAR (60px)                        │
│  [Logo] [Search ⌘K]                    [🔔] [Profile ▼]  │
├───────────┬─────────────────────────────────────────────┤
│           │                                             │
│  SIDEBAR  │              CONTENT AREA                   │
│  (250px)  │                                             │
│           │          (Scrollable Page)                  │
│  [Home]   │                                             │
│  [Sales]  │                                             │
│  [Items]  │                                             │
│           │                                             │
│  ─────    │                                             │
│  REPORTS  │                                             │
│  [Dash]   │                                             │
│           │                                             │
│  ─────    │                                             │
│  [⚙️]     │                                             │
│           │                                             │
└───────────┴─────────────────────────────────────────────┘
```

### Sidebar Features

- **Expanded Width**: 250px
- **Collapsed Width**: 70px (icons only)
- **Auto-collapse**: Below 1100px screen width
- **Navigation sections**: Main, Reports, Settings
- **Active state**: Primary color background with pill shape

### Topbar Features

- **Height**: 60px
- **Global search**: Command+K shortcut hint
- **Notifications**: Badge with unread count
- **User profile**: Avatar with dropdown menu

---

## 📦 Modern Components (`modern_components.dart`)

### ModernTable

A clean data table with hover effects, sorting, and row actions.

```dart
ModernTable<Order>(
  columns: [
    ModernTableColumn(id: 'id', label: 'Order ID', sortable: true),
    ModernTableColumn(id: 'customer', label: 'Customer'),
    ModernTableColumn(id: 'amount', label: 'Amount', textAlign: TextAlign.right),
    ModernTableColumn(id: 'status', label: 'Status'),
  ],
  data: orders,
  showCheckboxes: true,
  sortColumn: 'date',
  sortAscending: false,
  cellBuilder: (item, column) {
    switch (column.id) {
      case 'id': return Text(item.id);
      case 'customer': return Text(item.customer);
      case 'amount': return Text('₹${item.amount}');
      case 'status': return StatusChip(label: item.status, type: StatusType.success);
      default: return SizedBox();
    }
  },
  actionsBuilder: (item) => [
    PopupMenuItem(value: 'view', child: Text('View')),
    PopupMenuItem(value: 'edit', child: Text('Edit')),
    PopupMenuItem(value: 'delete', child: Text('Delete')),
  ],
  onAction: (item, action) => handleAction(item, action),
)
```

### StatusChip

Pill-style status indicator.

```dart
// Types: success, warning, error, info, neutral
StatusChip(
  label: 'Completed',
  type: StatusType.success,
  icon: Icons.check_circle,
)
```

### QuantityInput

Modern +/- stepper input.

```dart
QuantityInput(
  value: quantity,
  min: 0,
  max: 100,
  onChanged: (value) => setState(() => quantity = value),
  compact: false,
)
```

### ResponsiveFormGrid

Auto-adjusts columns based on screen width.

```dart
// 1 column (<800px) | 2 columns (800-1200px) | 3 columns (>1200px)
ResponsiveFormGrid(
  spacing: 16,
  children: [
    TextField(decoration: InputDecoration(labelText: 'Name')),
    TextField(decoration: InputDecoration(labelText: 'SKU')),
    TextField(decoration: InputDecoration(labelText: 'Price')),
  ],
)
```

### SectionHeader

Consistent section headers with optional action.

```dart
SectionHeader(
  title: 'Recent Orders',
  subtitle: 'Last 30 days',
  action: TextButton(onPressed: () {}, child: Text('View All')),
)
```

### ModernCard

Consistent card styling.

```dart
ModernCard(
  padding: EdgeInsets.all(20),
  onTap: () => navigateToDetail(),
  child: Column(
    children: [
      Text('Card Title'),
      Text('Card content goes here'),
    ],
  ),
)
```

---

## 🚀 Usage

### 1. Apply Theme

```dart
// main.dart
import 'theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.lightTheme,
  // ...
)
```

### 2. Use Main Layout

```dart
import 'layouts/main_layout.dart';

MaterialPageRoute(
  builder: (context) => MainLayout(
    currentRoute: '/products',
    onNavigate: (route) => Navigator.pushReplacementNamed(context, route),
    child: ProductsScreen(),
  ),
)
```

### 3. Use Colors in Widgets

```dart
import 'theme/app_theme.dart';

Container(
  color: AppColors.background,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.slate900),
  ),
)
```

---

## 🎯 Design Principles

1. **No heavy shadows** - Use subtle 1px borders instead
2. **Generous whitespace** - 24px+ padding in cards
3. **Consistent typography** - Inter font, limited size scale
4. **Clear visual hierarchy** - Slate900 for headings, slate500 for body
5. **Subtle interactions** - Hover states with 5% opacity tint
6. **Accessible** - 4.5:1+ contrast ratios

---

## 📱 Responsive Breakpoints

| Breakpoint | Behavior |
|------------|----------|
| < 800px | Single column forms, hidden sidebar |
| 800-1100px | 2-column forms, auto-collapsed sidebar |
| > 1100px | 3-column forms, expanded sidebar |

---

## 🔧 Extending the System

### Adding New Colors

```dart
// In AppColors class
static const Color myNewColor = Color(0xFF...);
```

### Adding New Components

```dart
// Create in lib/widgets/modern_components.dart
class MyNewWidget extends StatelessWidget {
  // Use AppColors, AppSpacing, AppRadius
}
```

### Creating New Screen

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';

class MyNewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            SectionHeader(title: 'My Screen'),
            // Content...
          ],
        ),
      ),
    );
  }
}
```
