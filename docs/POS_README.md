# 🏪 BillEase POS System

**A complete, production-ready Point of Sale system with Web and Desktop applications**

## 🎯 What is This?

BillEase POS is a comprehensive billing and sales management system designed for retail businesses. It provides everything you need to run a modern retail operation:

- 💳 **Complete Billing** - Create invoices with tax, discounts, and multiple payment methods
- 📦 **Inventory Management** - Real-time stock tracking with low-stock alerts
- 👤 **Customer Management** - Track customer purchases and build relationships
- 📊 **Sales Analytics** - Understand your business performance
- 🖨️ **Receipt Printing** - Professional receipt generation
- 📱 **Multi-Platform** - Available as Web app and Desktop application

## ✨ Key Features

### Billing & Sales
- ✅ Invoice creation with automatic numbering
- ✅ Barcode scanning support
- ✅ Multiple payment methods (Cash, Card, UPI, Wallet, Bank Transfer)
- ✅ Tax calculations (GST/VAT)
- ✅ Item-level and cart-level discounts
- ✅ Promotional codes
- ✅ Change calculation
- ✅ Receipt printing

### Inventory
- ✅ Product catalog with images
- ✅ Real-time stock tracking
- ✅ Low stock alerts
- ✅ Stock adjustment history
- ✅ Barcode management
- ✅ Category & brand organization

### Customers
- ✅ Customer profiles with full details
- ✅ Purchase history tracking
- ✅ Customer groups (Regular/VIP/Wholesale)
- ✅ Loyalty points
- ✅ Quick search and selection

## 🚀 Quick Start

### Option 1: Automated Setup (Windows)
```bash
.\setup-pos.bat
```

### Option 2: Automated Setup (Linux/Mac)
```bash
chmod +x setup-pos.sh
./setup-pos.sh
```

### Option 3: Manual Setup

1. **Database Setup**
   - Run migrations in Supabase:
     - `migrations/pos/001_initial_schema.sql`
     - `migrations/pos/002_customers_and_enhancements.sql`
     - (Optional) `migrations/pos/003_sample_data.sql`

2. **Web App**
   ```bash
   cd main-website
   npm install
   npm run dev
   ```
   
3. **Desktop App**
   ```bash
   cd desktop-app/python_backend
   pip install -r requirements.txt
   python pos_app.py
   ```

## 📖 Documentation

- **📘 [Complete System Guide](POS_SYSTEM_GUIDE.md)** - Full documentation for users and developers
- **📋 [Quick Reference](POS_QUICK_REFERENCE.md)** - Commands, APIs, and shortcuts
- **📝 [Implementation Summary](POS_IMPLEMENTATION_SUMMARY.md)** - What was built and how
- **🏗️ [Architecture](POS_ARCHITECTURE.md)** - System design and structure

## 🖥️ Screenshots

### Web Application
The web app features:
- Modern, responsive design
- Product grid with search and barcode scanning
- Real-time cart with automatic calculations
- Customer selection and management
- Complete checkout workflow
- Professional receipt printing

### Desktop Application
The desktop app provides:
- Native GUI using Python Tkinter
- Fast barcode scanning
- Offline capability (with API sync)
- Cross-platform support
- Standalone installation

## 🛠️ Technology Stack

### Web
- **Frontend:** Next.js 14, React 18, Tailwind CSS
- **Backend:** Next.js API Routes
- **Database:** PostgreSQL (Supabase)
- **Auth:** JWT

### Desktop
- **Language:** Python 3.8+
- **GUI:** Tkinter
- **API Client:** Requests

## 📦 What's Included

### Files Created
- ✅ 5 API route files (customers, sales, stock, payments, discounts)
- ✅ 1 comprehensive POS UI (1000+ lines)
- ✅ 1 desktop application (600+ lines)
- ✅ 3 database migration files
- ✅ Updated TypeScript types
- ✅ 5 documentation files
- ✅ Setup scripts for Windows and Linux/Mac

### Features Implemented
- ✅ Complete billing workflow
- ✅ Barcode scanning
- ✅ Multiple payment methods
- ✅ Tax calculations
- ✅ Discount codes
- ✅ Customer management
- ✅ Inventory tracking
- ✅ Receipt printing
- ✅ Stock adjustments
- ✅ Purchase history

## 🎯 Use Cases

Perfect for:
- 🏪 Retail stores
- 🍽️ Restaurants & cafes
- 🛒 Grocery stores
- 📚 Book stores
- 👕 Clothing stores
- 🔧 Hardware stores
- 💊 Pharmacies
- 🎁 Gift shops

## 🔒 Security

- JWT authentication
- Row-level security (RLS)
- Tenant isolation
- HTTPS encryption
- Password hashing
- API authorization

## 📊 Sample Data

Load sample data for testing:
```sql
-- Edit migrations/pos/003_sample_data.sql
-- Replace YOUR_TENANT_ID with your tenant ID
-- Run in Supabase SQL Editor
```

Includes:
- 25 sample products across 4 categories
- 10 sample customers
- 5 payment methods
- 5 discount codes
- 5 currencies

## 🚢 Deployment

### Web App
```bash
cd main-website
npm run build
vercel --prod
```

### Desktop App
```bash
cd desktop-app/python_backend
pyinstaller --onefile --windowed --name="BillEase POS" pos_app.py
```

## 📱 API Endpoints

### Core Endpoints
- `POST /api/auth/login` - Authentication
- `GET /api/products` - List products
- `POST /api/pos/sales` - Create sale
- `GET /api/pos/customers` - List customers
- `POST /api/pos/stock/adjust` - Adjust inventory
- `POST /api/pos/discounts/validate` - Validate discount

Full API documentation in [Quick Reference](POS_QUICK_REFERENCE.md)

## 🐛 Troubleshooting

### Common Issues

**Products not showing**
- Check database connection
- Verify migrations ran successfully
- Check authentication token

**Barcode scanner not working**
- Ensure input field is focused
- Test with manual entry
- Check scanner configuration

**Receipt not printing**
- Check browser pop-up settings
- Verify printer connection
- Allow print dialogs

Full troubleshooting guide in [System Guide](POS_SYSTEM_GUIDE.md)

## 📞 Support

1. Check the documentation files
2. Review the Quick Reference guide
3. Check browser console for errors
4. Review API logs
5. Contact your development team

## 🎓 Learning Path

1. **Start Here:** [Implementation Summary](POS_IMPLEMENTATION_SUMMARY.md)
2. **Learn More:** [System Guide](POS_SYSTEM_GUIDE.md)
3. **Quick Reference:** [Quick Reference](POS_QUICK_REFERENCE.md)
4. **Deep Dive:** [Architecture](POS_ARCHITECTURE.md)

## 🎉 Success!

You now have a complete, production-ready POS system! 

**Next Steps:**
1. ✅ Complete the setup
2. ✅ Load sample data
3. ✅ Test all features
4. ✅ Configure for your business
5. ✅ Start making sales!

## 📄 License

Part of the BillEase Suite.

---

**Built with ❤️ for modern retail businesses**

🌟 Star this project • 🐛 Report issues • 💡 Suggest features
