import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// =============================================================================
/// MODERN TABLE WIDGET
/// A clean, enterprise-grade data table with hover effects and actions
/// =============================================================================

class ModernTableColumn {
  final String id;
  final String label;
  final double? width;
  final bool sortable;
  final TextAlign textAlign;

  const ModernTableColumn({
    required this.id,
    required this.label,
    this.width,
    this.sortable = false,
    this.textAlign = TextAlign.left,
  });
}

class ModernTable<T> extends StatefulWidget {
  final List<ModernTableColumn> columns;
  final List<T> data;
  final Widget Function(T item, ModernTableColumn column) cellBuilder;
  final void Function(T item)? onRowTap;
  final List<PopupMenuEntry<String>> Function(T item)? actionsBuilder;
  final void Function(T item, String action)? onAction;
  final bool showCheckboxes;
  final List<T> selectedItems;
  final void Function(List<T>)? onSelectionChanged;
  final bool isLoading;
  final String? emptyMessage;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending)? onSort;

  const ModernTable({
    super.key,
    required this.columns,
    required this.data,
    required this.cellBuilder,
    this.onRowTap,
    this.actionsBuilder,
    this.onAction,
    this.showCheckboxes = false,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.isLoading = false,
    this.emptyMessage,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  State<ModernTable<T>> createState() => _ModernTableState<T>();
}

class _ModernTableState<T> extends State<ModernTable<T>> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Divider
          const Divider(height: 1, color: AppColors.border),

          // Body
          Expanded(
            child: widget.isLoading
                ? _buildLoadingState()
                : widget.data.isEmpty
                    ? _buildEmptyState()
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        children: [
          if (widget.showCheckboxes) ...[
            SizedBox(
              width: 40,
              child: Checkbox(
                value: widget.data.isNotEmpty &&
                    widget.selectedItems.length == widget.data.length,
                tristate: widget.selectedItems.isNotEmpty &&
                    widget.selectedItems.length < widget.data.length,
                onChanged: (value) {
                  if (widget.onSelectionChanged != null) {
                    if (value == true) {
                      widget.onSelectionChanged!(List.from(widget.data));
                    } else {
                      widget.onSelectionChanged!([]);
                    }
                  }
                },
              ),
            ),
          ],
          ...widget.columns.map((column) {
            return Expanded(
              flex: column.width != null ? 0 : 1,
              child: SizedBox(
                width: column.width,
                child: _buildHeaderCell(column),
              ),
            );
          }),
          if (widget.actionsBuilder != null)
            const SizedBox(width: 48), // Space for actions
        ],
      ),
    );
  }

  Widget _buildHeaderCell(ModernTableColumn column) {
    final isSorted = widget.sortColumn == column.id;

    return InkWell(
      onTap: column.sortable && widget.onSort != null
          ? () {
              if (isSorted) {
                widget.onSort!(column.id, !widget.sortAscending);
              } else {
                widget.onSort!(column.id, true);
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: column.textAlign == TextAlign.right
              ? MainAxisAlignment.end
              : column.textAlign == TextAlign.center
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
          children: [
            Text(
              column.label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
                letterSpacing: 0.5,
              ),
            ),
            if (column.sortable) ...[
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (widget.sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 14,
                color: isSorted ? AppColors.primary : AppColors.slate400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      itemCount: widget.data.length,
      itemBuilder: (context, index) {
        final item = widget.data[index];
        final isSelected = widget.selectedItems.contains(item);
        final isHovered = _hoveredIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: InkWell(
            onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : isHovered
                        ? AppColors.primary.withOpacity(0.05)
                        : AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: index < widget.data.length - 1
                        ? AppColors.borderLight
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (widget.showCheckboxes) ...[
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          if (widget.onSelectionChanged != null) {
                            final newSelection = List<T>.from(widget.selectedItems);
                            if (value == true) {
                              newSelection.add(item);
                            } else {
                              newSelection.remove(item);
                            }
                            widget.onSelectionChanged!(newSelection);
                          }
                        },
                      ),
                    ),
                  ],
                  ...widget.columns.map((column) {
                    return Expanded(
                      flex: column.width != null ? 0 : 1,
                      child: SizedBox(
                        width: column.width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: widget.cellBuilder(item, column),
                        ),
                      ),
                    );
                  }),
                  if (widget.actionsBuilder != null)
                    SizedBox(
                      width: 48,
                      child: _buildActionsMenu(item),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsMenu(T item) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.slate500,
      ),
      itemBuilder: (context) => widget.actionsBuilder!(item),
      onSelected: (action) {
        if (widget.onAction != null) {
          widget.onAction!(item, action);
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 56,
              color: AppColors.slate300,
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage ?? 'No data available',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// STATUS CHIP WIDGET
/// Pill-style status indicator
/// =============================================================================

enum StatusType { success, warning, error, info, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: colors.foreground,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  ({Color background, Color foreground}) _getColors() {
    switch (type) {
      case StatusType.success:
        return (background: AppColors.successLight, foreground: AppColors.successDark);
      case StatusType.warning:
        return (background: AppColors.warningLight, foreground: AppColors.warningDark);
      case StatusType.error:
        return (background: AppColors.errorLight, foreground: AppColors.errorDark);
      case StatusType.info:
        return (background: AppColors.infoLight, foreground: AppColors.infoDark);
      case StatusType.neutral:
        return (background: AppColors.slate100, foreground: AppColors.slate600);
    }
  }
}

/// =============================================================================
/// QUANTITY INPUT WIDGET
/// Modern +/- stepper input
/// =============================================================================

class QuantityInput extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;
  final bool compact;

  const QuantityInput({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 999,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove_rounded,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: compact ? 40 : 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.slate800,
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add_rounded,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isDisabled ? AppColors.slate300 : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// MODERN CARD WIDGET
/// Consistent card styling across the app
/// =============================================================================

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// =============================================================================
/// RESPONSIVE FORM GRID
/// Auto-adjusts columns based on screen width
/// =============================================================================

class ResponsiveFormGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveFormGrid({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: (constraints.maxWidth - (spacing * (columns - 1))) / columns,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// =============================================================================
/// SECTION HEADER
/// Consistent section headers with optional action
/// =============================================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
