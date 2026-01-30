# Billing Screen - Quick Developer Guide

## 🎯 Overview
Modern, 3-panel desktop POS billing interface with keyboard-first design.

## 📐 Layout Structure

```
[25% Search Panel] [45% Product Grid] [30% Billing Panel]
```

## 🎨 Color Palette (Quick Reference)

```dart
// Backgrounds
0xFFF8F9FA  // Page
0xFFFFFFFF  // Cards
0xFFF8FAFC  // Inputs

// Primary
0xFF3B82F6  // Blue (buttons, active)
0xFF1E293B  // Dark slate (header)

// Status
0xFF16A34A  // Green (success)
0xFFF59E0B  // Amber (warning)
0xFFDC2626  // Red (error)

// Text
0xFF1E293B  // Primary
0xFF64748B  // Secondary
0xFF94A3B8  // Muted
```

## 🔑 Key Features

### 1. Search (Left Panel)
- **Auto-focus** on page load
- **Debounced** (300ms delay)
- Searches: SKU, Name, Barcode
- Product list with stock badges

### 2. Products (Center)
- Responsive grid (2-3 columns)
- One-click add to cart
- Stock indicators
- Empty state messaging

### 3. Billing (Right)
- Sticky panel (always visible)
- Collapsible customer details
- Inline cart item controls
- Prominent grand total
- Segmented payment selectors

## 📝 Important Components

### Search Debounce
```dart
Timer? _debounce;
_debounce = Timer(const Duration(milliseconds: 300), () {
  // Filter logic
});
```

### Responsive Grid
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final crossAxisCount = constraints.maxWidth < 1200 ? 2 : 3;
    // Grid view
  }
)
```

### Auto-focus
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _searchFocusNode.requestFocus();
});
```

## 🎛️ State Variables

```dart
// Controllers
_searchController
_customerNameController
_paidAmountController

// Focus Nodes
_searchFocusNode (auto-focus)
_paidAmountFocusNode

// Cart & Products
_allProducts
_filteredProducts
_cartItems

// Billing
_subtotal
_totalTax
_discount
_grandTotal
_paidAmount
_dueAmount
_changeAmount
_paymentMethod ('Cash', 'Card', 'UPI', 'Wallet')
_paymentStatus ('paid', 'partial', 'credit')
```

## 🔧 Key Methods

| Method | Purpose |
|--------|---------|
| `_loadData()` | Load products, customers, generate invoice # |
| `_filterProducts(query)` | Debounced product search |
| `_addToCart(product)` | Add/increment product in cart |
| `_updateCartItemQuantity()` | Modify cart item quantity |
| `_removeFromCart(index)` | Delete cart item |
| `_calculateTotals()` | Recalculate all billing amounts |
| `_completeSale()` | Process transaction & save |
| `_printReceipt(saleId)` | Generate text receipt file |
| `_resetBilling()` | Clear cart, reset form |

## 🎨 Widget Structure

```dart
BillingScreen
├── AppBar (_buildAppBar)
└── Body (LayoutBuilder)
    ├── _buildSearchPanel()      // 25%
    │   ├── Search TextField
    │   └── _buildProductList()
    ├── _buildProductsPanel()    // 45% (Expanded)
    │   └── GridView (_buildProductCard)
    └── _buildBillingPanel()     // 30%
        ├── Invoice Header
        ├── _buildCustomerSection()
        ├── Cart Items (_buildCartItem)
        ├── Totals (_buildTotalRow)
        └── Payment Panel
            ├── _buildPaymentMethodSelector()
            └── _buildPaymentStatusSelector()
```

## 🚀 Performance Tips

1. **Use debounce** for search (prevents excessive rebuilds)
2. **ListView/GridView.builder** (only visible items rendered)
3. **LayoutBuilder** for responsive sizing
4. **Minimal setState** (only update when needed)

## ⌨️ UX Best Practices

- ✅ Auto-focus search on load
- ✅ Clear empty states with hints
- ✅ Inline validation (amount fields)
- ✅ Instant feedback on actions
- ✅ High contrast text (readability)
- ✅ Large clickable areas (desktop)

## 🐛 Common Issues & Solutions

### Issue: Overflow errors
**Solution**: Use `LayoutBuilder` + percentage widths

### Issue: Search too slow
**Solution**: Debounce implemented (300ms)

### Issue: Cart not updating
**Solution**: Call `_calculateTotals()` after cart changes

### Issue: Customer dropdown not closing
**Solution**: Set `_showCustomerDropdown = false` in setState

## 📦 Dependencies Used

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // For keyboard handling
import 'package:intl/intl.dart';         // Date formatting
import 'dart:async';                     // Timer for debounce
```

## 🎯 Testing Checklist

- [ ] Search functionality (SKU, name, barcode)
- [ ] Add/remove/update cart items
- [ ] Payment method selection
- [ ] Payment status changes (paid/partial/credit)
- [ ] Amount calculations (change/due)
- [ ] Customer autocomplete
- [ ] Empty states (products, cart)
- [ ] Responsive grid (resize window)
- [ ] Complete sale flow
- [ ] Receipt generation

## 📱 Responsive Breakpoints

- `< 1200px` → 2-column product grid
- `≥ 1200px` → 3-column product grid

## 🎨 Design Tokens

```dart
// Spacing
8, 10, 12, 14, 16, 20, 24, 32 (multiples of 4)

// Border Radius
6, 8, 10, 12 (rounded corners)

// Font Sizes
11, 12, 13, 14, 15, 16, 18, 20, 24

// Font Weights
w400, w500, w600, w700, w800
```

## 🔐 Validation Rules

- Cart must have items to complete sale
- Paid amount ≥ total (when status = 'paid')
- Amounts must be valid numbers
- Customer fields optional

## 📄 Related Files

```
lib/
├── screens/
│   └── billing_screen.dart       (Main UI)
├── database/
│   └── database_helper.dart      (Data operations)
├── models/
│   ├── product.dart
│   └── sale.dart
└── utils/
    └── receipt_generator.dart    (Receipt printing)
```

## 💡 Pro Tips

1. **Search focus**: Use `Ctrl+F` (planned) to quickly focus search
2. **Quick add**: Click product card anywhere to add
3. **Inline edit**: Use quantity steppers for fast adjustments
4. **Payment shortcuts**: One-click payment method selection
5. **Customer search**: Type name or phone for autocomplete

## 🎓 Learning Resources

- Material Design 3: https://m3.material.io/
- Flutter Desktop: https://docs.flutter.dev/platform-integration/desktop
- Tailwind Colors: https://tailwindcss.com/docs/customizing-colors

---

**Quick Start**: The search bar auto-focuses on load—start typing to find products immediately.

**Need Help?** See `BILLING_UI_REDESIGN.md` for comprehensive documentation.
