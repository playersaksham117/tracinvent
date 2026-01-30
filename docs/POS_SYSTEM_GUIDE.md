# 📱 BillEase POS System - Complete Guide

## Overview

BillEase POS is a comprehensive Point of Sale system available in both **Web** and **Desktop** versions, featuring:

- 🧾 Complete billing and sales management
- 📦 Real-time inventory tracking
- 👤 Customer relationship management
- 💳 Multiple payment methods
- 📊 Tax and discount calculations
- 📸 Barcode scanning support
- 🖨️ Receipt printing
- 📈 Sales reporting

---

## 🌐 Web POS Application

### Features

#### 🧾 Billing & Sales
- ✅ Create and print invoices/receipts
- ✅ Quick product addition via barcode scan or manual entry
- ✅ Apply item-level and global discounts
- ✅ Automatic tax calculation (GST/VAT support)
- ✅ Multiple payment methods:
  - 💵 Cash
  - 💳 Credit/Debit Card
  - 📱 UPI
  - 👛 Digital Wallet
  - 🏦 Bank Transfer
- ✅ Multi-currency support
- ✅ Change calculation
- ✅ Payment reference tracking

#### 📦 Product & Inventory Management
- ✅ Add/update products with:
  - Name, SKU, Barcode
  - Selling price, Cost price
  - Tax rates
  - Stock quantity
  - Reorder levels
  - Categories and brands
  - Product images
- ✅ Real-time stock tracking
- ✅ Low stock alerts (visual indicators)
- ✅ Stock adjustment tracking with history
- ✅ Product search and filtering

#### 👤 Customer Management
- ✅ Add and save customer details:
  - Name, Phone, Email
  - Address and location
  - Customer group (Regular/VIP/Wholesale)
  - Credit limits
  - Loyalty points
- ✅ Track complete purchase history
- ✅ Quick customer search
- ✅ In-line customer creation during checkout

### Setup

1. **Database Migration**
   ```bash
   cd main-website
   # Run migrations in your Supabase dashboard or via CLI
   # 1. migrations/pos/001_initial_schema.sql
   # 2. migrations/pos/002_customers_and_enhancements.sql
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   Create `.env.local`:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key
   JWT_SECRET=your_jwt_secret
   ```

4. **Start Development Server**
   ```bash
   npm run dev
   ```

5. **Initialize Payment Methods**
   On first login, initialize payment methods:
   ```bash
   POST /api/pos/payment-methods
   ```

### Usage

#### Making a Sale

1. **Login** to the system
2. **Navigate** to POS (`/apps/pos`)
3. **Select Customer** (optional but recommended)
   - Click "👤 Customer" button
   - Search existing or add new customer
4. **Add Products**
   - Use barcode scanner input
   - Click product cards
   - Search by name/SKU/category
5. **Adjust Quantities**
   - Use +/- buttons
   - Apply item discounts if needed
6. **Apply Discount Code** (optional)
   - Enter code and validate
7. **Checkout**
   - Review order summary
   - Select payment method
   - Enter amount paid
   - Add reference number (for card/UPI/wallet)
   - Complete sale
8. **Print Receipt**
   - Receipt automatically opens in new window
   - Print or save as PDF

#### Managing Products

**Add New Product:**
```
POST /api/products
{
  "name": "Product Name",
  "sku": "SKU-001",
  "barcode": "1234567890",
  "selling_price": 29.99,
  "cost_price": 15.00,
  "tax_rate": 18.0,
  "stock_quantity": 100,
  "reorder_level": 20,
  "category": "Electronics",
  "is_active": true
}
```

**Adjust Stock:**
```
POST /api/pos/stock/adjust
{
  "product_id": "uuid",
  "adjustment_type": "add", // or "remove", "set"
  "quantity_change": 10,
  "reason": "Stock replenishment"
}
```

#### Creating Discounts

```
POST /api/pos/discounts
{
  "code": "SAVE10",
  "name": "10% Off",
  "discount_type": "percentage",
  "discount_value": 10,
  "min_purchase_amount": 50,
  "valid_from": "2026-01-01",
  "valid_until": "2026-12-31",
  "is_active": true
}
```

---

## 🖥️ Desktop POS Application

### Features

All Web POS features plus:
- ✅ Offline-capable (with sync)
- ✅ Native GUI using Tkinter
- ✅ Fast barcode scanning
- ✅ Standalone installation
- ✅ Cross-platform (Windows, Mac, Linux)

### Setup

1. **Install Python 3.8+**
   - Download from [python.org](https://www.python.org/downloads/)

2. **Install Dependencies**
   ```bash
   cd desktop-app/python_backend
   pip install -r requirements.txt
   ```

3. **Configure API URL**
   Edit `pos_app.py`:
   ```python
   API_BASE_URL = "http://localhost:3000/api"  # Your API URL
   ```

4. **Run Application**
   ```bash
   python pos_app.py
   ```

### Building Standalone Executable

**Windows:**
```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name="BillEase POS" --icon=icon.ico pos_app.py
```

**Mac:**
```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name="BillEase POS" --icon=icon.icns pos_app.py
```

**Linux:**
```bash
pip install pyinstaller
pyinstaller --onefile --name="BillEase POS" pos_app.py
```

### Usage

1. **Launch Application**
2. **Login** with credentials
3. **Add Products to Cart**
   - Click product cards
   - Use barcode scanner
   - Search products
4. **Manage Cart**
   - Adjust quantities
   - Remove items
5. **Select Customer** (optional)
6. **Checkout**
   - Choose payment method
   - Enter amount
   - Complete sale
7. **Receipt** auto-prints

---

## 🎯 Key Features Comparison

| Feature | Web POS | Desktop POS |
|---------|---------|-------------|
| Billing & Invoices | ✅ | ✅ |
| Barcode Scanning | ✅ | ✅ |
| Multiple Payment Methods | ✅ | ✅ |
| Tax Calculations | ✅ | ✅ |
| Discounts & Offers | ✅ | ✅ |
| Customer Management | ✅ | ✅ |
| Inventory Tracking | ✅ | ✅ |
| Low Stock Alerts | ✅ | ✅ |
| Receipt Printing | ✅ | ✅ |
| Multi-currency | ✅ | ⚠️ (requires API) |
| Offline Mode | ❌ | ✅ (with sync) |
| Auto-updates | ✅ | ⚠️ (manual) |

---

## 📊 Database Schema

### Key Tables

**products**
- Product catalog with pricing, stock, tax info

**customers**
- Customer profiles and contact details

**sales**
- Complete sale transactions

**sale_items**
- Line items for each sale

**payment_transactions**
- Payment tracking with methods

**stock_adjustments**
- Inventory change history

**discounts**
- Promotional codes and offers

**payment_methods**
- Available payment options

**tax_rates**
- Tax configuration

**shifts**
- Cashier shift management

---

## 🔒 Security

- JWT-based authentication
- Row-level security (RLS) in Supabase
- Tenant isolation
- Secure API endpoints
- Password hashing
- HTTPS required in production

---

## 🚀 Deployment

### Web Application

**Vercel (Recommended):**
```bash
npm run build
vercel --prod
```

**Other Platforms:**
```bash
npm run build
npm start
```

### Desktop Application

1. Build executable (see above)
2. Distribute installer
3. Configure API URL
4. Users run locally

---

## 📱 API Endpoints

### Sales
- `GET /api/pos/sales` - List sales
- `POST /api/pos/sales` - Create sale
- `GET /api/pos/sales/:id` - Get sale details

### Customers
- `GET /api/pos/customers` - List customers
- `POST /api/pos/customers` - Create customer
- `PUT /api/pos/customers` - Update customer
- `GET /api/pos/customers/:id/history` - Purchase history

### Products
- `GET /api/products` - List products
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Inventory
- `GET /api/pos/stock` - Stock levels
- `POST /api/pos/stock/adjust` - Adjust stock
- `GET /api/pos/stock?low_stock=true` - Low stock items

### Payments & Discounts
- `GET /api/pos/payment-methods` - List payment methods
- `POST /api/pos/discounts/validate` - Validate discount code
- `GET /api/pos/discounts` - List discounts

---

## 🛠️ Troubleshooting

### Web POS

**Products not showing:**
- Check database connection
- Verify authentication
- Check browser console for errors

**Barcode scanner not working:**
- Ensure input field is focused
- Check scanner configuration
- Test with keyboard input

**Receipt not printing:**
- Check browser pop-up settings
- Allow print dialogs
- Verify printer connection

### Desktop POS

**Cannot connect to API:**
- Verify API_BASE_URL
- Check network connection
- Ensure API is running

**Login fails:**
- Check credentials
- Verify API endpoint
- Check firewall settings

**Products not loading:**
- Check API authentication
- Verify network connectivity
- Check API response in logs

---

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review API logs
3. Check browser console (Web)
4. Review error messages (Desktop)
5. Contact support team

---

## 🎉 Success!

You now have a fully functional POS system with:
- ✅ Web and Desktop applications
- ✅ Complete billing functionality
- ✅ Inventory management
- ✅ Customer tracking
- ✅ Multiple payment methods
- ✅ Barcode scanning
- ✅ Receipt printing
- ✅ Real-time stock updates

Start making sales! 🚀
