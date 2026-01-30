# TracInvent - Complete Feature Guide

## 🎯 Application Overview

TracInvent is a comprehensive desktop inventory tracking system designed for businesses that need to manage stock across multiple locations with precise tracking down to specific storage locations (cells and racks).

---

## 📊 1. Dashboard Features

### Overview Statistics
- **Total Items**: Count of all inventory items in the system
- **Warehouses**: Number of active storage locations
- **Low Stock Alerts**: Items below reorder level
- **Critical Stock Alerts**: Items below minimum stock level
- **Inventory Value**: Total value of all stock at cost price

### Stock Alert System
- **Critical Alerts (RED)**: Items at or below minimum stock level
- **Low Stock Alerts (ORANGE)**: Items at or below reorder level
- Real-time monitoring and visual indicators
- Quick view of item details and current stock

### Recent Activity
- Last 5 transactions displayed
- Transaction type indicators (Purchase/Sale/Transfer)
- Date and quantity information
- Quick reference to recent stock movements

---

## 📦 2. Inventory Management

### Item Management
- **Add New Items**: Complete item profile creation
- **Edit Items**: Update item information
- **Delete Items**: Remove items from inventory
- **View Details**: Comprehensive item information display

### Item Information Fields
- **Basic Info**:
  - Item Name
  - SKU (Stock Keeping Unit)
  - Barcode (optional)
  - Category
  - Unit of Measurement (pcs, kg, ltr, etc.)

- **Stock Levels**:
  - Reorder Level: Triggers low stock warning
  - Minimum Stock Level: Critical stock threshold
  - Current Stock: Calculated across all locations

- **Pricing**:
  - Cost Price: Purchase price
  - Selling Price: Sale price
  - Automatic margin calculation

- **Additional**:
  - Description
  - Created and Updated timestamps

### Search and Filtering
- **Search**: By name or SKU
- **Category Filter**: Filter items by category
- **Stock Status**: Visual indicators (In Stock/Low Stock/Critical)

### Stock Monitoring
- Real-time stock levels across all warehouses
- Color-coded status indicators
- Quick view of stock thresholds
- Total stock calculation from all locations

---

## 🏢 3. Warehouse & Storage Management

### Warehouse Types
1. **Warehouse**: Large storage facility
2. **Branch**: Retail or distribution branch
3. **Godown**: Storage depot

### Warehouse Information
- **Location Details**:
  - Name
  - Address
  - City, State, Pincode
  
- **Contact Information**:
  - Contact Person
  - Contact Phone
  
- **Status**:
  - Active/Inactive toggle
  - Creation date tracking

### Storage Locations (Cells & Racks)

#### Location Types
1. **Cell**: Individual storage unit
2. **Rack**: Shelf or rack system
3. **Zone**: Area designation

#### Location Details
- **Code**: Unique identifier (e.g., A1, RACK-01, ZONE-A)
- **Description**: Location details
- **Position Tracking**:
  - Row number
  - Column number
  - Level/Height
- **Warehouse Association**: Linked to parent warehouse

### Visual Organization
- Grid-based location display
- Color-coded location types
- Easy location management
- Quick stock assignment to locations

---

## 💼 4. Transaction Management

### Transaction Types

#### Purchase Orders
- Record incoming stock
- **Required Information**:
  - Item selection
  - Warehouse/Location
  - Quantity received
  - Unit price
  - Total amount (auto-calculated)
  
- **Optional Information**:
  - Reference/Invoice number
  - Supplier name
  - Transaction date
  - Notes

#### Sales Orders
- Record outgoing stock
- **Required Information**:
  - Item selection
  - Warehouse/Location
  - Quantity sold
  - Unit price
  - Total amount (auto-calculated)
  
- **Optional Information**:
  - Reference/Invoice number
  - Customer name
  - Transaction date
  - Notes

### Automatic Stock Updates
- Stock levels automatically adjusted on transaction
- Real-time inventory updates
- Location-specific stock tracking
- Transaction history maintained

### Transaction History
- Complete transaction log
- Filter by transaction type
- Search by item or warehouse
- Date-based sorting
- Reference number tracking

### Transaction Details Display
- Transaction type with color coding
- Item information
- Quantity and pricing
- Date and time
- Reference numbers
- Party information (Supplier/Customer)
- Notes and additional details

---

## 🔔 5. Alert System

### Low Stock Monitoring

#### Critical Stock (RED)
- Triggers when: Stock ≤ Minimum Stock Level
- Visual indicator: Red background
- Priority: High
- Action: Immediate reordering required

#### Low Stock (ORANGE)
- Triggers when: Stock ≤ Reorder Level
- Visual indicator: Orange background
- Priority: Medium
- Action: Plan for reordering

#### In Stock (GREEN)
- Triggers when: Stock > Reorder Level
- Visual indicator: Green background
- Status: Normal

### Alert Notifications
- Dashboard alerts widget
- Inventory screen indicators
- Threshold-based triggering
- Real-time updates

---

## 💾 6. Database & Data Management

### Local SQLite Database
- **Location**: Application documents folder
- **File**: tracinvent.db
- **Auto-backup**: Recommended for production use

### Tables Structure

1. **inventory_items**: Master item data
2. **warehouses**: Location information
3. **storage_locations**: Cells and racks
4. **stock**: Current stock levels
5. **transactions**: All stock movements

### Data Relationships
- Items linked to stock records
- Stock linked to warehouses and locations
- Transactions linked to items and warehouses
- Foreign key constraints maintain data integrity

---

## 🎨 7. User Interface Features

### Navigation
- **Side Navigation Rail**: Quick access to main sections
- **Icon-based Navigation**: Visual section identification
- **Persistent Navigation**: Stays visible across screens

### Material Design 3
- Modern, clean interface
- Consistent color scheme
- Responsive layouts
- Smooth animations

### Forms and Dialogs
- Modal dialogs for data entry
- Form validation
- Required field indicators
- Helpful placeholders

### Data Display
- Card-based layouts
- List views with sorting
- Grid views for locations
- Color-coded status indicators

---

## 📈 8. Reporting & Analytics

### Current Metrics
- Total inventory value
- Stock level summaries
- Transaction summaries
- Low stock reports

### Future Enhancements (Planned)
- Stock movement reports
- Purchase/Sale analytics
- Supplier/Customer reports
- Export to PDF/Excel
- Profit margin analysis

---

## 🔧 9. Configuration Options

### Customizable Settings
- **Units**: Define custom measurement units
- **Categories**: Create item categories
- **Stock Thresholds**: Set per-item reorder levels
- **Currency**: Default USD, customizable per item

### Default Values
- Minimum Stock: 5 units
- Reorder Level: 10 units
- Can be changed per item

---

## 🚀 10. Best Practices

### Setup Workflow
1. **Add Warehouses First**
   - Create all storage locations
   - Add contact information
   
2. **Define Storage Locations**
   - Create cells and racks
   - Organize by row, column, level
   
3. **Add Inventory Items**
   - Complete item information
   - Set appropriate thresholds
   
4. **Record Initial Stock**
   - Use purchase transactions
   - Assign to correct locations
   
5. **Monitor Dashboard**
   - Check alerts regularly
   - Track stock movements

### Data Management
- Regular backups recommended
- Consistent naming conventions
- Use meaningful SKUs
- Keep descriptions updated
- Archive old transactions periodically

### Stock Control
- Set realistic reorder levels
- Monitor critical alerts daily
- Regular stock audits
- Update prices periodically
- Track supplier information

---

## 🎯 11. Key Benefits

1. **Multi-Location Support**: Track stock across unlimited warehouses
2. **Precise Location Tracking**: Down to cell and rack level
3. **Real-Time Alerts**: Never run out of critical stock
4. **Complete Transaction History**: Full audit trail
5. **Easy to Use**: Intuitive interface, minimal training required
6. **Offline Capable**: No internet required, all data local
7. **Cross-Platform**: Works on Windows, Linux, and macOS
8. **Fast Performance**: SQLite database, instant queries
9. **Scalable**: Handles thousands of items and locations
10. **No Subscription**: One-time setup, no recurring fees

---

## 📱 12. System Requirements

### Minimum Requirements
- **OS**: Windows 10+, Ubuntu 20.04+, or macOS 10.14+
- **RAM**: 4GB (8GB recommended)
- **Storage**: 500MB free space
- **Display**: 1366x768 minimum resolution

### Recommended
- **OS**: Windows 11, Ubuntu 22.04+, or macOS 12+
- **RAM**: 8GB or more
- **Storage**: 2GB free space
- **Display**: 1920x1080 or higher
- **SSD**: For better performance

---

## 🔐 13. Security Features

### Data Protection
- Local database storage
- No cloud dependency
- User-controlled backups
- Data stays on your device

### Future Enhancements (Planned)
- User authentication
- Role-based access control
- Database encryption
- Activity logging

---

## 📞 14. Support & Maintenance

### Troubleshooting
- Check README.md for common issues
- Run `flutter doctor` for system diagnostics
- Verify database file permissions
- Check disk space availability

### Updates
- Regular feature enhancements
- Bug fixes and improvements
- Performance optimizations
- New reporting capabilities

---

## 🌟 15. Future Roadmap

### Planned Features
- [ ] Barcode scanning support
- [ ] PDF report generation
- [ ] Export to Excel
- [ ] Multi-user support
- [ ] Cloud sync option
- [ ] Mobile companion app
- [ ] Batch operations
- [ ] Advanced analytics
- [ ] Stock valuation methods (FIFO/LIFO/Average)
- [ ] Expiry date tracking
- [ ] Serial number tracking
- [ ] Purchase order management
- [ ] Supplier management
- [ ] Email notifications
- [ ] Dashboard customization

---

**Version**: 1.0.0  
**Last Updated**: January 2026  
**Built with**: Flutter & SQLite
