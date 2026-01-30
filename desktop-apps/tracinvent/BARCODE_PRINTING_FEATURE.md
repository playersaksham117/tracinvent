# Barcode Printing Feature

## Overview
This feature allows users to print barcode stickers for inventory items with customizable sticker sizes. The barcode printing system is integrated into the Settings and Inventory sections of the application.

## Features

### 1. **Customizable Sticker Sizes**
Users can select from 4 predefined sticker sizes in Settings:
- **Small**: 2 x 1 inch (50.8 x 25.4 mm)
- **Medium**: 3 x 2 inch (76.2 x 50.8 mm) - Default
- **Large**: 4 x 2 inch (101.6 x 50.8 mm)
- **Extra Large**: 4 x 3 inch (101.6 x 76.2 mm)

### 2. **Barcode Sticker Content**
Each sticker includes:
- Product name (bold, 2 lines max)
- Barcode (auto-detects type: EAN13, EAN8, or Code128)
- Product SKU
- Selling price (optional, can be toggled in settings)

### 3. **Smart Barcode Type Detection**
The system automatically selects the appropriate barcode type:
- **EAN-13**: For 12-13 digit numeric codes
- **EAN-8**: For 7-8 digit numeric codes
- **Code-128**: For alphanumeric codes (default fallback)

### 4. **Multiple Copy Printing**
Users can print 1-100 copies of the same barcode sticker in a single print job.

## How to Use

### Step 1: Configure Barcode Settings
1. Navigate to **Settings** screen
2. Scroll to **Barcode Print Settings** section
3. Select your preferred **Sticker Size** from the dropdown
4. Toggle **Include Price on Barcode** (ON/OFF)

### Step 2: Print Barcode from Inventory
1. Go to **Inventory** screen
2. Find the product you want to print
3. Click the **three-dot menu** (⋮) on the product card
4. Select **Print Barcode**

### Step 3: Print Dialog
1. Review the barcode preview
2. Set the **Number of Copies** (1-100)
3. Verify the sticker size settings (shown in info box)
4. Click **Print** button
5. Select your printer and confirm

## Technical Details

### Files Created/Modified

#### New Files:
- `lib/services/barcode_print_service.dart` - Core printing service
- `lib/widgets/barcode_print_dialog.dart` - Print dialog UI

#### Modified Files:
- `lib/models/settings.dart` - Added barcode settings
- `lib/providers/settings_provider.dart` - Added barcode methods
- `lib/screens/settings_screen.dart` - Added barcode UI section
- `lib/screens/inventory_screen.dart` - Added print button
- `pubspec.yaml` - Added `barcode_widget: ^2.0.4`

### Dependencies
- **barcode_widget**: For barcode generation and display
- **pdf**: For PDF document generation
- **printing**: For print functionality

### Barcode Data Source
The system uses the following priority for barcode data:
1. Item's `barcode` field (if available)
2. Item's `sku` field (fallback)

## Settings Persistence
All barcode settings are saved automatically using SharedPreferences and persist between app sessions:
- Selected sticker size
- Include price preference

## Print Output
The print dialog uses the Flutter `printing` package which:
- Opens system print dialog
- Supports all connected printers
- Can save as PDF instead of printing
- Supports print preview

## Best Practices

1. **Use consistent barcode formats**: Try to maintain consistent SKU/barcode formats (all numeric or all alphanumeric)
2. **Test print first**: Print a single copy first to verify size and layout
3. **Update settings before bulk printing**: Configure size and price settings before printing multiple items
4. **Barcode scanner compatibility**: EAN-13 and Code-128 are widely supported by barcode scanners

## Future Enhancements (Potential)
- Custom sticker dimensions
- Logo/branding on stickers
- QR code support
- Batch printing for multiple items
- Export to PDF file
- Custom text fields on stickers

---
**Last Updated**: January 22, 2026
