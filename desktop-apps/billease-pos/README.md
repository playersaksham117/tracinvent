# 🏪 BillEase POS - Flutter Edition

**Premium Offline-First Point of Sale System**

## ✨ Features

### 🚀 Core Capabilities
- **Offline-First Architecture** - Works without internet, syncs automatically when online
- **SQLite Local Database** - Fast, reliable local data storage
- **Automatic Sync** - Background sync to Supabase when connected
- **Real-time Inventory** - Live stock updates
- **Premium UI/UX** - Beautiful, modern Flutter design
- **Cross-Platform** - Android, iOS, Windows, macOS, Linux

### 💳 Point of Sale
- Fast product search and barcode scanning
- Shopping cart management
- Multiple payment methods (Cash, Card, UPI, Wallet)
- Automatic tax calculations
- Discount support
- Customer selection
- Receipt printing (PDF)
- Change calculation

### 📦 Inventory Management
- Product catalog with images
- Stock tracking
- Low stock alerts
- Stock adjustments with history
- Category and brand organization
- Barcode support

### 👥 Customer Management
- Customer profiles
- Purchase history
- Contact information
- Customer groups (Regular/VIP/Wholesale)
- Loyalty points

### 📊 Sync & Analytics
- Online/Offline indicator
- Pending sync counter
- Manual sync trigger
- Sales statistics
- Dashboard overview

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode (for mobile development)
- Supabase account (for cloud sync)

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd desktop-app/flutter_pos
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   
   Edit `lib/main.dart` and add your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. **Run the app**
   
   **Desktop (Windows/macOS/Linux):**
   ```bash
   flutter run -d windows  # or macos, linux
   ```
   
   **Android:**
   ```bash
   flutter run -d android
   ```
   
   **iOS:**
   ```bash
   flutter run -d ios
   ```

## 📱 Platform-Specific Setup

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 33
- Permissions: Camera, Bluetooth, Internet

### iOS
- Minimum iOS: 12.0
- Permissions: Camera, Bluetooth
- Requires Xcode 13+

### Windows
- Windows 10 or later
- Visual Studio 2019 or later

### macOS
- macOS 10.14 or later
- Xcode 13+

### Linux
- GTK 3 or later
- Common Linux development packages

## 🏗️ Architecture

### Offline-First Design
```
┌─────────────────┐
│   Flutter UI    │
└────────┬────────┘
         │
┌────────▼────────┐
│  Local SQLite   │  ◄── Primary Data Source
│    Database     │
└────────┬────────┘
         │
┌────────▼────────┐
│  Sync Service   │  ◄── Background Sync
└────────┬────────┘
         │
┌────────▼────────┐
│    Supabase     │  ◄── Cloud Backup
│  (PostgreSQL)   │
└─────────────────┘
```

### Key Components

**Database Layer** (`lib/database/`)
- `database_helper.dart` - SQLite database management
- 8 tables with indexes and constraints
- CRUD operations
- Sync status tracking

**Models** (`lib/models/`)
- `models.dart` - Product, Customer, Sale, SaleItem, PaymentMethod
- Type-safe data models
- JSON serialization

**Services** (`lib/services/`)
- `sync_service.dart` - Offline/online sync
- `receipt_service.dart` - PDF receipt generation
- Connectivity monitoring
- Automatic background sync

**Screens** (`lib/screens/`)
- `dashboard_screen.dart` - Main dashboard with stats
- `pos_screen.dart` - Point of sale interface

**Widgets** (`lib/widgets/`)
- `premium_widgets.dart` - Reusable UI components
- Premium design system
- Consistent styling

## 🎨 UI Design

### Color Scheme
- **Primary:** Indigo (#6366F1)
- **Secondary:** Emerald (#10B981)
- **Accent:** Amber (#F59E0B)
- **Success:** Green (#10B981)
- **Error:** Red (#EF4444)

### Typography
- Font Family: Poppins
- Premium card designs
- Gradient buttons
- Smooth animations

## 💾 Database Schema

### Products Table
- Local storage with sync status
- Stock tracking
- Barcode support
- Category organization

### Customers Table
- Contact information
- Purchase history
- Loyalty program

### Sales Table
- Invoice management
- Payment tracking
- Tax and discount calculations

### Sale Items Table
- Line item details
- Automatic calculations

### Stock Adjustments Table
- Adjustment history
- Reason tracking

### Sync Queue Table
- Pending operations
- Retry mechanism

## 🔄 Sync Mechanism

### How It Works
1. All operations save to **local SQLite first**
2. Records marked with `sync_status = 0` (pending)
3. **Sync Service** monitors connectivity
4. When online, automatically uploads pending records
5. Server returns IDs, local records updated
6. `sync_status` set to `1` (synced)

### Sync Triggers
- Manual sync button press
- Periodic timer (every 5 minutes)
- Connectivity restored
- App foreground

### Conflict Resolution
- Local changes always prioritized
- Server as backup/restore point
- Upsert operations for products/customers

## 📄 Receipt Printing

### Features
- PDF generation using `printing` package
- Thermal printer support (80mm)
- Professional layout
- Item details
- Tax and discount breakdown
- Payment information

### Print Options
- Preview before printing
- Direct print to thermal printer
- Save as PDF
- Share receipt

## 🔐 Security

- Supabase Row Level Security (RLS)
- Multi-tenant isolation
- Secure token storage
- Encrypted communications
- Local data encryption (optional)

## 🚀 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Linux
```bash
flutter build linux --release
```

## 📦 Build Output
- **Android:** `build/app/outputs/flutter-apk/app-release.apk`
- **iOS:** `build/ios/iphoneos/Runner.app`
- **Windows:** `build/windows/runner/Release/`
- **macOS:** `build/macos/Build/Products/Release/`
- **Linux:** `build/linux/x64/release/bundle/`

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

## 🐛 Troubleshooting

### Database Issues
```dart
// Clear database and reset
await DatabaseHelper.instance.close();
await deleteDatabase('billease_pos.db');
```

### Sync Problems
- Check internet connectivity
- Verify Supabase credentials
- Check sync queue: `SELECT * FROM sync_queue`
- Manual sync from dashboard

### Barcode Scanner Not Working
- Grant camera permissions
- Check device camera
- Test with manual barcode entry

### Receipt Printing Issues
- Check printer connection
- Verify Bluetooth permissions
- Test with PDF preview

## 📊 Performance

### Optimizations
- Indexed database queries
- Lazy loading for large lists
- Image caching
- Efficient state management
- Background sync (non-blocking)

### Recommended Hardware
- **Minimum:** 2GB RAM, dual-core processor
- **Recommended:** 4GB+ RAM, quad-core processor
- **Storage:** 500MB free space

## 🔄 Updates & Maintenance

### Update Flutter Dependencies
```bash
flutter pub upgrade
```

### Database Migrations
- Increment version in `database_helper.dart`
- Add migration logic in `_upgradeDB()`

## 📞 Support

- Check documentation
- Review code comments
- Test with sample data
- Contact development team

## 🎉 Success Checklist

- [ ] Flutter SDK installed
- [ ] Dependencies fetched
- [ ] Supabase configured
- [ ] App running successfully
- [ ] Database created
- [ ] Products added
- [ ] Test sale completed
- [ ] Receipt printed
- [ ] Sync working

## 📝 License

Part of the BillEase Suite

---

**Built with Flutter & ❤️**

Premium Offline-First POS System
