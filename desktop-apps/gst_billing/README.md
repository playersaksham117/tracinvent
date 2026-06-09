# BillEase Accounts+

Professional Indian GST Billing & Accounting Application

## Features

- **GST Compliance**: CGST + SGST (intra-state), IGST (inter-state)
- **HSN/SAC Codes**: Automatic mapping per product
- **Tax Slabs**: Support for 0%, 5%, 12%, 18%, 28% GST rates
- **Invoice Generation**: Professional PDF invoices with print/share
- **Credit Sales (Udhar)**: Track outstanding payments
- **Keyboard Shortcuts**: Fast billing with Ctrl+N, Ctrl+S, Ctrl+P, etc.
- **GSTR-1/GSTR-3B Ready**: Export data for tax filing

## POS And Billing Requirements

Enable fast billing while ensuring inventory accuracy, tax compliance, and accounting integration.

### 2.1 Sales Billing Functions

- GST compliant invoice generation
- B2B and B2C
- Tax inclusive and tax exclusive
- Multiple price lists
- Item and bill discounts
- Multiple units
- Barcode scanning
- Split payments
- Round off
- Sales return and refund
- Credit and debit notes
- Estimate to bill conversion
- Hold and recall bills

Why important: front counter must be fast and mistake-proof.

### 2.2 Tax Logic

- Auto CGST, SGST, IGST
- Reverse charge handling
- Exempt items
- Composition handling
- HSN and SAC tagging

Purpose: avoid wrong tax and prevent notices.

### 2.3 Payment Handling

- Cash
- UPI
- Card
- Wallet
- Mixed modes
- Credit sale
- Partial payment

Purpose: maintain accurate books.

### 2.4 Hardware Integration

- Thermal printer
- Barcode scanner
- Cash drawer
- Weighing scale
- Kitchen printer (restaurant)

### 2.5 POS Control

- Cashier login
- Shift open and close
- Cash counting
- Supervisor override
- Discount limits

### 2.6 POS To Accounting Impact

Every sale automatically:

- Updates revenue
- Updates GST payable
- Updates cash or bank
- Updates customer ledger
- Updates stock
- Records COGS

#### Default Accounting Mapping (Example)

- Debit Cash or Bank (for immediate payments)
- Debit Accounts Receivable (for credit sales)
- Credit Sales Revenue
- Credit CGST Payable, SGST Payable, or IGST Payable
- Debit Cost Of Goods Sold
- Credit Inventory

## Cross-Module Governance Requirements

All modules must:

- Share common identity.
- Share organization data.
- Post financial impact to accounting.
- Maintain audit history.
- Support compliance.
- Work in multi-branch setups.
- Avoid data silos (use shared sources of truth).

## Getting Started

1. Install Flutter SDK (3.10.1+)
2. Run `flutter pub get`
3. Run `flutter run -d windows`

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+N | New Invoice |
| Ctrl+S | Save Invoice |
| Ctrl+P | Print Invoice |
| Ctrl+T | Toggle Tax Mode |
| Ctrl+Shift+W | Share via WhatsApp |
| F5 | Toggle Credit Sale |

## License

© Vyoumix - All Rights Reserved
