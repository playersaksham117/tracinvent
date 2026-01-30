# TracInvent Dashboard Design Documentation

## Overview
Professional ERP-grade dashboard design for desktop inventory management, featuring modern charts and intuitive stock adjustment workflows.

---

## 📊 CHART COMPONENTS

### 1. Inventory Movement Line Chart
**File:** `lib/widgets/dashboard_charts.dart` → `InventoryMovementLineChart`

#### Purpose
Visualize temporal trends of inventory flow (incoming vs outgoing) over time.

#### Data Model
```dart
Map<DateTime, double> incomingData;  // Date → Quantity received
Map<DateTime, double> outgoingData;  // Date → Quantity dispatched
```

#### UI Structure
```
┌─────────────────────────────────────────┐
│  Chart Container                        │
│  ┌───────────────────────────────────┐  │
│  │     ↗ Incoming (Green Line)       │  │
│  │    ↗                               │  │
│  │   ↗    ↘ Outgoing (Red Line)     │  │
│  │  ↗      ↘                         │  │
│  │ ↗        ↘                        │  │
│  └───────────────────────────────────┘  │
│    Mon  Tue  Wed  Thu  Fri  Sat  Sun    │
└─────────────────────────────────────────┘
```

#### Design Rationale
- **Line chart over bar**: Better for continuous time-series data, shows trends clearly
- **Dual gradient fills**: Visual distinction between incoming (green) and outgoing (red)
- **Curved lines**: Softer, more professional look than angular lines
- **Interactive tooltips**: Shows exact values on hover with date + quantity
- **Dot markers**: Emphasizes actual data points, improves readability

#### Key Features
- Auto-scales Y-axis (max value × 1.2 for padding)
- Date formatting: "MMM dd" (e.g., "Jan 15")
- Color convention: Green (#10B981) = incoming, Red (#EF4444) = outgoing
- Empty state handling with icon + message

#### Code Example
```dart
InventoryMovementLineChart(
  incomingData: {
    DateTime(2026, 1, 15): 120,
    DateTime(2026, 1, 16): 85,
    DateTime(2026, 1, 17): 200,
  },
  outgoingData: {
    DateTime(2026, 1, 15): 95,
    DateTime(2026, 1, 16): 140,
    DateTime(2026, 1, 17): 110,
  },
)
```

---

### 2. Category Distribution Donut Chart
**File:** `lib/widgets/dashboard_charts.dart` → `CategoryDistributionDonutChart`

#### Purpose
Show proportional stock distribution across product categories.

#### Data Model
```dart
Map<String, double> categoryData;   // Category name → Total stock
Map<String, Color> categoryColors;  // Category name → Display color
```

#### UI Structure
```
┌──────────────────────────────────────────┐
│  ┌─────────┐      LEGEND                 │
│  │   ○○○   │      ■ Electronics  45%     │
│  │  ○   ○  │      ■ Furniture    30%     │
│  │  ○   ○  │      ■ Accessories  15%     │
│  │   ○○○   │      ■ Consumables  10%     │
│  └─────────┘                              │
│   Donut Chart    Category breakdown       │
└──────────────────────────────────────────┘
```

#### Design Rationale
- **Donut over pie**: Center space used for total/branding, cleaner aesthetic
- **Percentage labels**: Immediate understanding of proportions
- **Side legend**: Lists categories with counts and percentages
- **Color coding**: Distinct colors for each category (6-color palette)
- **Center radius 60px**: Optimal donut thickness for desktop viewing

#### Key Features
- Sector spacing: 3px for visual separation
- Percentage calculation: Auto-computes from values
- Legend format: "Category • X% • Y items"
- Responsive text ellipsis for long category names
- Touch/hover interactions built-in

#### Color Palette
```dart
[
  Color(0xFF3B82F6),  // Blue
  Color(0xFF8B5CF6),  // Purple
  Color(0xFF10B981),  // Green
  Color(0xFFF59E0B),  // Amber
  Color(0xFFEF4444),  // Red
  Color(0xFF06B6D4),  // Cyan
]
```

---

### 3. Warehouse Comparison Bar Chart
**File:** `lib/widgets/dashboard_charts.dart` → `WarehouseComparisonBarChart`

#### Purpose
Compare stock levels across multiple warehouse locations.

#### Data Model
```dart
Map<String, double> warehouseData;   // Warehouse ID → Total stock
Map<String, String> warehouseNames;  // Warehouse ID → Display name
```

#### UI Structure
```
┌──────────────────────────────────────┐
│  Warehouse A  ████████████  1,250    │
│  Warehouse B  ██████        850      │
│  Warehouse C  █████████     1,100    │
│  Warehouse D  ███           400      │
└──────────────────────────────────────┘
```

#### Design Rationale
- **Horizontal bars**: Better label readability than vertical bars
- **Auto-sorted**: Descending order (highest stock first)
- **Gradient fill**: Subtle depth effect on bars
- **Width 32px**: Optimal thickness for desktop
- **Rounded tops**: Modern, polished look

#### Key Features
- Truncates long warehouse names (max 10 chars + "...")
- Interactive tooltips with full name + exact stock count
- Dynamic color assignment (rotates through 6-color palette)
- Y-axis padding: max value × 1.2
- Grid lines: Horizontal only (vertical distracts from bars)

---

### 4. Stock Health Indicator
**File:** `lib/widgets/dashboard_charts.dart` → `StockHealthIndicator`

#### Purpose
Segmented progress bar showing healthy/low/critical stock distribution.

#### Data Model
```dart
int totalItems;
int lowStockItems;       // Below reorder level
int criticalStockItems;  // Below minimum level
```

#### UI Structure
```
┌─────────────────────────────────────────┐
│  [████████████▓▓▓▓▓▓░░░░]              │
│   Green     Amber   Red                 │
│                                         │
│   Healthy    Low Stock    Critical     │
│     145         28          7          │
└─────────────────────────────────────────┘
```

#### Design Rationale
- **Segmented bar**: Immediate visual health status
- **Traffic light colors**: Universal red/amber/green convention
- **Proportional widths**: Flexbox-based percentage allocation
- **Legend below**: Shows labels + counts for each segment
- **32px height**: Prominent but not overwhelming

#### Color Meanings
- **Green (#10B981)**: Healthy stock (above reorder level)
- **Amber (#F59E0B)**: Low stock (below reorder, above minimum)
- **Red (#EF4444)**: Critical stock (below minimum level)

---

## 🔧 STOCK ADJUSTMENT UX

### Component
**File:** `lib/widgets/stock_adjustment_modal.dart` → `StockAdjustmentModal`

### UX Philosophy
Single-modal approach reduces cognitive load. Users perform both add/reduce operations in one familiar interface without navigation overhead.

---

### Widget Hierarchy
```
Dialog (560px width, max 720px height)
├── Header (Fixed)
│   ├── Icon + Title
│   └── Close Button
├── Content (Scrollable)
│   ├── Item Info Card
│   │   ├── Item Name
│   │   └── SKU + Category Chips
│   ├── Current Stock Display (Large)
│   ├── Action Toggle (Add/Reduce)
│   ├── Quantity Input (36px font)
│   ├── Reason Dropdown (Required)
│   └── Stock Preview Card (Before → After)
└── Footer (Fixed)
    ├── Cancel Button
    └── Confirm Button (Color-coded)
```

---

### Layout Specifications

#### 1. Header Section
```
┌──────────────────────────────────────────┐
│  [📦] Stock Adjustment              [✕]  │
└──────────────────────────────────────────┘
```
- **Height**: Auto
- **Background**: White
- **Border bottom**: 1px #E2E8F0
- **Icon**: Blue circle background (#3B82F6 10% opacity)
- **Title**: 20px, font-weight 600

---

#### 2. Item Info Card
```
┌──────────────────────────────────────────┐
│  Wireless Mouse Pro                      │
│  [SKU: WM-001] [Category: Electronics]   │
└──────────────────────────────────────────┘
```
- **Background**: #F8FAFC (slate gray)
- **Border**: 1px #E2E8F0
- **Padding**: 20px
- **Chips**: White background with border

---

#### 3. Current Stock Display
```
Current Stock:  1,250 units
    ↑14px          ↑28px bold
```
- **Center-aligned**
- **Label**: 16px, gray-600
- **Value**: 28px, font-weight 700, slate-900

---

#### 4. Action Toggle (Critical Component)
```
┌────────────────────────────────────────┐
│ [  Add Stock  ] [ Reduce Stock ]       │
│    ↑ Active       ↑ Inactive           │
└────────────────────────────────────────┘
```

**Design Rationale:**
- **Toggle vs Separate Forms**: Single interface reduces training time
- **Color Coding**: 
  - Add mode: Green (#10B981) - positive action
  - Reduce mode: Red (#EF4444) - destructive action
- **Visual State**: Active button has white background + shadow
- **Smooth Transition**: 200ms animation on toggle
- **Icon + Text**: Improves scannability

**State Management:**
```dart
bool _isAddMode = true;  // Default to safer "Add" mode
```

---

#### 5. Quantity Input (Desktop-First Design)
```
┌────────────────────────────────────────┐
│                                        │
│              250                       │
│                    units               │
│                                        │
└────────────────────────────────────────┘
```

**Specifications:**
- **Font Size**: 36px (large, numpad-friendly)
- **Center-aligned**: Easy focus for data entry
- **Number-only**: `FilteringTextInputFormatter.digitsOnly`
- **Unit suffix**: 18px, right-aligned, gray
- **Background**: #F8FAFC
- **Border**: 2px
  - Default: #E2E8F0 (slate)
  - Focus: #3B82F6 (blue)
  - Error: #EF4444 (red)

**Validation:**
- Must be > 0
- Reduce mode: Cannot exceed current stock
- Real-time error display below input

**UX Rationale:**
- **Large font**: Reduces input errors, improves desktop readability
- **Centered text**: Natural focus point
- **Inline unit**: Context always visible
- **Immediate validation**: Prevents invalid submissions

---

#### 6. Reason Dropdown (Mandatory)
```
┌────────────────────────────────────────┐
│  Reason *                              │
│  [Select a reason ▼]                   │
└────────────────────────────────────────┘
```

**Add Mode Reasons:**
- Purchase Order
- Stock Return
- Production Complete
- Inventory Correction
- Opening Balance

**Reduce Mode Reasons:**
- Sales Order
- Damaged Goods
- Expired Items
- Sample Distribution
- Inventory Correction
- Theft/Loss

**UX Rationale:**
- **Mandatory field**: Prevents accidental adjustments
- **Context-aware**: Different reasons per mode
- **Audit trail**: Every adjustment is documented
- **Red asterisk**: Visual required indicator

---

#### 7. Stock Preview Card (Smart Component)
```
┌────────────────────────────────────────┐
│  [👁] Stock Preview                     │
│                                        │
│   Current       →      After           │
│    1,250               1,500           │
│    units               units           │
│                                        │
│  ⚠️ Warning: Stock below minimum (100) │
└────────────────────────────────────────┘
```

**Features:**
- **Gradient Background**: Color-coded (green/red based on mode)
- **Before → After**: Clear visual transition
- **Large "After" Value**: 32px font, colored
- **Smart Warning**: Shows if result falls below minimum level
- **Only visible when**: Quantity > 0

**UX Rationale:**
- **Prevents errors**: User sees result before committing
- **Confidence builder**: Clear consequences of action
- **Warning system**: Proactive low-stock alerts

---

#### 8. Fixed Footer Buttons
```
┌────────────────────────────────────────┐
│  [    Cancel    ] [ ✓ Confirm Add ]    │
└────────────────────────────────────────┘
```

**Cancel Button:**
- **Style**: Outlined, gray
- **Behavior**: Closes modal without action

**Confirm Button:**
- **Width**: 2× cancel button (more prominent)
- **Color**: 
  - Add mode: Green (#10B981)
  - Reduce mode: Red (#EF4444)
- **Icon + Label**: Reinforces action type
- **Disabled State**: Gray when validation fails
- **Elevation**: 0 (flat design)

**UX Rationale:**
- **Fixed Position**: Always visible, no scrolling needed
- **Asymmetric Width**: Primary action more prominent
- **Color Psychology**: Green = safe, Red = caution
- **Disabled Until Valid**: Prevents errors

---

### Validation Rules

```dart
bool _isValid =>
  _quantity > 0 &&                          // Must enter quantity
  _selectedReason != null &&                // Must select reason
  (_isAddMode || _quantity <= currentStock); // Reduce: can't exceed stock
```

**Real-time Validation:**
- ✅ Quantity input: Live error display
- ✅ Confirm button: Disabled until valid
- ✅ Visual feedback: Red border on error fields

---

### Interaction Flow

```
1. User opens modal
   ↓
2. Reviews item info + current stock
   ↓
3. Selects Add or Reduce mode
   ↓
4. Enters quantity (sees live validation)
   ↓
5. Selects reason from dropdown
   ↓
6. Reviews stock preview (before → after)
   ↓
7. Confirms (if valid) or cancels
   ↓
8. Modal returns result object:
   {
     'success': true,
     'type': 'purchase', // or 'sale'
     'quantity': 250,
     'reason': 'Purchase Order',
   }
```

---

### Accessibility Features

- **Keyboard Navigation**: Tab order follows logical flow
- **Focus Indicators**: Clear blue borders on focus
- **Label Association**: All inputs have descriptive labels
- **Error Messages**: Inline, specific, actionable
- **Button States**: Disabled state visually distinct
- **Icon + Text**: Multiple information channels

---

## 📐 DESKTOP-FIRST DESIGN PRINCIPLES

### 1. **No Horizontal Overflow**
- All components use responsive widths
- Tables/charts have proper min-width constraints
- Scrolling only vertical (natural desktop pattern)

### 2. **Optimal Spacing**
- Modal width: 560px (Goldilocks zone for forms)
- Chart padding: 16-32px (breathing room)
- Card gaps: 20-24px (clear separation)
- Button padding: 16px vertical (easy click targets)

### 3. **Typography Scale**
```
H1 (Page Title):     24px, font-weight 600
H2 (Section):        20px, font-weight 600
H3 (Card Header):    16px, font-weight 600
Body:                14px, font-weight 400
Large Input:         36px, font-weight 700
Small Labels:        12px, font-weight 500
Tiny Meta:           11px, font-weight 400
```

### 4. **Color System**
```dart
// Backgrounds
Slate-50:  #F8FAFC  (Page background)
White:     #FFFFFF  (Card backgrounds)
Slate-100: #F1F5F9  (Subtle fills)

// Borders
Slate-200: #E2E8F0  (Default borders)
Slate-300: #CBD5E1  (Hover states)

// Text
Slate-900: #0F172A  (Primary text)
Slate-700: #334155  (Secondary text)
Slate-600: #475569  (Tertiary text)
Slate-500: #64748B  (Disabled text)

// Status Colors
Success:   #10B981  (Green)
Warning:   #F59E0B  (Amber)
Danger:    #EF4444  (Red)
Primary:   #3B82F6  (Blue)
Secondary: #8B5CF6  (Purple)
Info:      #06B6D4  (Cyan)
```

### 5. **Elevation System**
```
Level 0: No shadow (flat)
Level 1: 0px 1px 3px rgba(0,0,0,0.1)   (Subtle lift)
Level 2: 0px 2px 8px rgba(0,0,0,0.05)  (Cards)
Level 3: 0px 4px 16px rgba(0,0,0,0.1)  (Modals)
```

### 6. **Border Radius**
```
Small:  6px   (Chips, badges)
Medium: 10px  (Buttons)
Large:  12px  (Cards, inputs)
XLarge: 16px  (Modals)
Round:  9999px (Pills, avatars)
```

---

## 🎨 CHART INTEGRATION GUIDE

### Dashboard Screen Integration

```dart
// In dashboard_screen.dart

import '../widgets/dashboard_charts.dart';

// 1. Prepare data from providers
final incomingData = _aggregateIncoming(inventoryProvider.transactions);
final outgoingData = _aggregateOutgoing(inventoryProvider.transactions);

// 2. Use chart widgets
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: Column(
    children: [
      // Chart header
      Row(
        children: [
          Icon(Icons.show_chart, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Text('Inventory Movement', style: ...),
        ],
      ),
      SizedBox(height: 24),
      
      // Chart
      SizedBox(
        height: 280,
        child: InventoryMovementLineChart(
          incomingData: incomingData,
          outgoingData: outgoingData,
        ),
      ),
    ],
  ),
)
```

### Stock Adjustment Integration

```dart
// From inventory screen or dashboard

await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (context) => StockAdjustmentModal(
    item: selectedItem,
    currentStock: inventoryProvider.getTotalStock(selectedItem.id),
  ),
).then((result) {
  if (result != null && result['success'] == true) {
    // Update inventory
    inventoryProvider.recordTransaction(
      itemId: selectedItem.id,
      type: result['type'],
      quantity: result['quantity'],
      reason: result['reason'],
    );
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stock updated successfully')),
    );
  }
});
```

---

## 📊 DATA PREPARATION EXAMPLES

### Line Chart Data Aggregation
```dart
Map<DateTime, double> _aggregateLast7Days(
  List<Transaction> transactions,
  String type,
) {
  final now = DateTime.now();
  final data = <DateTime, double>{};
  
  for (int i = 0; i < 7; i++) {
    final date = DateTime(now.year, now.month, now.day - i);
    data[date] = 0;
  }
  
  for (var txn in transactions) {
    final txnDate = DateTime(
      txn.date.year,
      txn.date.month,
      txn.date.day,
    );
    
    if (txn.type == type && data.containsKey(txnDate)) {
      data[txnDate] = data[txnDate]! + txn.quantity;
    }
  }
  
  return data;
}
```

### Category Distribution Data
```dart
Map<String, double> _aggregateByCategory(
  List<InventoryItem> items,
  List<Stock> stocks,
) {
  final categoryData = <String, double>{};
  
  for (var item in items) {
    final totalStock = stocks
        .where((s) => s.itemId == item.id)
        .fold(0.0, (sum, s) => sum + s.quantity);
    
    categoryData[item.category] = 
        (categoryData[item.category] ?? 0) + totalStock;
  }
  
  return categoryData;
}
```

### Warehouse Comparison Data
```dart
Map<String, double> _aggregateByWarehouse(List<Stock> stocks) {
  final warehouseData = <String, double>{};
  
  for (var stock in stocks) {
    warehouseData[stock.warehouseId] = 
        (warehouseData[stock.warehouseId] ?? 0) + stock.quantity;
  }
  
  return warehouseData;
}
```

---

## 🔍 UX RESEARCH INSIGHTS

### Why Line Charts for Inventory Movement?
- **Trend visibility**: Shows patterns over time (seasonality, growth)
- **Comparison**: Dual lines make incoming/outgoing relationship clear
- **Prediction**: Users can extrapolate future trends
- **Industry standard**: ERP systems universally use line charts for movement

### Why Donut over Pie Charts?
- **Modern aesthetic**: Cleaner, more professional look
- **Center space utilization**: Can add total count or branding
- **Better proportions**: Easier to compare similar-sized slices
- **Less cluttered**: Percentages inside, labels outside

### Why Horizontal Bars for Warehouses?
- **Label readability**: Long warehouse names don't rotate/truncate
- **Natural reading**: Left-to-right matches text scanning
- **Easier comparison**: Eye moves horizontally to compare lengths
- **Desktop optimization**: Utilizes screen width efficiently

### Why Single Modal for Stock Adjustment?
- **Cognitive load**: One mental model vs two separate screens
- **Context retention**: Same form, different mode = less confusion
- **Fewer clicks**: No navigation between add/reduce
- **Visual safety**: Color coding prevents wrong-mode errors

---

## ✅ FLUTTER-FRIENDLY PATTERNS

### 1. **Stateless Where Possible**
Charts are stateless widgets - data flows down from providers.

### 2. **Composition Over Inheritance**
Small, reusable widgets (`_buildLegendItem`, `_buildPreviewValue`).

### 3. **Provider Pattern**
All data fetched from providers, no direct database calls.

### 4. **Null Safety**
All nullable fields handled with `??` operator and empty states.

### 5. **Responsive Layouts**
LayoutBuilder + MediaQuery for adaptive sizing.

### 6. **Performance**
- Charts only rebuild when data changes
- Heavy computations cached
- `const` constructors where possible

---

## 🚀 NEXT STEPS

### Integration Checklist
- [ ] Import chart widgets in dashboard_screen.dart
- [ ] Implement data aggregation methods
- [ ] Add loading states for async data
- [ ] Test empty states (no data scenarios)
- [ ] Add "Export Chart" functionality
- [ ] Implement chart drill-down (click to details)
- [ ] Add date range selector for line chart
- [ ] Test with real transaction data
- [ ] Optimize chart performance (large datasets)
- [ ] Add animation on chart load

### Enhancement Ideas
1. **Chart Customization**: User-selectable date ranges
2. **Export Functionality**: PNG/PDF chart export
3. **Drill-Down**: Click chart segments to see details
4. **Comparison Mode**: Compare time periods side-by-side
5. **Alerts**: Automated alerts when critical thresholds met
6. **Forecasting**: ML-based stock prediction overlay

---

## 📚 REFERENCES

### Dependencies
```yaml
dependencies:
  fl_chart: ^0.66.0      # Chart library
  intl: ^0.18.0          # Date formatting
  provider: ^6.1.1       # State management
```

### External Resources
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)
- [Material Design 3](https://m3.material.io/)
- [Flutter Desktop Best Practices](https://docs.flutter.dev/desktop)

---

*This design document reflects the implemented state as of January 21, 2026.*
*All measurements are in logical pixels (dp) unless otherwise specified.*
