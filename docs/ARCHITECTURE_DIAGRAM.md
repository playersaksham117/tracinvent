# 🏗️ BillEase Suite - Complete Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SUPABASE DATABASE                                │
│                    (Single Source of Truth)                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  📊 Tables: organizations, user_profiles, products, customers,    │  │
│  │             sales, sale_items, stock_movements, transactions,      │  │
│  │             chart_of_accounts, ledger, audit_logs, user_sessions  │  │
│  │                                                                     │  │
│  │  🔐 RLS Policies: organization_id based isolation                 │  │
│  │  ⚡ Triggers: Stock updates, Ledger posting, Audit logging        │  │
│  │  🔄 Automation: Provisions (bad debt, depreciation)               │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                              ↑  ↓                                        │
└─────────────────────────────────────────────────────────────────────────┘
                                 ↑  ↓
        ┌────────────────────────┼──┼────────────────────────┐
        │                        │  │                        │
        ↓                        ↓  ↓                        ↓
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   WEB APP        │  │  NODE.JS BACKEND │  │  DESKTOP APP     │
│   (Next.js)      │  │  (Express API)   │  │  (Flutter)       │
│   Port: 3000     │  │  Port: 3001      │  │                  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
         │                       │                       │
         ↓                       ↓                       ↓
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  OPERATIONS      │  │  REST API        │  │  ACCOUNTING      │
│  FEATURES:       │  │  ENDPOINTS:      │  │  FEATURES:       │
│                  │  │                  │  │                  │
│  • POS           │  │  • Products      │  │  • Chart of      │
│  • Products      │  │  • Sales         │  │    Accounts      │
│  • Stock Mgmt    │  │  • Customers     │  │  • General       │
│  • Sales         │  │  • Suppliers     │  │    Ledger        │
│  • Customers     │  │  • Transactions  │  │  • Journal       │
│  • Suppliers     │  │  • Audit Logs    │  │    Entries       │
│  • ExIn          │  │  • Reports       │  │  • Provisions    │
│  • Reports       │  │                  │  │  • Reconciliation│
│                  │  │  Authentication: │  │  • Reports       │
│  Direct Supabase │  │  JWT Middleware  │  │                  │
│  Client Access   │  │                  │  │  + Python        │
│                  │  │  Automatic:      │  │    Backend       │
│                  │  │  • Stock updates │  │                  │
│                  │  │  • Ledger posts  │  │  Direct Supabase │
│                  │  │  • Audit logs    │  │  Admin Access    │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 🔄 Data Flow Examples

### Example 1: Creating a Sale (Web App)

```
1. USER (Sales Staff)
   ↓
   Makes sale on POS (web-app)
   ↓
2. WEB APP
   ↓
   Sends sale data to Supabase
   ↓
3. SUPABASE DATABASE
   ↓
   Inserts into 'sales' table
   ↓
4. TRIGGER: update_product_stock_on_sale()
   ↓
   Reduces product stock automatically
   ↓
5. TRIGGER: post_sale_to_ledger()
   ↓
   Creates accounting entries:
   • Debit: Cash/Bank (Asset ↑)
   • Credit: Sales Revenue (Income ↑)
   • Debit: Cost of Goods Sold (Expense ↑)
   • Credit: Inventory (Asset ↓)
   ↓
6. TRIGGER: log_audit_trail()
   ↓
   Records in audit_logs table
   ↓
7. RESULT
   ↓
   • Sale recorded ✅
   • Stock updated ✅
   • Accounting entries created ✅
   • Audit log saved ✅
   ↓
8. DESKTOP APP (Accountant)
   ↓
   Sees ledger entries automatically
   No manual posting needed!
```

### Example 2: Using Node.js Backend API

```
1. CLIENT (Web App / Mobile App / Third Party)
   ↓
   GET /api/products (with JWT token)
   ↓
2. NODE.JS BACKEND
   ↓
   auth.js middleware validates JWT
   ↓
   Extracts user_id from token
   ↓
   Gets organization_id from user_profile
   ↓
3. SUPABASE DATABASE
   ↓
   RLS policy filters: WHERE organization_id = user's org
   ↓
   Returns only organization's products
   ↓
4. NODE.JS BACKEND
   ↓
   Returns JSON response
   ↓
5. CLIENT
   ↓
   Receives data (only from their organization)
```

### Example 3: Monthly Provisions (Automatic)

```
1. CRON JOB (Monthly - 1st day at midnight)
   ↓
   Triggers run_all_provisions()
   ↓
2. FUNCTION: create_automatic_provisions()
   ↓
   Calculates:
   • Bad Debt Provision (5% of receivables)
   • Depreciation Provision (10% annual / 12)
   ↓
3. SUPABASE DATABASE
   ↓
   Creates journal entries automatically:
   
   Bad Debt:
   • Debit: Bad Debt Expense (5150)
   • Credit: Provision for Bad Debts (1210)
   
   Depreciation:
   • Debit: Depreciation Expense (5250)
   • Credit: Accumulated Depreciation (1510)
   ↓
4. DESKTOP APP (Accountant)
   ↓
   Reviews provision entries
   Can manually adjust if needed
```

---

## 🔐 Security Layers

```
┌─────────────────────────────────────────────────────────┐
│ LAYER 1: Supabase Authentication                        │
│ • JWT tokens for all users                              │
│ • Email/password, OAuth, magic links                    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ LAYER 2: Row Level Security (RLS)                       │
│ • organization_id based isolation                       │
│ • Users see only their organization's data              │
│ • Enforced at database level                            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ LAYER 3: API Authentication (Node.js)                   │
│ • JWT middleware validates tokens                       │
│ • Extracts user info from token                         │
│ • Attaches to request object                            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ LAYER 4: Application Logic                              │
│ • Additional validation                                 │
│ • Business rules enforcement                            │
│ • Custom authorization                                  │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ LAYER 5: Audit Logging                                  │
│ • Every action tracked                                  │
│ • User, timestamp, operation recorded                   │
│ • Old/new data snapshots                                │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Database Automation

### Automatic Processes (No Manual Work Required)

```
┌───────────────────────────────────────────────────────────┐
│                   SALE CREATED                             │
└───────────────────────────────────────────────────────────┘
                          ↓
    ┌─────────────────────┼─────────────────────┐
    ↓                     ↓                     ↓
┌─────────┐         ┌──────────┐         ┌──────────┐
│ STOCK   │         │ LEDGER   │         │ AUDIT    │
│ UPDATE  │         │ POSTING  │         │ LOG      │
│         │         │          │         │          │
│ Reduce  │         │ Create   │         │ Record   │
│ quantity│         │ Dr/Cr    │         │ action   │
│ by sale │         │ entries  │         │ details  │
│ qty     │         │          │         │          │
└─────────┘         └──────────┘         └──────────┘

All happens automatically via PostgreSQL triggers!
```

---

## 🎭 User Roles & Access

### Web App Users (Operations Team)
```
┌──────────────────────────────────────┐
│  Sales Staff / Store Managers         │
├──────────────────────────────────────┤
│  CAN:                                 │
│  ✅ Create sales (POS)                │
│  ✅ View products                     │
│  ✅ Manage inventory                  │
│  ✅ View customers                    │
│  ✅ Track expenses (ExIn)             │
│  ✅ View reports                      │
│                                       │
│  CANNOT:                              │
│  ❌ Access accounting (Chart of Accts)│
│  ❌ View ledger entries               │
│  ❌ Create journal entries            │
│  ❌ Run provisions                    │
└──────────────────────────────────────┘
```

### Desktop App Users (Accounting Team)
```
┌──────────────────────────────────────┐
│  Accountants / Finance Team           │
├──────────────────────────────────────┤
│  CAN:                                 │
│  ✅ View chart of accounts            │
│  ✅ Review ledger entries             │
│  ✅ Create journal entries            │
│  ✅ Run provisions                    │
│  ✅ Reconcile accounts                │
│  ✅ Generate financial reports        │
│                                       │
│  CANNOT:                              │
│  ❌ Make sales (no POS access)        │
│  ❌ Manage inventory                  │
│  ❌ Direct customer management        │
│                                       │
│  AUTO-RECEIVES:                       │
│  ⚡ Sales ledger entries (auto)       │
│  ⚡ Stock movement impacts (auto)     │
│  ⚡ Provision entries (monthly auto)  │
└──────────────────────────────────────┘
```

---

## 🔧 Technology Stack

```
┌─────────────────────────────────────────────────────────┐
│                     FRONTEND                             │
├─────────────────────────────────────────────────────────┤
│  • Next.js 14 (React) - Web App                         │
│  • Flutter - Desktop App                                │
│  • Tailwind CSS - Styling                               │
│  • React Query - State Management                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     BACKEND                              │
├─────────────────────────────────────────────────────────┤
│  • Node.js + Express - REST API                         │
│  • Python + FastAPI - Desktop Backend                   │
│  • Supabase Auth - Authentication                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     DATABASE                             │
├─────────────────────────────────────────────────────────┤
│  • PostgreSQL (via Supabase)                            │
│  • Row Level Security (RLS)                             │
│  • Triggers & Functions                                 │
│  • JSONB for audit data                                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE                          │
├─────────────────────────────────────────────────────────┤
│  • Supabase Cloud - Database + Auth                     │
│  • Vercel/Hostinger - Web App Hosting                   │
│  • Local - Desktop App                                  │
└─────────────────────────────────────────────────────────┘
```

---

## 📈 Scalability & Performance

### Multi-Tenancy Architecture
```
One Database, Multiple Organizations:

Organization A (Retail Store)
├── 500 products
├── 1,000 customers
├── 5,000 sales/month
└── 3 users

Organization B (Wholesale)
├── 200 products
├── 50 customers
├── 1,000 sales/month
└── 2 users

Organization C (Restaurant)
├── 150 menu items
├── 5,000 customers
├── 10,000 orders/month
└── 8 users

All isolated by organization_id!
RLS ensures data never crosses between orgs.
```

### Performance Optimizations
- ✅ Database indexes on organization_id
- ✅ RLS policies for fast filtering
- ✅ Automatic query optimization
- ✅ Connection pooling
- ✅ Caching strategies

---

## 🚀 Deployment Architecture

```
PRODUCTION SETUP:

┌─────────────────────────────────────────────┐
│  USERS (Browsers / Desktop Apps)             │
└─────────────────────────────────────────────┘
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
┌──────────────┐        ┌──────────────┐
│  WEB APP     │        │ DESKTOP APP  │
│  (Vercel)    │        │ (Local PC)   │
│  Next.js     │        │ Flutter      │
└──────────────┘        └──────────────┘
        ↓                       ↓
        └───────────┬───────────┘
                    ↓
        ┌───────────────────────┐
        │  NODE.JS BACKEND      │
        │  (VPS / Cloud Server) │
        │  Express API          │
        └───────────────────────┘
                    ↓
        ┌───────────────────────┐
        │  SUPABASE CLOUD       │
        │  (Database + Auth)    │
        │  PostgreSQL           │
        └───────────────────────┘
```

---

**Architecture Date**: December 30, 2025  
**Version**: 1.0  
**Status**: Production Ready (after DB setup)
