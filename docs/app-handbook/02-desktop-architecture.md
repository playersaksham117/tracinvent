# Desktop App Architecture

## Layer Map
- UI Layer: `lib/screens`, `lib/widgets`
- State Layer: `lib/providers`
- Domain/Data Models: `lib/models`
- Service Layer: `lib/services`
- Persistence: SQLite via `DatabaseService` + initializer/migrations

## Runtime Flow
1. App bootstraps providers in `main.dart`.
2. Providers load initial data from services/database.
3. Screens consume providers and trigger actions.
4. Services persist changes and providers refresh state.

## Key Components
- `InventoryProvider`: items/stocks/transactions and stats
- `WarehouseProvider`: warehouse metadata and selection
- `AdjustmentProvider`: stock adjustments and batch actions
- `NavigationProvider`: feature routing in home shell
- `SyncProvider`: connectivity + pending changes/sync workflow

## Database Notes
- Local DB file: `tracinvent.db`
- Tables include items, stocks, transactions, warehouses, cells, users, batch_info, stock_adjustments
- Migration logic is centralized in database service/initializer

## Extension Points
- Add new reports in `screens/reports_*` + provider methods
- Add business validation in service layer before provider updates
- Keep UI responsive by handling long operations asynchronously
