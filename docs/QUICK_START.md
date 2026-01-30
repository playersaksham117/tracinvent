# 🚀 Quick Start Guide - BillEase SaaS

This guide will get your BillEase SaaS application up and running in under 10 minutes.

## 📋 Prerequisites Checklist

- [ ] Node.js 18+ installed
- [ ] npm or yarn installed
- [ ] Git installed
- [ ] Supabase account (free tier works)
- [ ] Code editor (VS Code recommended)

## Step 1: Set Up Supabase Project (5 minutes)

### 1.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Fill in:
   - **Project name**: `billease-saas` (or your choice)
   - **Database password**: Generate a strong password and save it
   - **Region**: Choose closest to you (e.g., `ap-south-1` for India)
4. Click "Create new project"
5. Wait 2-3 minutes for project setup

### 1.2 Get Your Supabase Credentials

Once your project is ready:

1. Go to **Settings** > **API**
2. Copy these values:
   ```
   Project URL: https://xxxxx.supabase.co
   anon public key: eyJhbGc...
   service_role key: eyJhbGc... (keep this secret!)
   ```

### 1.3 Run Database Migration

1. In your Supabase project, go to **SQL Editor**
2. Click "New Query"
3. Open `migrations/saas/001_multi_tenant_schema.sql` from your project
4. Copy the entire contents and paste into the SQL Editor
5. Click "Run" (bottom right)
6. You should see "Success. No rows returned" - this is expected!

**Verify Migration:**
- Go to **Table Editor** in Supabase
- You should see these tables:
  - organizations
  - user_profiles
  - organization_members
  - categories
  - accounts
  - transactions
  - budgets
  - budget_categories
  - and more...

### 1.4 Configure Authentication (Optional but Recommended)

**Enable Email Authentication:**
1. Go to **Authentication** > **Providers**
2. Email is enabled by default
3. Configure email templates if desired

**Enable Google OAuth (Optional):**
1. Go to **Authentication** > **Providers**
2. Click on **Google**
3. Toggle "Enable Google Provider"
4. Add your Google OAuth credentials:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create new project or select existing
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized redirect URI: `https://xxxxx.supabase.co/auth/v1/callback`
   - Copy Client ID and Client Secret to Supabase
5. Click "Save"

## Step 2: Set Up Your Local Environment (2 minutes)

### 2.1 Navigate to Project

```bash
cd "e:\Vyoumix\BillEase Suite\main-website"
```

### 2.2 Install Dependencies

```bash
npm install
```

This will install all required packages including:
- Next.js 14
- React 18
- Supabase client
- Tailwind CSS
- TypeScript
- And all other dependencies

### 2.3 Create Environment File

```bash
# Copy the example file
cp .env.example .env.local
```

### 2.4 Configure Environment Variables

Open `.env.local` and update with your Supabase credentials:

```env
# Supabase (REQUIRED - from Step 1.2)
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...

# App Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_APP_NAME="BillEase Suite"

# India-First Defaults
NEXT_PUBLIC_DEFAULT_CURRENCY=INR
NEXT_PUBLIC_DEFAULT_TIMEZONE=Asia/Kolkata
NEXT_PUBLIC_DEFAULT_COUNTRY=IN

# Development
NODE_ENV=development
```

## Step 3: Run the Application (30 seconds)

### 3.1 Start Development Server

```bash
npm run dev
```

You should see:
```
✓ Ready in 2.5s
○ Local: http://localhost:3000
```

### 3.2 Open Your Browser

Navigate to: [http://localhost:3000](http://localhost:3000)

## Step 4: Create Your First Account (2 minutes)

### 4.1 Sign Up

1. Click "Sign up" or go to [http://localhost:3000/auth/signup](http://localhost:3000/auth/signup)
2. Fill in the form:
   - **Full Name**: John Doe
   - **Email**: your@email.com
   - **Password**: minimum 8 characters
   - **Confirm Password**: same as above
3. Click "Create Account"
4. Check your email for verification (optional, depends on Supabase settings)

### 4.2 Complete Onboarding

After signing up, you'll be redirected to the onboarding page:

**Step 1: Organization Details**
- **Organization Name**: "My Business" or "Personal Finance"
- **Organization Type**: Choose Individual, Family, or Business
- **Currency**: INR (or your preference)
- **Fiscal Year Start**: April (for India) or January
- Click "Continue"

**Step 2: Initial Setup**
- ✅ Keep "Create sample data" checked (recommended for testing)
- Click "Create Organization"

### 4.3 Explore Your Dashboard

You'll now see your dashboard with:
- Total Balance
- Income This Month
- Expenses This Month
- Active Budgets
- Recent Transactions
- Expense Breakdown Chart

## Step 5: Test Key Features (3 minutes)

### 5.1 View Transactions

1. Click "Transactions" in the left sidebar
2. You'll see sample transactions (if you enabled sample data)
3. Click "+ New Transaction" to create one:
   - Toggle between Income/Expense
   - Enter amount: 1000
   - Select category
   - Select account
   - Add description
   - Click "Create Transaction"

### 5.2 Create a Budget

1. Click "Budgets" in the left sidebar
2. Click "+ New Budget"
3. Fill in:
   - **Budget Name**: "Monthly Expenses"
   - **Period Type**: Monthly
   - **Total Budget**: 50000
   - **Alert Threshold**: 80%
4. Optionally allocate to categories
5. Click "Create Budget"

### 5.3 View Analytics

1. Click "Analytics" in the left sidebar
2. See:
   - Income vs Expense stats
   - Category breakdowns
   - Month-over-month comparisons
   - Visual charts

## 🎉 You're Done!

Your BillEase SaaS application is now fully set up and running!

## 🔧 Troubleshooting

### Issue: "Supabase client error"
**Solution:** Double-check your environment variables in `.env.local`

### Issue: "No rows in database"
**Solution:** Re-run the migration SQL in Supabase SQL Editor

### Issue: "Authentication failed"
**Solution:** 
1. Check Supabase Auth is enabled
2. Verify redirect URLs are correct
3. Clear browser cache and cookies

### Issue: "Port 3000 already in use"
**Solution:** 
```bash
# Kill the process using port 3000
# Windows:
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Mac/Linux:
lsof -ti:3000 | xargs kill
```

### Issue: "Module not found"
**Solution:** 
```bash
# Delete node_modules and reinstall
rm -rf node_modules
npm install
```

## 📚 Next Steps

Now that you're set up, explore:

1. **Create More Organizations**: Test multi-tenancy by creating multiple orgs
2. **Invite Team Members**: Add users with different roles
3. **Customize Categories**: Add your own income/expense categories
4. **Set Up Accounts**: Add your bank accounts, wallets, etc.
5. **Create Recurring Transactions**: Set up monthly bills
6. **Generate Reports**: Use analytics for insights

## 🚀 Deploy to Production

Ready to deploy? See [DEPLOYMENT.md](./DEPLOYMENT.md) for:
- Vercel deployment
- Environment setup
- Domain configuration
- SSL/HTTPS setup
- Performance optimization

## 📖 Full Documentation

For detailed documentation, see:
- [SAAS_README.md](../SAAS_README.md) - Complete feature guide
- [ARCHITECTURE_DIAGRAM.md](../ARCHITECTURE_DIAGRAM.md) - System architecture
- [DATABASE_SCHEMAS.md](../DATABASE_SCHEMAS.md) - Database structure

## 🆘 Need Help?

- **Documentation**: Check SAAS_README.md
- **Issues**: Create an issue on GitHub
- **Email**: support@billease.com
- **Community**: Join our Discord/Slack

---

**Congratulations on setting up BillEase SaaS! 🎊**

Start managing your finances like a pro! 💰
