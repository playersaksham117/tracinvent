# SpendSight - Design System & UI/UX Documentation

## 🎨 Design Philosophy

**Modern Fintech Aesthetic**
- Clean, minimal interface prioritizing financial clarity
- Soft, comfortable color palette reducing eye strain
- Generous whitespace for breathing room
- Large, readable numbers for quick comprehension
- Subtle shadows creating depth without distraction

---

## 📐 Visual Design System

### Color Palette
```dart
// Primary - Soft Purple (Trust & Stability)
Primary: #7C5FE8
Primary Container: #E8E1FF
On Primary: #FFFFFF
On Primary Container: #2B1B5C

// Success - Soft Green (Income)
Success: #4CAF50
Success Light: #E8F5E9

// Error - Soft Red (Expense)
Error: #EF5350
Error Light: #FFEBEE

// Neutral - Clean Grays
Background: #F8F9FA
Surface: #FFFFFF
Surface Variant: #F3F4F6
On Surface: #1F2937
On Surface Variant: #6B7280

// Accent Colors
Orange: #FF9800 (Food)
Blue: #2196F3 (Transport)
Purple: #9C27B0 (Shopping)
Teal: #009688 (Bills)
```

### Typography Hierarchy
```dart
Display Large: 57px / Bold (Balance amounts)
Display Medium: 45px / Bold (Section headers)
Headline Large: 32px / Bold (Screen titles)
Title Large: 22px / SemiBold (Card titles)
Title Medium: 16px / SemiBold (List items)
Body Large: 16px / Regular (Body text)
Body Medium: 14px / Regular (Descriptions)
Label Small: 11px / Medium (Captions)

Font Family: Inter (Google Fonts)
```

### Spacing System
```dart
XXS: 4px   // Tight spacing
XS:  8px   // Compact spacing
SM:  12px  // Small spacing
MD:  16px  // Default spacing
LG:  24px  // Large spacing
XL:  32px  // Extra large spacing
XXL: 48px  // Section spacing
```

### Border Radius
```dart
Small: 12px    // Chips, buttons
Medium: 16px   // Cards, inputs
Large: 20px    // Feature cards
XLarge: 24px   // Hero cards
Full: 999px    // Pills, avatars
```

### Elevation & Shadows
```dart
Level 0: No shadow (Flat surface)
Level 1: Soft shadow for cards
  - offset: (0, 2)
  - blur: 8
  - color: rgba(0,0,0,0.04)

Level 2: Medium shadow for elevated cards
  - offset: (0, 4)
  - blur: 12
  - color: rgba(0,0,0,0.06)

Level 3: Strong shadow for FAB
  - offset: (0, 8)
  - blur: 16
  - color: rgba(0,0,0,0.08)
```

---

## 🏗️ Widget Hierarchy & Structure

### 1. DASHBOARD / HOME SCREEN

```
HomeScreen (StatefulWidget)
├── Scaffold
│   ├── Body: CustomScrollView
│   │   ├── SliverAppBar.large
│   │   │   ├── Title: Column
│   │   │   │   ├── MonthSelector (Subtitle)
│   │   │   │   └── "Overview" (Title)
│   │   │   └── Actions: [NotificationBell]
│   │   │
│   │   └── SliverPadding
│   │       └── SliverList
│   │           ├── BalanceCard (Hero Widget)
│   │           │   ├── "Available Balance" Label
│   │           │   ├── Amount Display (Display Large)
│   │           │   └── Row
│   │           │       ├── IncomeChip
│   │           │       └── ExpenseChip
│   │           │
│   │           ├── QuickActionsRow
│   │           │   ├── AddIncomeCard
│   │           │   ├── AddExpenseCard
│   │           │   └── SplitBillCard
│   │           │
│   │           ├── SpendingTrendSection
│   │           │   ├── SectionHeader
│   │           │   └── MiniBarChart
│   │           │
│   │           └── RecentTransactionsSection
│   │               ├── SectionHeader
│   │               └── TransactionList
│   │
│   ├── FloatingActionButton.extended
│   │   ├── Icon: Add
│   │   └── Label: "Expense"
│   │
│   └── BottomNavigationBar (NavigationBar)
│       ├── Home
│       ├── Budgets
│       ├── Analytics
│       ├── Reports
│       └── Settings
```

**UI Rationale:**
- **SliverAppBar**: Provides smooth scroll behavior with collapsing header
- **Large Balance Card**: Primary focus - users need to see balance immediately
- **Quick Actions**: 3-column grid for one-thumb reach
- **Recent Transactions**: Lazy-loaded list for performance
- **FAB Position**: Center-docked for dominant action (Add Expense)

---

### 2. ADD TRANSACTION SCREEN

```
AddTransactionScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── Leading: BackButton
│   │   └── Title: "Add Expense/Income"
│   │
│   └── Body: Form (SingleChildScrollView)
│       ├── TypeToggle (Expense/Income)
│       │   └── SegmentedButton
│       │
│       ├── AmountInputCard
│       │   ├── Currency Prefix ($)
│       │   ├── TextField (Display Large)
│       │   └── Hint: "0.00"
│       │
│       ├── CategorySelectorSection
│       │   ├── Label: "Category"
│       │   └── Wrap (FilterChips)
│       │       ├── FoodChip (Icon + Label)
│       │       ├── ShoppingChip
│       │       ├── TransportChip
│       │       └── ... (7 total)
│       │
│       ├── DatePickerCard
│       │   ├── Icon: Calendar
│       │   ├── SelectedDate
│       │   └── TrailingIcon: Chevron
│       │
│       ├── NotesField
│       │   ├── Label: "Note (Optional)"
│       │   └── TextField (Multiline)
│       │
│       └── SafeArea
│           └── SaveButton (Fixed Bottom)
│               └── FilledButton
```

**UI Rationale:**
- **Top Position Amount**: Most important field, large and obvious
- **Toggle Button**: Clear visual state for Expense vs Income
- **Category Chips**: Visual selection easier than dropdown
- **Fixed Save Button**: Always accessible, no scrolling needed
- **Keyboard Handling**: Number keyboard for amount, auto-focus

---

### 3. TRANSACTIONS LIST SCREEN

```
TransactionsScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── Title: "Transactions"
│   │   └── Actions: [FilterButton]
│   │
│   └── Body: Column
│       ├── FilterBar (Sticky)
│       │   ├── DateRangePicker
│       │   ├── CategoryFilter
│       │   └── TypeFilter (All/Income/Expense)
│       │
│       └── ListView.builder
│           └── TransactionCard (foreach transaction)
│               ├── Row
│               │   ├── CategoryIcon (Colored Circle)
│               │   ├── Column
│               │   │   ├── Title (Bold)
│               │   │   └── Subtitle (Category • Date)
│               │   └── Amount
│               │       ├── + or - prefix
│               │       └── Color (Green/Red)
│               │
│               └── Divider (Optional)
```

**UI Rationale:**
- **Sticky Filter**: Always visible for quick filtering
- **Color Coding**: Green (income) / Red (expense) for quick scanning
- **Date Grouping**: Transactions grouped by date for context
- **Swipe Actions**: Delete/Edit on swipe (optional enhancement)

---

### 4. BUDGETS SCREEN

```
BudgetsScreen (StatefulWidget)
├── CustomScrollView
│   ├── SliverAppBar
│   │   ├── Title: "Budgets"
│   │   └── Actions: [AddBudgetButton]
│   │
│   └── SliverList
│       ├── OverallBudgetCard
│       │   ├── CurrentMonth Label
│       │   ├── Row
│       │   │   ├── Column (Spent/Total)
│       │   │   └── CircularProgressIndicator
│       │   └── LinearProgressBar
│       │
│       ├── SectionHeader: "By Category"
│       │
│       └── CategoryBudgetList
│           └── BudgetCard (foreach category)
│               ├── CategoryIcon
│               ├── CategoryName
│               ├── ProgressBar
│               ├── Amount (Spent/Budget)
│               └── Percentage
```

**UI Rationale:**
- **Overall Progress First**: Big picture before details
- **Visual Progress Bars**: Instant understanding of budget status
- **Color Warnings**: Red when over budget, yellow near limit
- **Percentage Display**: Clear metric alongside amounts

---

### 5. ANALYTICS SCREEN

```
AnalyticsScreen (StatefulWidget)
├── CustomScrollView
│   ├── SliverAppBar
│   │   └── Title: "Analytics"
│   │
│   └── SliverList
│       ├── PeriodSelector (Week/Month/Year)
│       │   └── SegmentedButton
│       │
│       ├── TotalSpentCard
│       │   ├── Label
│       │   ├── Amount (Display Large)
│       │   └── TrendIndicator (↓ 12% from last month)
│       │
│       ├── SpendingByCategory
│       │   ├── SectionHeader
│       │   └── Card
│       │       ├── PieChart
│       │       └── Legend
│       │
│       └── SpendingTrends
│           ├── SectionHeader
│           └── LineChart
```

**UI Rationale:**
- **Numbers First**: Total amount more prominent than charts
- **Period Toggle**: Easy switching between time ranges
- **Simple Charts**: Pie chart for categories, line for trends
- **Color Consistency**: Same colors as category system

---

## 🎯 UX Design Principles

### 1. One-Thumb Friendly Design
- **Bottom Navigation**: All 5 tabs within thumb reach
- **FAB Position**: Center-docked, easily accessible
- **Touch Targets**: Minimum 48x48 dp
- **Modal Reach**: Critical actions in bottom 50% of screen

### 2. Minimal Steps to Action
- **Add Expense**: 2 taps (FAB → Amount → Save)
- **View Balance**: 0 taps (visible on launch)
- **Filter Transactions**: 1 tap (filter icon)

### 3. Visual Hierarchy
```
Priority 1: Balance & Amounts (Display fonts, bold)
Priority 2: Action Buttons (High contrast, colored)
Priority 3: Categories & Labels (Medium weight)
Priority 4: Descriptions & Notes (Regular weight, gray)
```

### 4. Error Prevention
- **Validation**: Real-time as user types
- **Defaults**: Smart defaults (today's date, last category)
- **Confirmations**: Only for destructive actions
- **Undo**: Toast with undo for deletions

### 5. Accessibility
- **Color Blindness**: Icons + text labels, not color alone
- **Screen Readers**: Semantic widgets, proper labels
- **Dynamic Type**: Scales with system font size
- **Contrast**: WCAG AA compliant (4.5:1 minimum)

---

## 🔧 Technical Implementation

### Material 3 Configuration
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF7C5FE8),
    brightness: Brightness.light,
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), // 20+ as specified
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  ),
)
```

### Responsive Breakpoints
```dart
// Mobile: < 600dp
// Tablet: 600-840dp
// Desktop: > 840dp

double getResponsivePadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return 16.0;  // Mobile
  if (width < 840) return 24.0;  // Tablet
  return 32.0;                   // Desktop
}
```

### Performance Optimizations
- **Lazy Loading**: ListView.builder for transactions
- **Image Caching**: CachedNetworkImage for profile
- **State Management**: Provider for global state
- **Debouncing**: Search filters debounced 300ms

---

## 📱 Example Flutter Widgets

### Balance Card (Hero Widget)
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        colorScheme.primaryContainer,
        colorScheme.primaryContainer.withOpacity(0.8),
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: colorScheme.primary.withOpacity(0.1),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Available Balance',
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      SizedBox(height: 8),
      Text(
        '\$4,256.80',
        style: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      SizedBox(height: 20),
      Row(
        children: [
          _IncomeExpenseChip(
            label: 'Income',
            amount: '\$5,400',
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
          SizedBox(width: 16),
          _IncomeExpenseChip(
            label: 'Expenses',
            amount: '\$1,143',
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
        ],
      ),
    ],
  ),
)
```

### Quick Action Card
```dart
Card(
  elevation: 0,
  color: colorScheme.surfaceVariant,
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ),
)
```

### Transaction List Item
```dart
Card(
  margin: EdgeInsets.only(bottom: 8),
  child: ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    leading: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(categoryIcon, color: categoryColor, size: 24),
    ),
    title: Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      '$category • $date',
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    trailing: Text(
      '${isExpense ? '-' : '+'}\$$amount',
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: isExpense ? Colors.red[700] : Colors.green[700],
      ),
    ),
  ),
)
```

---

## ✅ Checklist for Implementation

### Layout & Responsiveness
- [ ] SafeArea wrapper on all screens
- [ ] MediaQuery for responsive sizing
- [ ] ListView.builder for long lists
- [ ] SingleChildScrollView for forms
- [ ] Keyboard handling (padding/scroll)

### Visual Consistency
- [ ] 20+ border radius on all cards
- [ ] Consistent spacing (8, 16, 24, 32)
- [ ] Soft shadows (elevation 1-2)
- [ ] Color-coded amounts (green/red)
- [ ] Inter font family

### Accessibility
- [ ] Semantic widgets (Semantics wrapper)
- [ ] Proper contrast ratios
- [ ] Touch targets 48x48 minimum
- [ ] Screen reader labels
- [ ] Dynamic font sizing support

### Performance
- [ ] No expensive builds in main thread
- [ ] Images optimized and cached
- [ ] Debounced search/filters
- [ ] Pagination for transactions
- [ ] State management optimization

---

## 🎨 Design Tokens (Constants)

```dart
// colors.dart
class AppColors {
  static const primary = Color(0xFF7C5FE8);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFEF5350);
  static const warning = Color(0xFFFF9800);
  
  static const food = Color(0xFFFF9800);
  static const transport = Color(0xFF2196F3);
  static const shopping = Color(0xFF9C27B0);
  static const bills = Color(0xFF009688);
}

// spacing.dart
class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// radius.dart
class AppRadius {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 20.0;
  static const xlarge = 24.0;
  static BorderRadius circular(double radius) =>
      BorderRadius.circular(radius);
}
```

---

**Design Version**: 1.0  
**Last Updated**: January 19, 2026  
**Designer**: Senior Mobile UI/UX Team
