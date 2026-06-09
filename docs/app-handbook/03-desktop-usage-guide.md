# Desktop Usage Guide

## Start Application
1. Open terminal in `desktop-apps/tracinvent`
2. Run: `flutter run -d windows`

## Daily Workflows
### Inventory
- Add/edit/delete items
- Search by name, SKU, barcode
- Monitor low/critical stock tags

### Warehouse & Stock
- Select warehouse context
- Perform stock in/out
- Track location-level quantity changes

### Adjustments & Batches
- Create adjustment entry with reason/quantity
- Approve/reject pending adjustments
- Manage batch numbers and expiry views

### Dashboard & Reports
- Review KPI cards and movement chart
- Check stock alerts and recent activity
- Export/report where enabled

## Operational Checks
- Use refresh actions after bulk updates
- Validate barcode/SKU uniqueness for imports
- Confirm approvals are done by authorized users

## Troubleshooting
- Missing assets: verify `assets/icons` and `pubspec.yaml`
- DB issues: check DB path logs and migration version
- Slow UI: refresh provider data and avoid duplicate long-running actions
