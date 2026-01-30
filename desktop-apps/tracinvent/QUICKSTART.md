# TracInvent - Quick Start Guide

## ⚡ Get Started in 5 Minutes

### Step 1: Setup (First Time Only)

**Windows:**
```bash
cd desktop-apps/tracinvent
setup.bat
```

**Linux/Mac:**
```bash
cd desktop-apps/tracinvent
chmod +x setup.sh
./setup.sh
```

### Step 2: Run the Application

```bash
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d macos    # macOS
```

---

## 📋 Initial Setup Workflow

### 1. Add Your First Warehouse (30 seconds)
1. Click **Warehouses** in the left menu
2. Click the **+** button
3. Fill in:
   - Name: "Main Warehouse"
   - Type: Warehouse
   - Address: Your address
4. Click **Add**

### 2. Add Storage Locations (1 minute)
1. Select the warehouse you just created
2. Click **Add Location**
3. Add a few locations:
   - Code: "A1", Type: Cell
   - Code: "A2", Type: Cell
   - Code: "RACK-01", Type: Rack
4. Click **Add** for each

### 3. Add Your First Items (2 minutes)
1. Click **Inventory** in the left menu
2. Click the **+** button
3. Fill in item details:
   - Name: "Product Name"
   - SKU: "PROD-001"
   - Category: "Electronics" (or your category)
   - Unit: "pcs"
   - Reorder Level: 10
   - Min Stock: 5
   - Cost Price: 50
   - Selling Price: 75
4. Click **Add Item**
5. Repeat for more items

### 4. Record Your First Purchase (1 minute)
1. Click **Transactions** in the left menu
2. Click the **+** button → **Purchase**
3. Select:
   - Item you created
   - Warehouse location
   - Storage location (optional)
   - Quantity: 100
   - Unit Price: 50
   - Supplier: "Supplier Name"
4. Click **Record Purchase**

### 5. Check Your Dashboard
1. Click **Dashboard** in the left menu
2. See your inventory value, stock levels, and recent transactions!

---

## 🎯 Common Tasks

### Record a Sale
1. Go to **Transactions**
2. Click **+** → **Sale**
3. Select item, location, quantity
4. System automatically reduces stock

### Check Low Stock Items
1. Go to **Dashboard**
2. View "Stock Alerts" section
3. Items in RED are critical
4. Items in ORANGE are low stock

### Add More Storage Locations
1. Go to **Warehouses**
2. Select a warehouse
3. Click **Add Location**
4. Define cells, racks, or zones

### View Item Stock Across Locations
1. Go to **Inventory**
2. Click on any item
3. View total stock and locations

---

## 💡 Tips & Tricks

### SKU Naming
- Use consistent format: `CAT-001`, `PROD-001`
- Include category prefix
- Use numbers for easy sorting

### Stock Levels
- **Minimum Stock**: Absolute lowest (emergency)
- **Reorder Level**: Trigger for ordering (comfortable buffer)
- Example: Min=5, Reorder=20 means order when it hits 20

### Organize Warehouses
- Use descriptive names
- Add contact information
- Mark inactive ones instead of deleting

### Storage Locations
- Use grid system: A1, A2, B1, B2
- Or use descriptive: RACK-01, SHELF-A
- Add row/column/level for 3D organization

---

## 🚀 Build for Production

### Windows
```bash
flutter build windows --release
```
Output: `build/windows/runner/Release/`

### Linux
```bash
flutter build linux --release
```
Output: `build/linux/x64/release/bundle/`

### macOS
```bash
flutter build macos --release
```
Output: `build/macos/Build/Products/Release/`

---

## 🔍 Keyboard Shortcuts

- **Alt+1**: Dashboard
- **Alt+2**: Inventory
- **Alt+3**: Warehouses
- **Alt+4**: Transactions
- **Ctrl+F**: Search (where applicable)
- **Escape**: Close dialogs

---

## ❓ Troubleshooting

**App won't start?**
- Run `flutter doctor` to check setup
- Ensure all dependencies installed: `flutter pub get`

**Database errors?**
- Check write permissions in Documents folder
- Try running as administrator (Windows)

**Items not showing?**
- Click refresh icon in app bar
- Restart the application

**Can't add transactions?**
- Ensure you have both warehouses AND items created first

---

## 📚 Next Steps

1. **Read FEATURES.md**: Complete feature guide
2. **Read README.md**: Detailed documentation
3. **Import your data**: Start with your actual inventory
4. **Set stock alerts**: Configure thresholds for your business
5. **Regular backups**: Backup tracinvent.db file regularly

---

## 🎉 You're Ready!

Your TracInvent inventory system is now set up and ready to use. Start tracking your inventory with precision!

**Need Help?** Check the documentation files:
- `README.md` - Full documentation
- `FEATURES.md` - Complete feature list
- Project issues/support channel

---

**Happy Tracking! 📦**
