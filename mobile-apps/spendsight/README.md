# SpendSight - Personal Finance Tracker

A beautiful, fast, and intuitive Flutter mobile app for tracking personal finances with Material 3 design.

## Features

### 🎯 Core Screens
- **Splash Screen** - Animated welcome screen
- **Authentication** - Sign in/Sign up with email
- **Account Type Setup** - Choose between Personal, Family, or Couple accounts
- **Home Dashboard** - Quick overview of finances with balance, spending trends, and recent transactions
- **Add Transaction** - Fast expense/income entry with categories
- **Budgets** - Track spending against category budgets
- **Analytics** - Visual insights with pie charts and line graphs
- **Reports** - Monthly financial summaries and export options
- **Settings** - Profile, preferences, and account management

### 🎨 Design Principles
- ✅ **One-thumb usage** - All interactive elements within reach
- ✅ **Bottom navigation** - 5 main tabs (Home, Budgets, Analytics, Reports, Settings)
- ✅ **FAB for Add Expense** - Quick access to most common action
- ✅ **Large numbers** - Financial data is clear and readable
- ✅ **Simple language** - No accounting jargon
- ✅ **Material 3** - Modern, adaptive design system

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── models/
│   └── transaction.dart             # Transaction data model
├── screens/
│   ├── splash_screen.dart           # Animated splash
│   ├── auth_screen.dart             # Authentication
│   ├── account_type_screen.dart     # Account setup
│   ├── home_screen.dart             # Main navigation
│   ├── add_transaction_screen.dart  # Add expense/income
│   ├── budgets_screen.dart          # Budget tracking
│   ├── analytics_screen.dart        # Charts & insights
│   ├── reports_screen.dart          # Monthly reports
│   └── settings_screen.dart         # User preferences
└── widgets/
    └── overview_tab.dart            # Home dashboard content
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- iOS/Android Emulator or Physical Device

### Installation

1. **Clone or navigate to the project directory**
```bash
cd "e:\Vyoumix\BillEase Suite\mobile-apps\spendsight"
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Key Dependencies
- `material_color_utilities` - Material 3 color utilities
- `google_fonts` - Inter font family
- `flutter_animate` - Smooth animations
- `fl_chart` - Beautiful charts for analytics
- `provider` - State management
- `shared_preferences` - Local storage

## UI Highlights

### Home Dashboard
- Balance card with income/expense summary
- Quick action buttons (Add Income, Split Bill)
- Weekly spending bar chart
- Recent transaction list with icons

### Add Transaction
- Toggle between Expense/Income
- Large amount input with currency prefix
- Category chips with icons
- Date picker
- Optional note field

### Budgets
- Overall monthly budget progress
- Category-wise budget tracking
- Visual progress bars
- Overspending indicators

### Analytics
- Period selector (Week/Month/Year)
- Total spending card with trends
- Pie chart for category breakdown
- Line chart for spending trends
- Legend with amounts

### Reports
- Monthly summary cards
- Income/Expense/Saved breakdown
- Saving rate calculation
- Export and share options

### Settings
- Profile management
- Notifications toggle
- Dark mode toggle
- Currency selection
- Account type
- Privacy & security
- Help center
- Delete data option

## Design Choices

### Colors
- Primary: Purple (`#6750A4`) for brand identity
- System: Material 3 color schemes with light/dark mode
- Semantic: Green for income/positive, Red for expense/negative

### Typography
- Font: Inter (Google Fonts)
- Large financial numbers for readability
- Clear hierarchy with bold headings

### Navigation
- Bottom navigation bar (5 items max)
- FAB only on Home tab for quick expense entry
- Back navigation in full-screen dialogs

### Accessibility
- One-thumb friendly UI
- Large touch targets (min 48x48)
- Clear labels and icons
- High contrast text

## Future Enhancements
- [ ] Real backend integration
- [ ] Biometric authentication
- [ ] Recurring transactions
- [ ] Bill reminders
- [ ] Multi-currency support
- [ ] Bank account sync
- [ ] Receipt scanning
- [ ] Shared family budgets
- [ ] Investment tracking
- [ ] Tax reports

## License
MIT License - Feel free to use this project for learning or as a template for your own finance app.

---

Built with ❤️ using Flutter & Material 3
