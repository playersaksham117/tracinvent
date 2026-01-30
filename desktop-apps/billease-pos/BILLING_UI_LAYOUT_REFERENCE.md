# Billing Screen Layout - Visual Reference

## Desktop Layout (1920x1080 Example)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  ╔════════════════════════════════════════════════════════════════════════════════════╗ │
│  ║  🛒 Point of Sale                                         📜 History              ║ │
│  ╚════════════════════════════════════════════════════════════════════════════════════╝ │
├──────────────┬────────────────────────────────────────────────┬─────────────────────────┤
│              │                                                │                         │
│   SEARCH     │            PRODUCT GRID                        │    BILLING PANEL        │
│   PANEL      │            (Center View)                       │    (Sticky Right)       │
│              │                                                │                         │
│  ┌─────────┐ │                                                │  ╔═══════════════════╗ │
│  │ 🔍 SKU, │ │   ┌──────────┐ ┌──────────┐ ┌──────────┐    │  ║   INVOICE         ║ │
│  │  Name,  │ │   │ Laptop   │ │ Mouse    │ │ Keyboard │    │  ║   #INV/2026/001   ║ │
│  │ Barcode │ │   │ [42]     │ │ [156]    │ │ [89]     │    │  ║   09 Jan 2026     ║ │
│  └─────────┘ │   │          │ │          │ │          │    │  ║   03:45 PM        ║ │
│              │   │ ₹45,999  │ │ ₹599     │ │ ₹1,299   │    │  ╚═══════════════════╝ │
│  ┌─────────┐ │   │      [+] │ │      [+] │ │      [+] │    │                         │
│  │ 💻 Laptop│ │   └──────────┘ └──────────┘ └──────────┘    │  ▼ Customer Details     │
│  │ ₹45,999 │ │                                                │  (Collapsible)          │
│  │ Stock:42│ │   ┌──────────┐ ┌──────────┐ ┌──────────┐    │  ────────────────────    │
│  │      [+]│ │   │ Headset  │ │ Webcam   │ │ Monitor  │    │                         │
│  └─────────┘ │   │ [23]     │ │ [67]     │ │ [34]     │    │  🛒 CART ITEMS          │
│              │   │          │ │          │ │          │    │                         │
│  ┌─────────┐ │   │ ₹2,499   │ │ ₹4,999   │ │ ₹18,999  │    │  ┌─────────────────┐   │
│  │ 🖱️ Mouse │ │   │      [+] │ │      [+] │ │      [+] │    │  │ Laptop      [×] │   │
│  │ ₹599    │ │   └──────────┘ └──────────┘ └──────────┘    │  │ ₹45,999 × 1     │   │
│  │ Stock156│ │                                                │  │ [-] 1 [+] 45,999│   │
│  │      [+]│ │   ┌──────────┐ ┌──────────┐ ┌──────────┐    │  └─────────────────┘   │
│  └─────────┘ │   │ Cables   │ │ USB Hub  │ │ Speakers │    │                         │
│      ▼       │   │ [234]    │ │ [89]     │ │ [45]     │    │  ┌─────────────────┐   │
│              │   │          │ │          │ │          │    │  │ Mouse       [×] │   │
│              │   │ ₹299     │ │ ₹1,799   │ │ ₹3,499   │    │  │ ₹599 × 2        │   │
│              │   │      [+] │ │      [+] │ │      [+] │    │  │ [-] 2 [+]  1,198│   │
│              │   └──────────┘ └──────────┘ └──────────┘    │  └─────────────────┘   │
│              │                                                │                         │
│              │   (Scrollable grid - 2 or 3 columns)           │  (Scrollable cart)      │
│              │                                                │  ────────────────────    │
│     25%      │                  45%                           │                         │
│              │                                                │  Subtotal    ₹47,197   │
│              │                                                │  Tax (18%)    ₹8,495   │
│              │                                                │  ────────────────────    │
│              │                                                │  ╔══════════════════╗   │
│              │                                                │  ║ TOTAL   ₹55,692 ║   │
│              │                                                │  ╚══════════════════╝   │
│              │                                                │                         │
│              │                                                │  Payment Method         │
│              │                                                │  ┌─────────────────┐   │
│              │                                                │  │💵│💳│📱│👛      │   │
│              │                                                │  └─────────────────┘   │
│              │                                                │                         │
│              │                                                │  Payment Status         │
│              │                                                │  ┌─────────────────┐   │
│              │                                                │  │Full│Part│Credit│   │
│              │                                                │  └─────────────────┘   │
│              │                                                │                         │
│              │                                                │  ₹ Amount Paid          │
│              │                                                │  [  55,700  ]           │
│              │                                                │                         │
│              │                                                │  ┌─────────────────┐   │
│              │                                                │  │ Change: ₹8      │   │
│              │                                                │  └─────────────────┘   │
│              │                                                │                         │
│              │                                                │  ┌═══════════════════┐ │
│              │                                                │  │  Complete Sale    │ │
│              │                                                │  └═══════════════════┘ │
│              │                                                │         30%             │
└──────────────┴────────────────────────────────────────────────┴─────────────────────────┘
```

## Color-Coded Sections

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ████████████████████████████████████████████████████████████████████      │ ← Dark Slate
│  App Bar (Navigation + Actions)                                            │   #1E293B
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│  ░░░░░░░░░░  │ ← White Background
│  Search      │   #FFFFFF
│  Panel       │   
│  (Border)    │ ← Light Gray Border
│              │   #E2E8F0
└──────────────┘

┌──────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ ← Light Gray Background
│  Product Grid            │   #F8F9FA
│                          │
│  ┌────────┐              │ ← White Cards
│  │ Card   │              │   #FFFFFF
│  └────────┘              │   with Border #E2E8F0
└──────────────────────────┘

┌─────────────────────────┐
│  ████████████████████   │ ← Dark Gradient Header
│  Invoice Header         │   #1E293B → #334155
└─────────────────────────┘

┌─────────────────────────┐
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │ ← Light Background
│  Cart Items             │   #FAFAFA
└─────────────────────────┘

┌─────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░   │ ← Very Light Background
│  Totals Section         │   #F8FAFC
│  ┌─────────────┐        │
│  │████████████ │        │ ← Dark Total Card
│  │ TOTAL: ₹... │        │   #1E293B
│  └─────────────┘        │
└─────────────────────────┘

┌─────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │ ← Blue Primary Button
│  Complete Sale          │   #3B82F6
└─────────────────────────┘
```

## Mobile/Tablet (NOT Optimized - Desktop Only)

```
Desktop screens 1366x768 and above recommended.
This layout is NOT designed for mobile/tablet use.
Use the mobile-optimized POS screen for those devices.
```

## Empty States

### No Products

```
┌──────────────────────────────────────┐
│                                      │
│            ┌───────────┐             │
│            │  ▓▓▓▓▓▓▓  │             │
│            │  🛍️       │             │
│            │  Empty    │             │
│            └───────────┘             │
│                                      │
│      No products available           │
│   Search or scan a product           │
│        to get started                │
│                                      │
└──────────────────────────────────────┘
```

### Empty Cart

```
┌──────────────────────────────────────┐
│                                      │
│            ┌───────────┐             │
│            │  ▓▓▓▓▓▓▓  │             │
│            │  🛒       │             │
│            │  Empty    │             │
│            └───────────┘             │
│                                      │
│         Cart is empty                │
│   Add products to start billing      │
│                                      │
└──────────────────────────────────────┘
```

## Interaction States

### Product Card - Hover

```
┌──────────────┐
│ Laptop   [42]│ ← Stock badge
│ SKU: LP-001  │
│              │
│ ₹45,999  [+] │ ← Add button highlighted
└──────────────┘
    ↑
 Blue border (#3B82F6) on hover
```

### Cart Item

```
┌─────────────────────────────┐
│ Laptop              [×]     │ ← Close button
│ ₹45,999 × 1                 │
│                             │
│ ┌─────────┐    ₹45,999     │
│ │[-] 1 [+]│                 │ ← Quantity stepper
│ └─────────┘                 │
└─────────────────────────────┘
```

### Payment Method Selector (Segmented)

```
┌────────────────────────────────┐
│ [💵] [💳] [📱] [👛]             │
│ Cash Card  UPI Wallet           │
└────────────────────────────────┘
     ↑
  Selected (Blue fill #3B82F6)
```

### Payment Status Selector

```
┌─────────────────────────────┐
│ [Full] [Partial] [Credit]   │
└─────────────────────────────┘
   ↑        ↑          ↑
  Green   Amber      Red
  #16A34A #F59E0B   #DC2626
```

## Responsive Breakpoints

### < 1200px (Small Desktop)

```
┌──────────────────────────────────────┐
│  [Search]  [Product Grid]  [Billing] │
│   Panel      2 Columns      Panel    │
│   25%          45%            30%    │
└──────────────────────────────────────┘
```

### ≥ 1200px (Standard Desktop)

```
┌──────────────────────────────────────┐
│  [Search]  [Product Grid]  [Billing] │
│   Panel      3 Columns      Panel    │
│   25%          45%            30%    │
└──────────────────────────────────────┘
```

### 4K Display (3840x2160)

```
┌────────────────────────────────────────────┐
│  [Search]  [Product Grid]    [Billing]     │
│   Panel      3 Columns        Panel        │
│   25%          45%              30%        │
│  (Larger      (Larger          (Larger     │
│   spacing)     cards)           text)      │
└────────────────────────────────────────────┘
```

## Keyboard Navigation Flow

```
[Search Field] → [Product Cards] → [Customer Name] → [Customer Phone] →
[Cart Items] → [Payment Method] → [Payment Status] → [Amount Paid] →
[Complete Sale Button]

Shortcut Keys (Planned):
Ctrl+F  → Focus search
Ctrl+P  → Focus paid amount
Enter   → Complete sale
Esc     → Clear search
F1-F4   → Payment methods
```

## Visual Hierarchy

```
1. HIGHEST PRIORITY (Largest, Boldest)
   - Grand Total Amount (24px, white on dark)
   - Invoice Number (20px, white on dark)
   - Complete Sale Button (52px height)

2. HIGH PRIORITY
   - Product Prices (18px, bold)
   - Cart Item Totals (15px, bold)
   - Payment Method Icons

3. MEDIUM PRIORITY
   - Product Names (14px, semi-bold)
   - Cart Item Names (13px, semi-bold)
   - Labels (13px, medium)

4. LOW PRIORITY
   - SKUs (11px, regular)
   - Metadata (12px, muted)
   - Stock counts (10px, badge)
```

## Spacing System

```
┌─────────────────────┐
│  ↕ 20px             │  ← Top padding
│  ← 20px             │  ← Left padding
│                     │
│  ┌───────────────┐  │
│  │  Card Content │  │
│  │  ↕ 12px       │  │  ← Inner padding
│  │  ← 12px       │  │
│  └───────────────┘  │
│                     │
│        ↕ 12px       │  ← Gap between cards
│  ┌───────────────┐  │
│  │  Card Content │  │
│  └───────────────┘  │
│                     │
└─────────────────────┘
```

## Design Token Reference

```
┌─────────────────────────────────────┐
│  BACKGROUNDS                        │
├─────────────────────────────────────┤
│  Page:   #F8F9FA  ░░░░░░░░░        │
│  Card:   #FFFFFF  ▓▓▓▓▓▓▓▓▓        │
│  Input:  #F8FAFC  ▒▒▒▒▒▒▒▒▒        │
├─────────────────────────────────────┤
│  BORDERS                            │
├─────────────────────────────────────┤
│  Primary: #E2E8F0  ─────────────    │
│  Subtle:  #F1F5F9  ..................│
├─────────────────────────────────────┤
│  TEXT                               │
├─────────────────────────────────────┤
│  Primary:   #1E293B  ████████       │
│  Secondary: #475569  ▓▓▓▓▓▓▓▓       │
│  Tertiary:  #64748B  ▒▒▒▒▒▒▒▒       │
│  Muted:     #94A3B8  ░░░░░░░░       │
├─────────────────────────────────────┤
│  ACCENTS                            │
├─────────────────────────────────────┤
│  Blue:   #3B82F6  🔵               │
│  Green:  #16A34A  🟢               │
│  Amber:  #F59E0B  🟠               │
│  Red:    #DC2626  🔴               │
└─────────────────────────────────────┘
```

---

**This is a reference guide for the redesigned billing screen layout.**

For implementation details, see:
- `BILLING_UI_REDESIGN.md` (Technical documentation)
- `BILLING_UI_QUICK_GUIDE.md` (Developer reference)
- `BILLING_UI_IMPLEMENTATION_SUMMARY.md` (Overview)
