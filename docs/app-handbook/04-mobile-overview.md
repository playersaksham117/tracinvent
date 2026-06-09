# Mobile App Overview (tracinvent_mobile)

## Purpose
Mobile companion app for TracInvent, built to provide the same core operational functionality with touch-friendly navigation.

## Feature Coverage
- Inventory CRUD and search (name/SKU/barcode)
- Warehouse-aware stock visibility
- Stock movement operations
- Adjustments and batch handling
- Dashboard KPIs, alerts, and recent activity
- Settings and sync/update pathways

## UX Differences vs Desktop
- Bottom navigation for key sections
- Drawer menu for full module access
- Mobile dashboard layout for narrow screens
- Touch-optimized cards/forms/list flows

## Tech Stack
- Flutter (Android/iOS)
- Provider state management (same pattern as desktop)
- SQLite via `sqflite` (mobile-native)

## Project Entry
- App entrypoint: `mobile-apps/tracinvent_mobile/lib/main.dart`
- Mobile shell: `mobile-apps/tracinvent_mobile/lib/screens/home_screen.dart`
