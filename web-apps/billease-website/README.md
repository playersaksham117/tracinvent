# BillEase Main Website - Setup Guide

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd main-website
npm install
```

### 2. Setup Environment Variables

```bash
cp .env.example .env.local
```

Edit `.env.local` with your actual values:
- Get Supabase credentials from https://supabase.com
- Get Stripe keys from https://stripe.com
- Generate JWT secret: `openssl rand -base64 32`

### 3. Setup Database

Run the migration files in order:

```bash
# Main database
psql postgresql://user:password@localhost:5432/billease_main -f ../migrations/main/001_initial_schema.sql

# App databases
psql postgresql://user:password@localhost:5432/billease_pos -f ../migrations/pos/001_initial_schema.sql
psql postgresql://user:password@localhost:5432/billease_crm -f ../migrations/crm/001_initial_schema.sql
psql postgresql://user:password@localhost:5432/billease_accounts -f ../migrations/accounts/001_initial_schema.sql
psql postgresql://user:password@localhost:5432/billease_inventory -f ../migrations/inventory/001_initial_schema.sql
```

### 4. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## 📁 Project Structure

```
main-website/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (marketing)/       # Marketing pages (homepage, products, etc.)
│   │   ├── (auth)/            # Authentication pages (login, signup)
│   │   ├── dashboard/         # User dashboard
│   │   ├── admin/             # Admin panel
│   │   ├── api/               # API routes
│   │   ├── layout.tsx         # Root layout
│   │   ├── page.tsx           # Homepage
│   │   └── globals.css        # Global styles
│   │
│   ├── components/            # React components
│   │   ├── ui/                # shadcn/ui components
│   │   ├── layout/            # Layout components (Navbar, Footer)
│   │   ├── marketing/         # Marketing components
│   │   ├── dashboard/         # Dashboard components
│   │   └── admin/             # Admin components
│   │
│   ├── lib/                   # Utility libraries
│   │   ├── supabase/          # Supabase clients
│   │   ├── stripe/            # Stripe integration
│   │   ├── auth/              # Authentication utilities
│   │   └── utils.ts           # General utilities
│   │
│   ├── types/                 # TypeScript types
│   └── hooks/                 # Custom React hooks
│
├── public/                    # Static files
├── migrations/                # Database migrations (in parent directory)
├── .env.local                 # Environment variables (create this)
├── .env.example               # Environment variables template
├── next.config.js             # Next.js configuration
├── tailwind.config.ts         # Tailwind CSS configuration
├── tsconfig.json              # TypeScript configuration
└── package.json               # Dependencies
```

## 🔐 Authentication Flow

1. User signs up on main website
2. User selects subscription plan
3. Payment processed via Stripe
4. User gets access to selected apps
5. JWT token generated for app access
6. User redirected to app with token

## 🎨 Design System

Based on shadcn/ui with customized colors:
- Primary: Blue (#3B82F6)
- Success: Green (#10B981)
- Warning: Yellow (#F59E0B)
- Danger: Red (#EF4444)

## 📝 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint

## 🔧 Next Steps

1. ✅ Setup project structure
2. ⬜ Install dependencies
3. ⬜ Create authentication pages
4. ⬜ Build user dashboard
5. ⬜ Implement admin panel
6. ⬜ Setup Stripe integration
7. ⬜ Create API routes
8. ⬜ Deploy to Vercel

## 📚 Documentation

- [Next.js Docs](https://nextjs.org/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Stripe Docs](https://stripe.com/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [shadcn/ui](https://ui.shadcn.com)

## 🐛 Troubleshooting

### Port already in use
```bash
# Kill process on port 3000
npx kill-port 3000
# Or use different port
npm run dev -- -p 3001
```

### Module not found errors
```bash
# Clear cache and reinstall
rm -rf node_modules .next
npm install
```

### TypeScript errors
```bash
# Regenerate types
npm run build
```

## 🚀 Deployment

### Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Deploy to production
vercel --prod
```

Set environment variables in Vercel dashboard.

## 📞 Support

For issues or questions, please open an issue on GitHub.
