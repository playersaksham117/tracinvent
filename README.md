# BillEase Suite

A comprehensive business management suite with POS, accounting, and financial management applications.

## 📁 Project Structure

```
BillEase Suite/
├── desktop-apps/          # Desktop applications
│   ├── billease-pos/     # Flutter-based Point of Sale system
│   └── tracinvent/       # Inventory tracking with warehouse management
│
├── web-apps/             # Web applications
│   └── billease-website/ # Next.js main website and SaaS platform
│
├── mobile-apps/          # Mobile applications
│   └── spendsight/      # Mobile financial management app
│
├── backend-services/     # Backend services
│   └── python-backend/  # Python API services
│
├── database/            # Database management
│   └── migrations/      # SQL migration scripts
│       ├── accounts/    # Accounting module migrations
│       ├── crm/         # CRM module migrations
│       ├── inventory/   # Inventory module migrations
│       ├── main/        # Main database migrations
│       ├── pos/         # POS module migrations
│       └── saas/        # SaaS multi-tenant migrations
│
└── docs/                # Documentation
    ├── Architecture and design docs
    ├── Implementation guides
    ├── Setup instructions
    └── Quick reference guides
```

## 🚀 Quick Start

### Desktop Applications

#### BillEase POS
```bash
cd desktop-apps/billease-pos
# Run setup script
./setup-pos.bat  # Windows
./setup-pos.sh   # Linux/Mac
```

#### TracInvent (Inventory Tracker)
```bash
cd desktop-apps/tracinvent
flutter pub get
flutter run -d windows  # or linux/macos
```

### Web Application
```bash
cd web-apps/billease-website
npm install
npm run dev
```

### Mobile Application
```bash
cd mobile-apps/spendsight
# Follow mobile app setup instructions
```

### Backend Services
```bash
cd backend-services/python-backend
# Follow backend setup instructions
```

## 📚 Documentation

All documentation is located in the `docs/` folder:
- Architecture diagrams and system design
- Database schemas and migration guides
- Feature documentation
- Setup and deployment guides
- Quick reference guides

## 🛠️ Technologies

- **Desktop**: Flutter (Windows, Linux, Mac)
- **Web**: Next.js, TypeScript, Tailwind CSS
- **Mobile**: (To be developed)
- **Backend**: Python
- **Database**: Supabase, PostgreSQL, SQLite

## 📝 License

Proprietary - All rights reserved
