# BillEase Suite

A comprehensive SaaS business management platform with POS, CRM, Accounts, and Inventory management modules.

## Project Structure

```
BillEase Suite/
├── main-website/          # Active Next.js 14 web application (PRIMARY)
├── migrations/            # PostgreSQL database migration files
├── desktop-app/          # Flutter desktop app (TO BE REMOVED - locked)
└── Documentation files
```

## Active Project: main-website

The `main-website` directory contains the primary Next.js 14 application with:

### Features
- ✅ Premium UI/UX with animations and gradients
- ✅ Authentication system (demo: demo1/demo123)
- ✅ Homepage with feature showcase
- ✅ Products overview and individual pages
- ✅ User dashboard
- ✅ Responsive design

### Tech Stack
- **Frontend**: Next.js 14.2.35, React 18, TypeScript 5.4.5
- **Styling**: Tailwind CSS 3.4.3, shadcn/ui components
- **Database**: SQLite (better-sqlite3) - Local testing
- **Authentication**: Demo account system (demo1/demo123)

### Working Apps
- ✅ **POS System** - `/apps/pos` - Full point of sale with cart
- ✅ **CRM** - `/apps/crm` - Customer management
- ✅ **Accounting** - `/apps/accounts` - Financial overview
- ✅ **Inventory** - `/apps/inventory` - Stock management

### Database
SQLite database is automatically created at `main-website/data/billease.db` on first run with demo data:
- 4 demo products (Laptop, iPhone, Chair, Mouse)
- 3 demo customers
- Demo user account (demo1/demo123)

## Getting Started

1. Navigate to the main website:
   ```bash
   cd main-website
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000](http://localhost:3000)

5. Test with demo credentials:
   - Username: `demo1`
   - Password: `demo123`

## Database Setup

Migration files are located in the `migrations/` directory:
- `01_main_database.sql` - Core tables (users, subscriptions, products)
- `02_pos_database.sql` - Point of Sale module
- `03_crm_database.sql` - Customer Relationship Management
- `04_accounts_database.sql` - Accounting module
- `05_inventory_database.sql` - Inventory management

## Cleanup Completed

**Removed directories:**
- ❌ `web-app/` - Old duplicate Next.js project
- ❌ `backend-nodejs/` - Unused separate backend
- ❌ `pos-app/` - Unused Flutter POS app
- ❌ `crm-app/` - Unused Flutter CRM app
- ❌ `accounts-app/` - Unused Flutter accounts app
- ❌ `tracinvent-app/` - Unused inventory app
- ❌ `POS58Setup_20180313.exe` - Old installer

**Removed documentation:**
- Various outdated .md files (IMPLEMENTATION_*, MODULE_*, QUICK_START_*, etc.)

**Kept documentation:**
- `ARCHITECTURE_DIAGRAM.md`
- `DATABASE_SCHEMAS.md`
- `DOCUMENTATION_INDEX.md`
- `FEATURES_LIST.md`
- `SUPABASE_CONFIGURATION.md`
- `SUPABASE_SETUP_GUIDE.md`

## Desktop App Directory

The `desktop-app/` directory has been **excluded from the workspace** to prevent 1000+ Flutter errors from showing in the Problems tab. The directory is hidden from VS Code via `.vscode/settings.json`.

**To fully remove it** (when file locks are released):
1. Close all applications and VS Code
2. Run:
   ```powershell
   cd "e:\Vyoumix\BillEase Suite"
   Remove-Item -Recurse -Force desktop-app
   ```

**Current Status**: Excluded from analysis, errors hidden ✓

## Next Steps

1. **Test the application** - Use demo1/demo123 to explore
2. **Create pricing page** - Add subscription tiers
3. **Build admin panel** - User management interface
4. **Deploy databases** - Run migration files
5. **Configure Supabase** - Set up real authentication

## Available Pages

- `/` - Homepage with feature showcase
- `/products` - All products overview (marketing)
- `/products/pos` - POS marketing page
- `/products/crm` - CRM marketing page
- `/products/accounts` - Accounting marketing page
- `/products/inventory` - Inventory marketing page
- `/login` - User authentication
- `/signup` - New user registration
- `/dashboard` - User dashboard (after login)

### Working Applications (After Login)
- `/apps/pos` - **Point of Sale System** (Fully functional)
- `/apps/crm` - **Customer Management** (Fully functional)
- `/apps/accounts` - **Accounting Dashboard** (Overview)
- `/apps/inventory` - **Inventory Dashboard** (Overview)

## Support

For questions or issues, refer to the documentation files in the root directory.
