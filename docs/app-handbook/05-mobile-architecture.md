# Mobile App Architecture & Usage

## Architecture
- Screens: `lib/screens`
- Providers: `lib/providers`
- Models: `lib/models`
- Services/DB: `lib/services`
- Assets: `assets/icons`, `assets/images`

The mobile app mirrors desktop business logic while adapting navigation and layouts for smaller screens.

## Setup & Run
1. Open terminal in `mobile-apps/tracinvent_mobile`
2. Install packages: `flutter pub get`
3. Check devices: `flutter devices`
4. Run on device/emulator: `flutter run -d <device_id>`

## Typical Mobile Workflow
- Open Dashboard for health status
- Use Inventory for item edits and barcode search
- Execute stock operations and adjustments
- Review warehouse-specific movement history

## Testing
- Static checks: `flutter analyze`
- Widget tests: `flutter test`

## Common Issues
- "Target file from not found": run `flutter run` only (no "from" keyword)
- Device not found: start emulator or connect phone with USB debugging
- Web/desktop target mismatch: ensure project platform support aligns with chosen device

## Change Management Notes
- Keep service APIs consistent between desktop and mobile
- Add mobile UI fallback for wide desktop-only widgets
- Validate all provider async flows for mounted-context safety
