import 'package:flutter/material.dart';

// App Colors - Premium Color Scheme
class AppColors {
  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  
  static const secondary = Color(0xFF10B981); // Emerald
  static const secondaryDark = Color(0xFF059669);
  static const secondaryLight = Color(0xFF34D399);
  
  static const accent = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF3B82F6);
  
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFF1F2937);
  
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFE5E7EB);
  
  static const cardShadow = Color(0x1A000000);
}

// Premium Button
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final Color? color;
  final double? width;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary
            ? LinearGradient(
                colors: [color ?? AppColors.primary, color ?? AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: !isPrimary ? AppColors.surface : null,
        border: !isPrimary ? Border.all(color: AppColors.border) : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        isPrimary ? Colors.white : AppColors.primary,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isPrimary ? Colors.white : AppColors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Premium Card
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Premium Input Field
class PremiumInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  const PremiumInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textSecondary)
                  : null,
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Product Card
class ProductCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double price;
  final int stock;
  final String? category;
  final VoidCallback onTap;
  final bool isLowStock;

  const ProductCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.stock,
    this.category,
    required this.onTap,
    this.isLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Center(
                    child: Icon(
                      Icons.shopping_bag,
                      size: 40,
                      color: AppColors.textLight,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          
          // Category Badge
          if (category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Product Name
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Price and Stock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Stock: $stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLowStock ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Cart Item Card
class CartItemCard extends StatelessWidget {
  final String productName;
  final double price;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Row(
            children: [
              IconButton(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.error,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.success,
              ),
            ],
          ),
          
          // Remove Button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

// Status Badge
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              PremiumButton(
                text: actionText!,
                onPressed: onAction,
                isPrimary: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Loading Shimmer
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}
