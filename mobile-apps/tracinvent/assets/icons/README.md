# TracInvent Logo Files

This directory contains the logo files for TracInvent application.

## Files

### 1. `tracinvent_logo.svg` (512x512)
- High-resolution logo for general use
- Perfect for large displays, promotional materials
- Use in app headers, splash screens

### 2. `tracinvent_logo_horizontal.svg` (800x200)
- Horizontal layout with text
- Ideal for top navigation bars, headers
- Includes tagline "Smart Inventory Tracking"

### 3. `tracinvent_icon_simple.svg` (256x256)
- Simplified design optimized for small sizes
- Best for taskbar icons, shortcuts, favicons
- Bold lines ensure visibility at 16x16, 32x32, 48x48

## Converting to ICO (Windows Desktop Icon)

To create the Windows app icon (.ico file), you need to convert the SVG to ICO format with multiple resolutions.

### Online Tools (Easiest):
1. **Convertio** (https://convertio.co/svg-ico/)
   - Upload `tracinvent_icon_simple.svg`
   - Convert to ICO
   - Download and rename to `app_icon.ico`

2. **CloudConvert** (https://cloudconvert.com/svg-to-ico)
   - Upload `tracinvent_icon_simple.svg`
   - Select ICO format
   - Set sizes: 16, 32, 48, 64, 128, 256
   - Download

### Manual Steps (After Conversion):
1. Place the generated `app_icon.ico` file in:
   ```
   windows/runner/resources/app_icon.ico
   ```

2. The ICO file should contain these sizes:
   - 16x16 (taskbar small)
   - 32x32 (taskbar normal)
   - 48x48 (desktop icon)
   - 64x64 (large icons)
   - 128x128 (extra large)
   - 256x256 (jumbo icons)

## Using in Flutter App

### Top Bar Logo
Import in your screen widget:
```dart
import 'package:flutter_svg/flutter_svg.dart';

// In your build method:
SvgPicture.asset(
  'assets/icons/tracinvent_logo_horizontal.svg',
  height: 40,
)
```

### Ensure pubspec.yaml includes:
```yaml
dependencies:
  flutter_svg: ^2.0.0

flutter:
  assets:
    - assets/icons/
```

## Color Scheme

The logo uses the app's color palette:
- Primary Blue: `#3B82F6`
- Dark Blue: `#1E40AF`, `#2563EB`
- Success Green: `#10B981`
- Text Dark: `#0F172A`
- Text Gray: `#64748B`

## Design Elements

- **Warehouse Symbol**: Represents inventory storage
- **Shelves/Lines**: Symbolize organized inventory
- **Checkmark Badge**: Indicates tracking and verification
- **Gradient Background**: Modern, professional look
- **Clean Geometry**: Ensures scalability and clarity
