# TracInvent - Inventory Tracking System

A comprehensive desktop inventory tracking application built with Flutter for Windows, Linux, and macOS.

## 🎯 Features

### 📊 Dashboard
- Overview cards showing total items, warehouses, and stock alerts
- Low stock and critical stock alerts with real-time monitoring
- Inventory value calculations
- Recent transaction history

### 📦 Inventory Management
- Add, edit, and delete inventory items
- Track SKU, barcode, category, and unit of measurement
- Set reorder levels and minimum stock thresholds
- Cost price and selling price tracking
- Real-time stock level monitoring across all locations

### 🏢 Warehouse & Storage Management
- Manage multiple warehouses, branches, and godowns
- Create storage locations (cells and racks) with position tracking
- Row, column, and level organization
- Location-based stock tracking
- Contact information for each location

### 💼 Transactions
- **Purchase Orders**: Record incoming stock with supplier details
- **Sales Orders**: Track outgoing stock with customer information
- Reference number tracking
- Date-based transaction history
- Automatic stock level updates
- Transaction filtering and search

### 🔔 Stock Alerts
- **Critical Stock**: Items below minimum stock level (RED alert)
- **Low Stock**: Items below reorder level (ORANGE alert)
- Visual indicators on dashboard and inventory screens

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Windows, Linux, or macOS desktop environment

### Installation

1. **Navigate to the project directory**
   ```bash
   cd "desktop-apps/tracinvent"
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d linux    # For Linux
   flutter run -d macos    # For macOS
   ```

### Build for Production

```bash
flutter build windows  # For Windows
flutter build linux    # For Linux
flutter build macos    # For macOS
```

The built application will be in the `build/` directory.

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── inventory_item.dart   # Inventory item model
│   ├── warehouse.dart        # Warehouse & storage location models
│   └── stock.dart            # Stock & transaction models
├── providers/                # State management
│   ├── inventory_provider.dart
│   └── warehouse_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart      # Main navigation
│   ├── dashboard_screen.dart # Dashboard overview
│   ├── inventory_screen.dart # Inventory management
│   ├── warehouses_screen.dart # Warehouse management
│   └── transactions_screen.dart # Transaction records
├── services/                 # Business logic
│   └── database_service.dart # SQLite database
└── widgets/                  # Reusable components
```

## 💾 Database

The application uses **SQLite** (via sqflite_common_ffi) for local data storage with the following tables:

- **inventory_items**: Product/item master data
- **warehouses**: Warehouse/branch/godown locations
- **storage_locations**: Cells, racks, and zones within warehouses
- **stock**: Current stock levels by item, warehouse, and location
- **transactions**: Purchase, sale, and transfer history

## 🎨 Technologies

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **SQLite**: Local database
- **Google Fonts**: Typography
- **FL Chart**: Data visualization
- **Material Design 3**: Modern UI components

## 📊 Key Metrics Tracked

- Total inventory items
- Number of warehouses/locations
- Low stock items count
- Critical stock items count
- Total inventory value
- Purchase and sale transactions
- Stock levels by location

## 🔧 Configuration

### Default Settings
- Minimum stock level: 5 units
- Reorder level: 10 units
- Currency: USD ($)

These can be customized when adding items.

## 📝 Usage Tips

1. **Start by adding warehouses**: Go to Warehouses screen and add your storage locations
2. **Add storage locations**: Create cells and racks within each warehouse
3. **Add inventory items**: Define your products with appropriate reorder levels
4. **Record transactions**: Use Purchase for incoming stock, Sale for outgoing
5. **Monitor dashboard**: Keep an eye on low stock alerts

## 🐛 Troubleshooting

**Database not initializing on Windows?**
- Ensure you have Visual C++ Redistributable installed
- Try running `flutter clean` and `flutter pub get`

**Build errors?**
- Make sure you're using Flutter 3.0 or higher
- Run `flutter doctor` to check for missing dependencies

## 📄 License

Proprietary - All rights reserved

## 👥 Support

For issues and questions, please contact the development team.

---

Built with ❤️ using Flutter
