# Desktop App Overview (TracInvent)

## Purpose
TracInvent Desktop is a warehouse and inventory operations app focused on high-volume daily execution on large screens.

## Core Feature Set
- Inventory management (items, SKU, barcode, category, pricing, reorder levels)
- Multi-warehouse stock visibility
- Stock in/out operations and transaction history
- Location-aware stock tracking (warehouse/cell)
- Batch and expiry tracking
- Stock adjustments and approval workflow
- Dashboard analytics (KPIs, movement charts, alerts)
- Reports and exports (CSV/Excel/PDF where configured)
- Auth/settings/sync/update checks

## Main User Roles
- Admin/Owner: full control, approvals, settings
- Operator: inventory updates, stock movements
- Viewer/Manager: dashboard, reports, audits

## Tech Stack
- Flutter (desktop-first UI patterns)
- Provider state management
- SQLite local persistence
- Supporting packages: charts, printing, CSV/Excel, connectivity, updates

## Project Entry
- App entrypoint: `desktop-apps/tracinvent/lib/main.dart`
- Shell screen: `desktop-apps/tracinvent/lib/screens/home_screen.dart`
