# TracInvent Backend

Python Flask REST API for TracInvent offline-first inventory management system.

## Setup

1. **Create virtual environment:**
   ```bash
   python -m venv venv
   ```

2. **Activate virtual environment:**
   - Windows: `venv\Scripts\activate`
   - Mac/Linux: `source venv/bin/activate`

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Setup environment:**
   ```bash
   copy .env.example .env
   ```

5. **Run server:**
   ```bash
   python app.py
   ```

Server runs on `http://localhost:5000`

## API Endpoints

### Health Check
- `GET /api/health` - Server health status

### Inventory Items
- `GET /api/inventory` - List all items
- `GET /api/inventory?since=<timestamp>` - Changes since timestamp
- `GET /api/inventory/<id>` - Get specific item
- `POST /api/inventory` - Create item
- `PUT /api/inventory/<id>` - Update item
- `DELETE /api/inventory/<id>` - Soft delete item

### Warehouses
- `GET /api/warehouses` - List all warehouses
- `POST /api/warehouses` - Create warehouse
- `PUT /api/warehouses/<id>` - Update warehouse
- `DELETE /api/warehouses/<id>` - Soft delete warehouse

### Stock
- `GET /api/stock` - List all stock
- `POST /api/stock` - Create stock record
- `PUT /api/stock/<id>` - Update stock

### Transactions
- `GET /api/transactions` - List all transactions
- `POST /api/transactions` - Create transaction

### Sync
- `POST /api/sync` - Bulk sync endpoint for offline-first sync

## Architecture

- **Offline-first**: Client maintains local SQLite database
- **Sync mechanism**: Timestamp-based incremental sync
- **Soft deletes**: Records marked as deleted, not physically removed
- **Conflict resolution**: Last-write-wins strategy
