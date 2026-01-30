# BillEase Suite - Project Structure

## Overview
BillEase Suite is organized as a multi-app workspace where each web application is independent and can be developed, deployed, and scaled separately.

---

## Folder Structure

```
BillEase Suite/
├── main-website/              # Marketing/Landing page + Demo selector
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx      # Homepage with app showcase
│   │   │   ├── demo/         # Demo pages for all apps
│   │   │   └── ...
│   │   └── components/       # Shared UI components
│   └── package.json
│
├── spendsight-app/           # Income/Expense Management SaaS
│   ├── src/
│   │   ├── app/
│   │   │   ├── auth/         # Authentication pages
│   │   │   ├── dashboard/    # Main dashboard
│   │   │   ├── onboarding/   # First-time setup
│   │   │   └── ...
│   │   ├── components/
│   │   ├── lib/
│   │   └── types/
│   └── package.json
│
├── pos-app/ (coming soon)    # Point of Sale Web Interface
│   └── ...
│
├── crm-app/ (coming soon)    # Customer Relationship Management
│   └── ...
│
├── accounts-app/ (coming soon) # Accounting System
│   └── ...
│
├── inventory-app/ (coming soon) # Inventory Management
│   └── ...
│
├── desktop-app/              # Desktop applications
│   └── flutter_pos/          # Flutter POS Desktop App
│
├── migrations/               # Database migrations for all apps
│   ├── saas/                 # SpendSight database
│   ├── pos/                  # POS database
│   ├── crm/                  # CRM database
│   ├── accounts/             # Accounts database
│   └── inventory/            # Inventory database
│
└── Documentation files...

```

---

## Current Status

### ✅ Completed Apps

1. **main-website** (Port: 3000)
   - Marketing homepage
   - App showcase with platform badges
   - Demo pages
   - Authentication routing

2. **SpendSight** (Currently in main-website, needs migration)
   - Multi-tenant SaaS
   - Income/Expense tracking
   - Budgeting system
   - Analytics dashboard
   - Status: **Fully functional**

3. **Flutter POS** (Desktop)
   - SQLite-based POS system
   - Receipt printing
   - Cash management
   - Status: **Fully functional**

### 🚧 To Be Created

4. **pos-app** (Web version)
   - Web interface for POS
   - Cloud-based alternative to desktop app

5. **crm-app**
   - Customer management
   - Lead tracking
   - Supplier management

6. **accounts-app**
   - Journal entries
   - Ledger
   - Financial statements

7. **inventory-app**
   - Stock management
   - Serial number tracking
   - Multi-location support

---

## Migration Plan for SpendSight

### Step 1: Copy SpendSight files to new folder
```bash
# Copy the auth, dashboard, onboarding pages
cp -r main-website/src/app/auth spendsight-app/src/app/
cp -r main-website/src/app/dashboard spendsight-app/src/app/
cp -r main-website/src/app/onboarding spendsight-app/src/app/

# Copy components
cp -r main-website/src/components/auth spendsight-app/src/components/
cp -r main-website/src/components/dashboard spendsight-app/src/components/
cp -r main-website/src/components/transactions spendsight-app/src/components/
cp -r main-website/src/components/budgets spendsight-app/src/components/
cp -r main-website/src/components/analytics spendsight-app/src/components/
cp -r main-website/src/components/onboarding spendsight-app/src/components/

# Copy lib
cp -r main-website/src/lib spendsight-app/src/

# Copy types
cp -r main-website/src/types spendsight-app/src/

# Copy middleware
cp main-website/src/middleware.ts spendsight-app/src/
```

### Step 2: Create package.json for SpendSight
```json
{
  "name": "spendsight",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev -p 3002",
    "build": "next build",
    "start": "next start -p 3002"
  }
}
```

### Step 3: Update main-website
- Remove SpendSight-specific pages (auth, dashboard, onboarding)
- Keep only marketing pages and demos
- Update navigation

---

## Development Workflow

### Running Apps

1. **Marketing Site**
```bash
cd main-website
npm run dev  # Runs on http://localhost:3000
```

2. **SpendSight**
```bash
cd spendsight-app
npm run dev  # Runs on http://localhost:3002
```

3. **POS (when created)**
```bash
cd pos-app
npm run dev  # Runs on http://localhost:3003
```

4. **CRM (when created)**
```bash
cd crm-app
npm run dev  # Runs on http://localhost:3004
```

### Running Multiple Apps
```bash
# Use separate terminals or a process manager like concurrently
npm install -g concurrently

# From root folder
concurrently "cd main-website && npm run dev" "cd spendsight-app && npm run dev"
```

---

## Deployment Strategy

### Option 1: Separate Deployments (Recommended)
Each app gets its own deployment:

- **main-website** → https://billeasesuite.com
- **spendsight-app** → https://spendsight.billeasesuite.com
- **pos-app** → https://pos.billeasesuite.com
- **crm-app** → https://crm.billeasesuite.com
- **accounts-app** → https://accounts.billeasesuite.com
- **inventory-app** → https://inventory.billeasesuite.com

### Option 2: Monorepo with Vercel
Use Vercel monorepo support to deploy all apps from one repository.

---

## Database Strategy

### Current Setup
- Each app has its own database/schema in Supabase
- Migrations are in the `migrations/` folder, organized by app

### Schema Naming
- `saas` → SpendSight database
- `pos` → Point of Sale database
- `crm` → CRM database
- `accounts` → Accounting database
- `inventory` → Inventory database

### Shared Tables (Optional)
- Users table (shared authentication)
- Organizations table (multi-tenant support)

---

## Authentication Flow

1. User visits **main-website**
2. Clicks "Get Started" on any app card (e.g., SpendSight)
3. Redirected to `/auth/signup?app=spendsight`
4. After signup/login, redirected to app subdomain or port
5. Single Sign-On (SSO) allows seamless access to all apps

---

## Next Steps

1. ✅ Create folder structure
2. ⏳ Initialize SpendSight as standalone Next.js app
3. ⏳ Move SpendSight files from main-website
4. ⏳ Update main-website to be pure marketing site
5. ⏳ Create POS web app
6. ⏳ Create CRM app
7. ⏳ Create Accounts app
8. ⏳ Create Inventory app
9. ⏳ Implement SSO across all apps
10. ⏳ Set up deployment pipeline

---

## Benefits of This Structure

✅ **Independent Development** - Each team can work on different apps
✅ **Independent Deployment** - Deploy apps separately without affecting others
✅ **Technology Flexibility** - Each app can use different tech if needed
✅ **Easier Scaling** - Scale individual apps based on demand
✅ **Better Organization** - Clear separation of concerns
✅ **Microservices Ready** - Easy to convert to microservices later

---

## Questions?

For implementation help, refer to:
- QUICK_START.md
- SAAS_README.md
- IMPLEMENTATION_SUMMARY.md
