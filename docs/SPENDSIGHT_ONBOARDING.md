# SpendSight Onboarding Enhancement - Implementation Summary

## Overview
Enhanced onboarding flow with account type selection that controls features, budget logic, and dashboard layout.

---

## Database Schema Changes

### Updated `organizations` Table

```sql
CREATE TABLE organizations (
    -- Existing fields
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    
    -- NEW: Account Type Configuration
    account_type VARCHAR(20) NOT NULL DEFAULT 'individual' 
        CHECK (account_type IN ('individual', 'family', 'business')),
    
    -- NEW: Enhanced Financial Configuration
    currency VARCHAR(3) DEFAULT 'INR',
    default_currency VARCHAR(3) DEFAULT 'INR',
    fiscal_year_start INTEGER DEFAULT 4,
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    country VARCHAR(2) DEFAULT 'IN', -- ISO 3166-1 alpha-2
    
    -- NEW: Business-specific Fields
    business_name VARCHAR(255),
    tax_id VARCHAR(100), -- GST/VAT/Tax ID
    tax_system VARCHAR(50), -- 'gst', 'vat', 'sales_tax'
    company_registration VARCHAR(100),
    
    -- NEW: Feature Flags (JSONB)
    features JSONB DEFAULT '{
        "gst_enabled": false,
        "multi_user": false,
        "advanced_reports": false,
        "api_access": false,
        "team_management": false,
        "expense_approval": false,
        "budget_alerts": true,
        "recurring_transactions": true
    }'::jsonb,
    
    -- Other fields...
    settings JSONB DEFAULT '{}',
    subscription_plan VARCHAR(50) DEFAULT 'free',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## Account Type Configurations

### 1. Individual Account
**Purpose:** Personal finance management

**Features:**
- ✅ Budget alerts
- ✅ Recurring transactions
- ✅ Advanced reports
- ❌ Multi-user
- ❌ GST/Tax features
- ❌ Team management
- ❌ API access

**Use Cases:**
- Personal expense tracking
- Individual budgeting
- Single-user scenarios

---

### 2. Family Account
**Purpose:** Household finance management

**Features:**
- ✅ Budget alerts
- ✅ Recurring transactions
- ✅ Advanced reports
- ✅ Multi-user (family members)
- ✅ Team management (family roles)
- ✅ Expense approval (parent approval for kids)
- ❌ GST/Tax features
- ❌ API access

**Use Cases:**
- Family budget management
- Shared household expenses
- Teaching kids about money
- Multi-member tracking

---

### 3. Business Account
**Purpose:** SME finance & accounting

**Features:**
- ✅ ALL features enabled
- ✅ GST/Tax integration
- ✅ Multi-user (employees)
- ✅ Advanced reports
- ✅ API access
- ✅ Team management (roles & permissions)
- ✅ Expense approval workflows
- ✅ Budget alerts
- ✅ Recurring transactions

**Additional Fields:**
- Business Name (legal name)
- Tax ID / GST Number
- Tax System (GST for India, VAT for others)
- Company Registration Number

**Use Cases:**
- Small business accounting
- GST invoicing & filing
- Multi-branch operations
- Employee expense management

---

## Onboarding Flow (2 Steps)

### Step 1: Account Setup

**Fields Collected:**

1. **Account Type Selection** (Required)
   - Visual cards with icons
   - Individual / Family / Business
   - Shows feature highlights

2. **Organization Name** (Required)
   - Changes placeholder based on account type
   - Individual: "My Personal Finances"
   - Family: "The Smiths"
   - Business: "Acme Inc."

3. **Business-Specific Fields** (Conditional - Only for Business)
   - Legal Business Name (Optional)
   - Tax ID / GST Number (Optional)

4. **Country Selection** (Required)
   - Dropdown with 6+ countries
   - Auto-sets currency, timezone, fiscal year start
   - Supported: India, US, UK, Australia, Canada, Singapore

5. **Currency** (Auto-filled based on country)
   - Read-only, set by country selection
   - INR, USD, GBP, AUD, CAD, SGD

6. **Fiscal Year Start** (Auto-filled, editable)
   - Month selection dropdown
   - Defaults based on country:
     - India: April
     - US/Canada: January
     - UK: April
     - Australia: July
   - Shows contextual help text

### Step 2: Initial Setup

**Options:**

1. **Create Sample Data** (Checkbox)
   - Default: ON
   - Creates:
     - 1 cash account (₹10,000 balance)
     - Default income/expense categories
     - 2 sample transactions

2. **What Happens Next** (Info section)
   - Organization creation
   - User role assignment (owner)
   - Team invitation option

**Actions:**
- Back button (returns to Step 1)
- Create Organization button (submits)

---

## Feature Control Logic

### How Features Control Behavior

```typescript
// Check if feature is enabled
const hasGST = organization.features.gst_enabled
const canAddUsers = organization.features.multi_user
const hasAPI = organization.features.api_access

// Conditional rendering
{hasGST && <GSTSection />}
{canAddUsers && <InviteTeamButton />}
```

### Budget Logic by Account Type

**Individual:**
- Single budget owner
- Personal categories only
- No approval workflow

**Family:**
- Shared budgets with multiple members
- Approval workflow for kids
- Family expense categories

**Business:**
- Department-wise budgets
- Multi-level approvals
- Cost center tracking
- GST-inclusive amounts

### Dashboard Layout by Account Type

**Individual:**
- Personal expense chart
- Monthly budget progress
- Savings goal tracker

**Family:**
- Family expense breakdown
- Member-wise spending
- Allowance tracking

**Business:**
- Revenue vs. Expense
- GST summary
- Department-wise breakdown
- Team expense reports

---

## Country & Tax System Mapping

| Country | Currency | Tax System | Fiscal Year Default |
|---------|----------|------------|---------------------|
| India (IN) | INR | GST | April - March |
| United States (US) | USD | Sales Tax | January - December |
| United Kingdom (GB) | GBP | VAT | April - March |
| Australia (AU) | AUD | GST | July - June |
| Canada (CA) | CAD | GST/HST | January - December |
| Singapore (SG) | SGD | GST | January - December |

### Future Tax Compatibility

The schema is designed to support:
- Multiple tax rates per country
- Tax exemptions
- Inter-state tax rules (India GST)
- Provincial taxes (Canada)
- Tax filing periods
- Tax compliance reports

**Tax System Field Values:**
- `gst` - Goods & Services Tax (India, Australia, Singapore, Canada)
- `vat` - Value Added Tax (UK, EU)
- `sales_tax` - US State Sales Tax
- `other` - Custom tax systems

---

## Migration Required

### If you have existing data:

```sql
-- Add new columns with defaults
ALTER TABLE organizations 
ADD COLUMN account_type VARCHAR(20) DEFAULT 'individual',
ADD COLUMN default_currency VARCHAR(3) DEFAULT 'INR',
ADD COLUMN business_name VARCHAR(255),
ADD COLUMN tax_id VARCHAR(100),
ADD COLUMN tax_system VARCHAR(50),
ADD COLUMN company_registration VARCHAR(100),
ADD COLUMN features JSONB DEFAULT '{
    "gst_enabled": false,
    "multi_user": false,
    "advanced_reports": false,
    "api_access": false,
    "team_management": false,
    "expense_approval": false,
    "budget_alerts": true,
    "recurring_transactions": true
}'::jsonb;

-- Add constraint
ALTER TABLE organizations 
ADD CONSTRAINT check_account_type 
CHECK (account_type IN ('individual', 'family', 'business'));
```

---

## Files Modified

1. **migrations/saas/001_multi_tenant_schema.sql**
   - Extended `organizations` table
   - Added account_type, features, business fields

2. **main-website/src/components/onboarding/onboarding-form.tsx**
   - Added account type selection UI
   - Added country/currency/fiscal year selection
   - Added business-specific fields
   - Enhanced validation and UX

---

## Testing Checklist

- [ ] Create individual account
- [ ] Create family account
- [ ] Create business account with GST
- [ ] Verify country selection updates currency/timezone
- [ ] Verify fiscal year dropdown
- [ ] Test sample data creation
- [ ] Verify features are set correctly per account type
- [ ] Check business name and tax ID are saved
- [ ] Verify onboarding_completed flag is set

---

## Next Steps

1. **Dashboard Customization**
   - Create different dashboard layouts per account type
   - Show/hide features based on account_type

2. **GST Module** (Business accounts only)
   - GST-inclusive pricing
   - CGST/SGST/IGST breakdown
   - GST report generation

3. **Team Management** (Family & Business)
   - Invite members
   - Assign roles
   - Expense approval workflow

4. **Budget Logic Enhancement**
   - Individual: Personal budgets
   - Family: Shared budgets with member allocation
   - Business: Department/cost center budgets

5. **API Access** (Business accounts)
   - Generate API keys
   - API documentation
   - Rate limiting

---

## Benefits

✅ **Personalized Experience** - Users get features relevant to their use case
✅ **Scalability** - Easy to add new account types or features
✅ **Global Ready** - Multi-country, multi-currency support
✅ **Tax Compliant** - Built-in support for various tax systems
✅ **Future-proof** - JSONB features allow easy feature flag updates
✅ **Better Onboarding** - Users understand what they're getting upfront

---

## Questions?

For implementation help:
- Database: migrations/saas/001_multi_tenant_schema.sql
- UI: main-website/src/components/onboarding/onboarding-form.tsx
- Docs: QUICK_START.md, SAAS_README.md
