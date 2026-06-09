# BillEase Admin Panel

This admin panel allows you to manage customers, desktop licenses, web subscriptions, and pricing settings.

## Features

- **Dashboard Overview**: View key metrics like MRR, customer count, active subscriptions, and recent activity
- **Customer Management**: View, search, and manage all customers
- **Desktop Licenses**: Generate, validate, revoke, and manage desktop application licenses
- **Web Subscriptions**: Monitor and manage web app subscriptions
- **Pricing Settings**: Configure subscription plans, desktop license pricing, and discount codes

## Supabase Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Save your project URL and anon key

### 2. Run Database Schema

1. Go to the SQL Editor in your Supabase dashboard
2. Copy the contents of `supabase/schema.sql`
3. Run the SQL to create all tables, indexes, and policies

### 3. Create Storage Bucket

1. Go to Storage in your Supabase dashboard
2. Create a new bucket called `admin-assets`
3. Set it to public (or configure RLS as needed)

### 4. Configure Environment Variables

Add these to your `.env.local` file:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 5. Configure Authentication (Optional)

For admin authentication, you can:

1. Use Supabase Auth with role-based access
2. Add users and set their `raw_user_meta_data` with `role: 'admin'` or `role: 'super_admin'`
3. The RLS policies will automatically restrict access based on user roles

## API Endpoints

### Customers API (`/api/admin/customers`)
- `GET`: Fetch customers with search, filters, and pagination
- `POST`: Create a new customer
- `PUT`: Update an existing customer
- `DELETE`: Delete a customer

### Licenses API (`/api/admin/licenses`)
- `GET`: Fetch licenses with filters and pagination
- `POST`: Generate a new license
- `PUT`: Update license (revoke, reset activations, etc.)
- `DELETE`: Delete a license

### License Validation API (`/api/admin/licenses/validate`)
- `POST`: Validate and activate a license key (used by desktop apps)

### Subscriptions API (`/api/admin/subscriptions`)
- `GET`: Fetch subscriptions with filters and pagination
- `POST`: Create a new subscription
- `PUT`: Update subscription (cancel, reactivate, etc.)
- `DELETE`: Delete a subscription

### Pricing API (`/api/admin/pricing`)
- `GET`: Fetch all pricing (plans, desktop pricing, discounts)
- `POST`: Create new pricing items
- `PUT`: Update pricing items
- `DELETE`: Delete pricing items

### Stats API (`/api/admin/stats`)
- `GET`: Fetch dashboard statistics

## Database Schema

### Tables

- `admin_customers`: Customer records
- `desktop_licenses`: License keys for desktop applications
- `license_activations`: Track machine activations per license
- `admin_subscriptions`: Web subscription records
- `pricing_plans`: Web subscription pricing plans
- `desktop_product_pricing`: Desktop license pricing
- `discount_codes`: Promotional discount codes
- `admin_activities`: Admin action audit log

### Real-time Updates

The admin panel uses Supabase Realtime for live updates:
- Customer changes
- License changes
- Subscription changes

## Desktop App Integration

### License Validation Endpoint

Desktop applications can validate licenses using:

```
POST /api/admin/licenses/validate
{
  "license_key": "BE-POS-XXXXXXXX-XXXX",
  "hardware_id": "unique-machine-identifier",
  "machine_name": "USER-PC",
  "os_info": "Windows 11"
}
```

Response:
```json
{
  "valid": true,
  "license": {
    "product": "BillEase POS",
    "type": "perpetual",
    "expires_on": null,
    "features": {}
  }
}
```

## Security Considerations

1. **Row Level Security (RLS)**: All tables have RLS enabled with admin-only policies
2. **API Authentication**: Add authentication middleware for production
3. **Rate Limiting**: Consider adding rate limiting for the license validation endpoint
4. **Input Validation**: All API endpoints validate input data
5. **Audit Logging**: Admin activities are logged to `admin_activities` table

## Development

```bash
# Start development server
npm run dev

# Access admin panel
http://localhost:3000/admin
```

## Production Checklist

- [ ] Set up proper Supabase RLS policies
- [ ] Configure authentication for admin routes
- [ ] Set up rate limiting
- [ ] Enable audit logging
- [ ] Configure backup schedule for database
- [ ] Set up monitoring and alerts
- [ ] Connect Stripe for payment processing
