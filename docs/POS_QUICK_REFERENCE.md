# 🚀 BillEase POS - Quick Reference

## 📋 Quick Commands

### Web App
```bash
# Install
cd main-website && npm install

# Run dev
npm run dev

# Build
npm run build

# Start production
npm start
```

### Desktop App
```bash
# Install
cd desktop-app/python_backend
pip install -r requirements.txt

# Run
python pos_app.py

# Build executable
pyinstaller --onefile --windowed --name="BillEase POS" pos_app.py
```

## 🔑 API Quick Reference

### Authentication
```bash
# Login
POST /api/auth/login
{ "email": "user@example.com", "password": "password" }

# Get current user
GET /api/auth/me
Headers: { "Authorization": "Bearer TOKEN" }
```

### Products
```bash
# List products
GET /api/products

# Create product
POST /api/products
{
  "name": "Product Name",
  "sku": "SKU-001",
  "barcode": "1234567890",
  "selling_price": 29.99,
  "tax_rate": 18.0,
  "stock_quantity": 100
}

# Update product
PUT /api/products/:id

# Delete product
DELETE /api/products/:id
```

### Customers
```bash
# List customers
GET /api/pos/customers

# Search customers
GET /api/pos/customers?search=john

# Create customer
POST /api/pos/customers
{
  "name": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com"
}
```

### Sales
```bash
# List sales
GET /api/pos/sales

# Get customer sales
GET /api/pos/sales?customer_id=UUID

# Create sale
POST /api/pos/sales
{
  "customer_id": "uuid",
  "items": [
    {
      "product_id": "uuid",
      "quantity": 2,
      "unit_price": 29.99,
      "tax_rate": 18.0
    }
  ],
  "payment_method": "cash",
  "amount_paid": 100.00
}
```

### Inventory
```bash
# Get stock levels
GET /api/pos/stock

# Get low stock items
GET /api/pos/stock?low_stock=true

# Adjust stock
POST /api/pos/stock/adjust
{
  "product_id": "uuid",
  "adjustment_type": "add",
  "quantity_change": 10,
  "reason": "Restock"
}
```

### Discounts
```bash
# List discounts
GET /api/pos/discounts

# Validate discount
POST /api/pos/discounts/validate
{
  "code": "SAVE10",
  "purchase_amount": 100.00
}
```

## ⌨️ Keyboard Shortcuts (Web)

| Action | Shortcut |
|--------|----------|
| Focus barcode input | `Alt + B` |
| Focus search | `Alt + S` |
| Checkout | `Alt + C` |
| Clear cart | `Alt + X` |
| Select customer | `Alt + U` |

## 📊 Database Quick Queries

### Get tenant ID
```sql
SELECT id FROM tenants WHERE user_id = auth.uid();
```

### Top selling products
```sql
SELECT p.name, SUM(si.quantity) as total_sold, SUM(si.total) as revenue
FROM products p
JOIN sale_items si ON p.id = si.product_id
JOIN sales s ON si.sale_id = s.id
WHERE s.status = 'completed'
GROUP BY p.id
ORDER BY revenue DESC
LIMIT 10;
```

### Today's sales
```sql
SELECT COUNT(*) as transactions, SUM(total_amount) as revenue
FROM sales
WHERE DATE(completed_at) = CURRENT_DATE
AND status = 'completed';
```

### Low stock products
```sql
SELECT name, sku, stock_quantity, reorder_level
FROM products
WHERE stock_quantity <= reorder_level
AND is_active = true;
```

### Top customers
```sql
SELECT name, phone, total_purchases, total_transactions
FROM customers
ORDER BY total_purchases DESC
LIMIT 10;
```

## 🐛 Common Issues & Fixes

### Products not showing
```bash
# Check if products exist
SELECT COUNT(*) FROM products WHERE is_active = true;

# Check tenant_id
SELECT * FROM tenants WHERE user_id = auth.uid();
```

### Payment methods missing
```bash
# Initialize payment methods
curl -X POST http://localhost:3000/api/pos/payment-methods \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Stock not updating
```bash
# Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'products';

# Manually update
UPDATE products SET stock_quantity = 100 WHERE id = 'uuid';
```

### Customer purchase history empty
```bash
# Check if customer_id is set on sales
SELECT sale_number, customer_id, customer_name FROM sales;

# Update existing sales
UPDATE sales SET customer_id = 'customer_uuid' 
WHERE customer_phone = '+1234567890';
```

## 📱 Testing Checklist

### Before Go-Live
- [ ] Run all migrations
- [ ] Initialize payment methods
- [ ] Add sample products
- [ ] Test barcode scanning
- [ ] Test checkout flow
- [ ] Test receipt printing
- [ ] Test customer creation
- [ ] Test stock adjustments
- [ ] Test discount codes
- [ ] Verify all calculations
- [ ] Test on mobile (web)
- [ ] Test desktop app
- [ ] Backup database

## 🔒 Security Checklist

- [ ] Change default passwords
- [ ] Set up HTTPS
- [ ] Configure CORS properly
- [ ] Enable RLS policies
- [ ] Set up backup system
- [ ] Configure rate limiting
- [ ] Enable audit logging
- [ ] Review user permissions
- [ ] Secure API keys
- [ ] Set up monitoring

## 📞 Support

- 📖 Full Guide: [POS_SYSTEM_GUIDE.md](POS_SYSTEM_GUIDE.md)
- 📝 Summary: [POS_IMPLEMENTATION_SUMMARY.md](POS_IMPLEMENTATION_SUMMARY.md)
- 🗄️ Database: See `migrations/pos/` folder
- 💻 Code: Check inline comments

## 🎯 Performance Tips

1. **Index frequently queried fields**
   ```sql
   CREATE INDEX idx_products_active_stock 
   ON products(is_active, stock_quantity);
   ```

2. **Use connection pooling**
3. **Enable query caching**
4. **Optimize image sizes**
5. **Lazy load product images**
6. **Use pagination for large lists**

## 🚀 Deployment

### Vercel (Web)
```bash
vercel --prod
```

### Digital Ocean (API)
```bash
docker build -t billease-api .
docker push registry/billease-api
```

### Desktop App Distribution
```bash
# Create installer (Windows)
pyinstaller --onefile --windowed pos_app.py
# Use Inno Setup for installer

# Create app bundle (Mac)
pyinstaller --onefile --windowed --icon=icon.icns pos_app.py

# Create package (Linux)
pyinstaller --onefile pos_app.py
# Use fpm to create .deb or .rpm
```

## 📈 Monitoring

### Key Metrics to Track
- Daily sales count
- Average transaction value
- Product velocity
- Low stock alerts
- Customer growth
- Payment method usage
- Peak hours
- Error rates

### Logs to Review
- Failed transactions
- Stock adjustments
- Login attempts
- API errors
- Slow queries

---

**Quick Start:** Run `setup-pos.bat` (Windows) or `setup-pos.sh` (Linux/Mac)

**Emergency:** Check logs in browser console (Web) or terminal (Desktop)

**Help:** See [POS_SYSTEM_GUIDE.md](POS_SYSTEM_GUIDE.md) for detailed documentation
