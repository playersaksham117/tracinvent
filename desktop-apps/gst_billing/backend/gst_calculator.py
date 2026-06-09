"""
GST Calculator - Indian GST Tax Calculation Engine
Handles CGST/SGST/IGST calculation based on place of supply
"""

from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
from decimal import Decimal, ROUND_HALF_UP
from enum import Enum


class GSTType(Enum):
    """GST Type based on transaction"""
    INTRA_STATE = "INTRA"      # CGST + SGST
    INTER_STATE = "INTER"      # IGST
    EXPORT = "EXPORT"          # Zero rated / IGST with refund
    SEZ = "SEZ"                # Special Economic Zone


class DiscountType(Enum):
    PERCENTAGE = "PERCENTAGE"
    AMOUNT = "AMOUNT"


@dataclass
class TransactionItem:
    """Individual line item in a transaction"""
    item_id: int
    item_name: str
    hsn_code: str
    quantity: Decimal
    rate: Decimal
    mrp: Decimal = Decimal("0")
    discount_type: DiscountType = DiscountType.AMOUNT
    discount_value: Decimal = Decimal("0")
    gst_rate: Decimal = Decimal("0")
    cess_rate: Decimal = Decimal("0")
    cess_amount: Decimal = Decimal("0")  # Fixed cess per unit
    free_quantity: Decimal = Decimal("0")
    unit_code: str = "NOS"
    
    # Calculated fields
    gross_amount: Decimal = field(default=Decimal("0"), init=False)
    discount_amount: Decimal = field(default=Decimal("0"), init=False)
    taxable_amount: Decimal = field(default=Decimal("0"), init=False)
    cgst_rate: Decimal = field(default=Decimal("0"), init=False)
    cgst_amount: Decimal = field(default=Decimal("0"), init=False)
    sgst_rate: Decimal = field(default=Decimal("0"), init=False)
    sgst_amount: Decimal = field(default=Decimal("0"), init=False)
    igst_rate: Decimal = field(default=Decimal("0"), init=False)
    igst_amount: Decimal = field(default=Decimal("0"), init=False)
    total_cess_amount: Decimal = field(default=Decimal("0"), init=False)
    total_tax_amount: Decimal = field(default=Decimal("0"), init=False)
    total_amount: Decimal = field(default=Decimal("0"), init=False)


@dataclass
class Transaction:
    """Complete transaction with all items"""
    company_state_code: str
    party_state_code: str
    place_of_supply: str
    items: List[TransactionItem]
    is_reverse_charge: bool = False
    is_export: bool = False
    is_sez: bool = False
    
    # Invoice level discount
    invoice_discount_type: DiscountType = DiscountType.AMOUNT
    invoice_discount_value: Decimal = Decimal("0")
    
    # Additional charges
    transport_charges: Decimal = Decimal("0")
    packing_charges: Decimal = Decimal("0")
    other_charges: Decimal = Decimal("0")
    
    # Auto round off
    enable_round_off: bool = True
    
    # Calculated totals
    subtotal: Decimal = field(default=Decimal("0"), init=False)
    total_discount: Decimal = field(default=Decimal("0"), init=False)
    total_taxable: Decimal = field(default=Decimal("0"), init=False)
    total_cgst: Decimal = field(default=Decimal("0"), init=False)
    total_sgst: Decimal = field(default=Decimal("0"), init=False)
    total_igst: Decimal = field(default=Decimal("0"), init=False)
    total_cess: Decimal = field(default=Decimal("0"), init=False)
    total_tax: Decimal = field(default=Decimal("0"), init=False)
    round_off: Decimal = field(default=Decimal("0"), init=False)
    grand_total: Decimal = field(default=Decimal("0"), init=False)
    gst_type: GSTType = field(default=GSTType.INTRA_STATE, init=False)


class GSTCalculator:
    """
    GST Tax Calculator for Indian Taxation
    
    Handles:
    - CGST/SGST for intra-state supply
    - IGST for inter-state supply
    - Cess calculation (percentage or fixed amount)
    - Discount calculation before tax
    - Round off logic
    - Reverse charge mechanism
    - Export and SEZ handling
    """
    
    DECIMAL_PLACES = 2
    
    def __init__(self):
        self.rounding = ROUND_HALF_UP
    
    def round_decimal(self, value: Decimal, places: int = None) -> Decimal:
        """Round a decimal value to specified places"""
        if places is None:
            places = self.DECIMAL_PLACES
        return value.quantize(Decimal(10) ** -places, rounding=self.rounding)
    
    def determine_gst_type(self, transaction: Transaction) -> GSTType:
        """
        Determine GST type based on place of supply
        
        Rules:
        - If company state == place of supply: CGST + SGST (Intra-state)
        - If company state != place of supply: IGST (Inter-state)
        - Export/SEZ: Special handling
        """
        if transaction.is_export:
            return GSTType.EXPORT
        if transaction.is_sez:
            return GSTType.SEZ
        
        if transaction.company_state_code == transaction.place_of_supply:
            return GSTType.INTRA_STATE
        else:
            return GSTType.INTER_STATE
    
    def calculate_item_tax(self, item: TransactionItem, gst_type: GSTType) -> TransactionItem:
        """Calculate tax for a single line item"""
        
        # Step 1: Calculate gross amount
        item.gross_amount = self.round_decimal(item.quantity * item.rate)
        
        # Step 2: Calculate discount
        if item.discount_type == DiscountType.PERCENTAGE:
            item.discount_amount = self.round_decimal(
                item.gross_amount * item.discount_value / Decimal("100")
            )
        else:
            item.discount_amount = self.round_decimal(item.discount_value)
        
        # Step 3: Calculate taxable amount (after discount)
        item.taxable_amount = self.round_decimal(item.gross_amount - item.discount_amount)
        
        # Step 4: Calculate GST based on type
        if gst_type == GSTType.INTRA_STATE:
            # Split equally between CGST and SGST
            item.cgst_rate = self.round_decimal(item.gst_rate / Decimal("2"))
            item.sgst_rate = self.round_decimal(item.gst_rate / Decimal("2"))
            item.igst_rate = Decimal("0")
            
            item.cgst_amount = self.round_decimal(
                item.taxable_amount * item.cgst_rate / Decimal("100")
            )
            item.sgst_amount = self.round_decimal(
                item.taxable_amount * item.sgst_rate / Decimal("100")
            )
            item.igst_amount = Decimal("0")
            
        elif gst_type in [GSTType.INTER_STATE, GSTType.SEZ]:
            # Full IGST
            item.cgst_rate = Decimal("0")
            item.sgst_rate = Decimal("0")
            item.igst_rate = item.gst_rate
            
            item.cgst_amount = Decimal("0")
            item.sgst_amount = Decimal("0")
            item.igst_amount = self.round_decimal(
                item.taxable_amount * item.igst_rate / Decimal("100")
            )
            
        elif gst_type == GSTType.EXPORT:
            # Zero rated for exports (or IGST with refund)
            item.cgst_rate = Decimal("0")
            item.sgst_rate = Decimal("0")
            item.igst_rate = item.gst_rate  # May be zero or with refund
            
            item.cgst_amount = Decimal("0")
            item.sgst_amount = Decimal("0")
            item.igst_amount = self.round_decimal(
                item.taxable_amount * item.igst_rate / Decimal("100")
            )
        
        # Step 5: Calculate Cess
        if item.cess_rate > 0:
            # Percentage cess
            item.total_cess_amount = self.round_decimal(
                item.taxable_amount * item.cess_rate / Decimal("100")
            )
        
        if item.cess_amount > 0:
            # Fixed cess per unit (e.g., ₹10 per cigarette pack)
            item.total_cess_amount += self.round_decimal(
                item.quantity * item.cess_amount
            )
        
        # Step 6: Calculate total tax
        item.total_tax_amount = (
            item.cgst_amount + 
            item.sgst_amount + 
            item.igst_amount + 
            item.total_cess_amount
        )
        
        # Step 7: Calculate total amount
        item.total_amount = item.taxable_amount + item.total_tax_amount
        
        return item
    
    def calculate_transaction(self, transaction: Transaction) -> Transaction:
        """
        Calculate complete transaction with all items
        
        Process:
        1. Determine GST type (Intra/Inter state)
        2. Calculate item-wise tax
        3. Apply invoice-level discount (if any)
        4. Add additional charges
        5. Apply round off
        """
        
        # Determine GST type
        transaction.gst_type = self.determine_gst_type(transaction)
        
        # Reset totals
        transaction.subtotal = Decimal("0")
        transaction.total_discount = Decimal("0")
        transaction.total_taxable = Decimal("0")
        transaction.total_cgst = Decimal("0")
        transaction.total_sgst = Decimal("0")
        transaction.total_igst = Decimal("0")
        transaction.total_cess = Decimal("0")
        
        # Calculate each item
        for item in transaction.items:
            self.calculate_item_tax(item, transaction.gst_type)
            
            transaction.subtotal += item.gross_amount
            transaction.total_discount += item.discount_amount
            transaction.total_taxable += item.taxable_amount
            transaction.total_cgst += item.cgst_amount
            transaction.total_sgst += item.sgst_amount
            transaction.total_igst += item.igst_amount
            transaction.total_cess += item.total_cess_amount
        
        # Apply invoice-level discount proportionally (if any)
        if transaction.invoice_discount_value > 0:
            if transaction.invoice_discount_type == DiscountType.PERCENTAGE:
                invoice_discount = self.round_decimal(
                    transaction.total_taxable * transaction.invoice_discount_value / Decimal("100")
                )
            else:
                invoice_discount = self.round_decimal(transaction.invoice_discount_value)
            
            # Reduce taxable amount and recalculate tax proportionally
            if transaction.total_taxable > 0:
                discount_ratio = invoice_discount / transaction.total_taxable
                
                transaction.total_taxable -= invoice_discount
                transaction.total_discount += invoice_discount
                
                # Reduce tax proportionally
                transaction.total_cgst = self.round_decimal(
                    transaction.total_cgst * (1 - discount_ratio)
                )
                transaction.total_sgst = self.round_decimal(
                    transaction.total_sgst * (1 - discount_ratio)
                )
                transaction.total_igst = self.round_decimal(
                    transaction.total_igst * (1 - discount_ratio)
                )
                transaction.total_cess = self.round_decimal(
                    transaction.total_cess * (1 - discount_ratio)
                )
        
        # Total tax
        transaction.total_tax = (
            transaction.total_cgst + 
            transaction.total_sgst + 
            transaction.total_igst + 
            transaction.total_cess
        )
        
        # Calculate subtotal before round off
        pre_round_total = (
            transaction.total_taxable + 
            transaction.total_tax +
            transaction.transport_charges +
            transaction.packing_charges +
            transaction.other_charges
        )
        
        # Apply round off
        if transaction.enable_round_off:
            rounded_total = self.round_decimal(pre_round_total, 0)
            transaction.round_off = rounded_total - pre_round_total
            transaction.grand_total = rounded_total
        else:
            transaction.round_off = Decimal("0")
            transaction.grand_total = self.round_decimal(pre_round_total)
        
        return transaction
    
    def get_hsn_wise_summary(self, transaction: Transaction) -> List[Dict[str, Any]]:
        """Generate HSN-wise tax summary for invoices"""
        hsn_summary = {}
        
        for item in transaction.items:
            hsn = item.hsn_code or "0000"
            
            if hsn not in hsn_summary:
                hsn_summary[hsn] = {
                    'hsn_code': hsn,
                    'quantity': Decimal("0"),
                    'taxable_amount': Decimal("0"),
                    'cgst_amount': Decimal("0"),
                    'sgst_amount': Decimal("0"),
                    'igst_amount': Decimal("0"),
                    'cess_amount': Decimal("0"),
                    'total_tax': Decimal("0"),
                    'gst_rate': item.gst_rate
                }
            
            hsn_summary[hsn]['quantity'] += item.quantity
            hsn_summary[hsn]['taxable_amount'] += item.taxable_amount
            hsn_summary[hsn]['cgst_amount'] += item.cgst_amount
            hsn_summary[hsn]['sgst_amount'] += item.sgst_amount
            hsn_summary[hsn]['igst_amount'] += item.igst_amount
            hsn_summary[hsn]['cess_amount'] += item.total_cess_amount
            hsn_summary[hsn]['total_tax'] += item.total_tax_amount
        
        return list(hsn_summary.values())
    
    def calculate_reverse_tax(self, amount: Decimal, gst_rate: Decimal, 
                              is_inclusive: bool = True) -> Dict[str, Decimal]:
        """
        Calculate tax from an inclusive amount (reverse calculation)
        Useful when MRP includes GST
        
        Formula: Taxable = Amount / (1 + GST Rate / 100)
        """
        if is_inclusive:
            taxable = self.round_decimal(
                amount * Decimal("100") / (Decimal("100") + gst_rate)
            )
            tax = amount - taxable
        else:
            taxable = amount
            tax = self.round_decimal(amount * gst_rate / Decimal("100"))
        
        return {
            'taxable_amount': taxable,
            'tax_amount': tax
        }


# Utility function for number to words (Indian format)
def number_to_words_indian(number: float) -> str:
    """Convert number to Indian rupees in words"""
    try:
        from num2words import num2words
        
        rupees = int(number)
        paise = int(round((number - rupees) * 100))
        
        rupees_words = num2words(rupees, lang='en_IN').title()
        
        if paise > 0:
            paise_words = num2words(paise, lang='en_IN').title()
            return f"Rupees {rupees_words} and {paise_words} Paise Only"
        
        return f"Rupees {rupees_words} Only"
    except ImportError:
        return f"Rupees {number:.2f}"


# Example usage
if __name__ == "__main__":
    # Create test transaction
    items = [
        TransactionItem(
            item_id=1,
            item_name="Laptop",
            hsn_code="84713010",
            quantity=Decimal("2"),
            rate=Decimal("50000"),
            gst_rate=Decimal("18"),
            discount_type=DiscountType.PERCENTAGE,
            discount_value=Decimal("5")
        ),
        TransactionItem(
            item_id=2,
            item_name="Mouse",
            hsn_code="84716060",
            quantity=Decimal("5"),
            rate=Decimal("500"),
            gst_rate=Decimal("18")
        )
    ]
    
    # Intra-state transaction (Maharashtra to Maharashtra)
    transaction = Transaction(
        company_state_code="27",
        party_state_code="27",
        place_of_supply="27",
        items=items
    )
    
    calculator = GSTCalculator()
    result = calculator.calculate_transaction(transaction)
    
    print("=== GST Calculation Result ===")
    print(f"GST Type: {result.gst_type.value}")
    print(f"Subtotal: ₹{result.subtotal}")
    print(f"Discount: ₹{result.total_discount}")
    print(f"Taxable: ₹{result.total_taxable}")
    print(f"CGST: ₹{result.total_cgst}")
    print(f"SGST: ₹{result.total_sgst}")
    print(f"IGST: ₹{result.total_igst}")
    print(f"Cess: ₹{result.total_cess}")
    print(f"Total Tax: ₹{result.total_tax}")
    print(f"Round Off: ₹{result.round_off}")
    print(f"Grand Total: ₹{result.grand_total}")
    print(f"\nIn Words: {number_to_words_indian(float(result.grand_total))}")
