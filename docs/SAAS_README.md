# BillEase Suite - SaaS Web App

A production-grade, multi-tenant SaaS application for managing Income, Expense, Budgeting, and Analytics for Individuals, Families, and Small–Medium Businesses. Built with Next.js 14 and Supabase.

## 🚀 Features

### Multi-Tenant Architecture
- **Organization-based isolation**: Complete data separation between organizations
- **Role-based access control**: Owner, Admin, Member, and Viewer roles
- **Row Level Security (RLS)**: Database-level security policies
- **Organization switcher**: Seamlessly switch between multiple organizations

### Core Modules

#### 💰 Income & Expense Tracking
- Record income and expense transactions
- Category-based classification
- Multiple account support (bank, cash, credit card, wallet, etc.)
- Payment method tracking
- Attachments and notes
- Advanced filtering and search

#### 🎯 Budgeting System
- Create period-based budgets (monthly, quarterly, yearly, custom)
- Category-wise budget allocation
- Real-time spending tracking
- Budget alerts and notifications
- Progress visualization
- Over-budget warnings

#### 📊 Analytics & Reports
- Income vs Expense trends
- Category-wise breakdowns
- Savings rate calculation
- Cash flow analysis
- Comparative analysis (month-over-month)
- Visual charts and graphs

#### 🏦 Account Management
- Multiple account types
- Real-time balance tracking
- Auto-updating balances based on transactions
- Account categorization

#### 📁 Category Management
- Custom income/expense categories
- Color-coded organization
- Hierarchical structure support
- System and custom categories

## 🛠 Tech Stack

- **Frontend**: Next.js 14 (App Router), React 18, TypeScript
- **Backend**: Supabase (PostgreSQL + Auth + RLS)
- **Styling**: Tailwind CSS, shadcn/ui components
- **Authentication**: Supabase Auth (Email/Password, Google OAuth)
- **Database**: PostgreSQL with Row Level Security
- **Deployment**: Vercel (recommended)

## 📁 Project Structure

```
main-website/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── auth/              # Authentication pages
│   │   │   ├── signin/        # Sign in page
│   │   │   ├── signup/        # Sign up page
│   │   │   └── callback/      # OAuth callback
│   │   ├── dashboard/         # Protected dashboard
│   │   │   ├── layout.tsx     # Dashboard layout with nav
│   │   │   ├── page.tsx       # Dashboard home
│   │   │   ├── transactions/  # Transaction management
│   │   │   ├── income/        # Income tracking
│   │   │   ├── expenses/      # Expense tracking
│   │   │   ├── budgets/       # Budget management
│   │   │   ├── accounts/      # Account management
│   │   │   ├── categories/    # Category management
│   │   │   ├── analytics/     # Analytics & reports
│   │   │   └── settings/      # Settings
│   │   └── api/               # API routes
│   ├── components/            # React components
│   │   ├── auth/             # Auth forms
│   │   ├── dashboard/        # Dashboard components
│   │   ├── transactions/     # Transaction components
│   │   ├── budgets/          # Budget components
│   │   ├── analytics/        # Analytics components
│   │   └── ui/               # Reusable UI components
│   ├── lib/                   # Utilities & helpers
│   │   ├── supabase/         # Supabase clients
│   │   ├── auth/             # Auth helpers
│   │   ├── organization/     # Organization helpers
│   │   └── utils.ts          # Utility functions
│   └── types/                 # TypeScript types
│       └── database.types.ts  # Database types
└── migrations/                # Database migrations
    └── saas/
        └── 001_multi_tenant_schema.sql
```

## 🗄 Database Schema

### Core Tables
- **organizations**: Multi-tenant organizations
- **user_profiles**: Extended user information
- **organization_members**: User-organization mapping with roles
- **categories**: Income/expense categories
- **accounts**: Bank accounts, wallets, etc.
- **transactions**: Income and expense records
- **budgets**: Budget definitions
- **budget_categories**: Category-wise budget allocations
- **recurring_templates**: Recurring transaction templates
- **analytics_cache**: Pre-computed analytics
- **activity_logs**: Audit trail

### Row Level Security (RLS)
All tables have comprehensive RLS policies ensuring:
- Users can only access data from their organizations
- Role-based permissions (owner, admin, member, viewer)
- Data isolation at the database level

## 🚦 Getting Started

### Prerequisites
- Node.js 18+ and npm/yarn
- Supabase account
- Git

### 1. Clone & Install

```bash
cd main-website
npm install
```

### 2. Set Up Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the database migration:
   - Go to Supabase SQL Editor
   - Copy and execute `migrations/saas/001_multi_tenant_schema.sql`

### 3. Environment Configuration

Copy `.env.example` to `.env.local`:

```bash
cp .env.example .env.local
```

Update with your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_DEFAULT_CURRENCY=INR
NEXT_PUBLIC_DEFAULT_TIMEZONE=Asia/Kolkata
```

### 4. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## 🔐 Authentication

### Email/Password
- Sign up with email and password
- Email verification (optional)
- Password reset flow

### OAuth (Google)
Configure Google OAuth in Supabase:
1. Go to Authentication > Providers
2. Enable Google provider
3. Add OAuth credentials
4. Set redirect URL: `http://localhost:3000/auth/callback`

## 👥 User Roles & Permissions

### Owner
- Full access to organization
- Can delete organization
- Manage all members
- All admin permissions

### Admin
- Manage members
- Create/edit/delete all data
- Access all modules
- View analytics

### Member
- Create/edit own transactions
- View all organization data
- Create budgets
- Limited deletion rights

### Viewer
- Read-only access
- View dashboards and reports
- No create/edit/delete permissions

## 📊 Key Features

### Dashboard
- Real-time financial overview
- Total balance across accounts
- Monthly income and expenses
- Active budget tracking
- Recent transactions
- Expense breakdown charts

### Transactions
- Quick transaction entry
- Income/Expense toggle
- Category and account assignment
- Payment method tracking
- Bulk actions
- Export functionality

### Budgets
- Flexible period selection
- Category-wise allocation
- Real-time progress tracking
- Alert thresholds
- Visual progress bars
- Over-budget warnings

### Analytics
- Income vs Expense trends
- Category breakdowns
- Month-over-month comparisons
- Savings rate calculations
- Customizable date ranges
- Visual charts and graphs

## 🌍 Localization

### Default Settings (India-First)
- Currency: INR (Indian Rupee)
- Timezone: Asia/Kolkata
- Fiscal Year: April 1st
- Date Format: DD/MM/YYYY
- Number Format: Indian numbering system

### Global Ready
- Multi-currency support (add via settings)
- Timezone configuration
- Customizable fiscal year
- Locale-based formatting

## 🔧 Configuration

### Environment Variables

```env
# Required
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# App Configuration
NEXT_PUBLIC_APP_URL=
NEXT_PUBLIC_APP_NAME=
NEXT_PUBLIC_DEFAULT_CURRENCY=
NEXT_PUBLIC_DEFAULT_TIMEZONE=

# Features (Optional)
NEXT_PUBLIC_ENABLE_ANALYTICS=true
NEXT_PUBLIC_ENABLE_BUDGETS=true
NEXT_PUBLIC_ENABLE_RECURRING=true

# Stripe (Optional - for subscriptions)
STRIPE_PUBLIC_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

## 🚀 Deployment

### Vercel (Recommended)

1. Push code to GitHub
2. Import project in Vercel
3. Add environment variables
4. Deploy

```bash
npm run build
npm run start
```

### Environment Variables
- Add all `.env.local` variables to Vercel
- Set `NODE_ENV=production`

## 🧪 Testing

```bash
# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

## 📈 Performance Optimization

- **Server Components**: Efficient data fetching
- **Analytics Caching**: Pre-computed metrics
- **Database Indexes**: Optimized queries
- **RLS Policies**: Database-level security
- **Code Splitting**: Lazy loading
- **Image Optimization**: Next.js Image

## 🔒 Security

- Row Level Security (RLS) on all tables
- Secure authentication with Supabase
- Protected API routes
- XSS protection
- CSRF tokens
- Secure headers
- Input validation
- SQL injection prevention

## 📝 Future Enhancements

- [ ] Recurring transactions automation
- [ ] PDF report generation
- [ ] Mobile app (React Native)
- [ ] Multi-currency support
- [ ] Invoice management
- [ ] Tax calculations
- [ ] Team collaboration features
- [ ] API webhooks
- [ ] Third-party integrations
- [ ] Advanced reporting

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Next.js Team
- Supabase Team
- shadcn/ui
- Tailwind CSS

## 📞 Support

For support, email support@billease.com or join our Slack channel.

---

**Built with ❤️ for modern businesses**
