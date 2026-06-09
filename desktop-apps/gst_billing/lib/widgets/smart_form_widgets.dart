/// Smart Form Widgets - "Easy-to-Use" UX Components
/// BillEase Accounts+ - Desktop-optimized form controls
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Stepper Input Widget for Quantity/Price fields
/// Layout: [-] [Input] [+]
class StepperInput extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final String? label;
  final String? suffix;
  final int decimals;
  final ValueChanged<double>? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const StepperInput({
    super.key,
    required this.value,
    this.min = 0,
    this.max = double.infinity,
    this.step = 1,
    this.label,
    this.suffix,
    this.decimals = 0,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<StepperInput> createState() => _StepperInputState();
}

class _StepperInputState extends State<StepperInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(StepperInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.decimals == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(widget.decimals);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Parse and validate on blur
      _parseAndUpdate(_controller.text);
    }
  }

  void _parseAndUpdate(String text) {
    final parsed = double.tryParse(text) ?? widget.value;
    final clamped = parsed.clamp(widget.min, widget.max);
    _controller.text = _formatValue(clamped);
    if (clamped != widget.value) {
      widget.onChanged?.call(clamped);
    }
  }

  void _increment() {
    final newValue = (widget.value + widget.step).clamp(widget.min, widget.max);
    _controller.text = _formatValue(newValue);
    widget.onChanged?.call(newValue);
  }

  void _decrement() {
    final newValue = (widget.value - widget.step).clamp(widget.min, widget.max);
    _controller.text = _formatValue(newValue);
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.slate300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement Button
              _StepperButton(
                icon: Icons.remove,
                onPressed: widget.enabled && widget.value > widget.min 
                    ? _decrement 
                    : null,
                isLeft: true,
              ),
              
              // Input Field
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.decimals > 0,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(widget.decimals > 0 ? r'[\d.]' : r'\d'),
                    ),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    suffixText: widget.suffix,
                    suffixStyle: const TextStyle(
                      color: AppTheme.slate400,
                      fontSize: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate800,
                  ),
                  onSubmitted: _parseAndUpdate,
                ),
              ),
              
              // Increment Button
              _StepperButton(
                icon: Icons.add,
                onPressed: widget.enabled && widget.value < widget.max 
                    ? _increment 
                    : null,
                isLeft: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stepper Button (+ or -)
class _StepperButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLeft;

  const _StepperButton({
    required this.icon,
    this.onPressed,
    required this.isLeft,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? AppTheme.slate100
                : _isHovered
                    ? AppTheme.primaryLight
                    : AppTheme.slate100,
            borderRadius: BorderRadius.only(
              topLeft: widget.isLeft ? const Radius.circular(7) : Radius.zero,
              bottomLeft: widget.isLeft ? const Radius.circular(7) : Radius.zero,
              topRight: !widget.isLeft ? const Radius.circular(7) : Radius.zero,
              bottomRight: !widget.isLeft ? const Radius.circular(7) : Radius.zero,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.onPressed == null
                ? AppTheme.slate300
                : _isHovered
                    ? AppTheme.primaryColor
                    : AppTheme.slate600,
          ),
        ),
      ),
    );
  }
}

/// Pill Search Bar - Large, rounded search input
class PillSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double width;

  const PillSearchBar({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.slate400),
          filled: true,
          fillColor: AppTheme.slate100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          hintStyle: const TextStyle(color: AppTheme.slate400, fontSize: 14),
        ),
        style: const TextStyle(fontSize: 14, color: AppTheme.slate800),
      ),
    );
  }
}

/// Smart Form Field with Enter to next field and Esc to close modal
class SmartFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final bool autofocus;

  const SmartFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.slate600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          obscureText: obscureText,
          maxLines: maxLines,
          autofocus: autofocus,
          textInputAction: nextFocusNode != null 
              ? TextInputAction.next 
              : TextInputAction.done,
          onFieldSubmitted: (_) {
            // Enter moves to next field
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Keyboard-aware Modal wrapper - Esc closes modal
class KeyboardModal extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final double? width;
  final double? maxHeight;

  const KeyboardModal({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.width,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        // Esc closes modal
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: width ?? 400,
          constraints: BoxConstraints(
            maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close (Esc)',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!
                        .expand((w) => [w, const SizedBox(width: 12)])
                        .toList()
                      ..removeLast(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Data Table with Hover Highlighting and Action Buttons
class HoverDataTable<T> extends StatelessWidget {
  final List<DataColumn> columns;
  final List<T> data;
  final DataRow Function(T item, int index, bool isHovered) rowBuilder;
  final bool showCheckboxColumn;

  const HoverDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.rowBuilder,
    this.showCheckboxColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: columns,
      showCheckboxColumn: showCheckboxColumn,
      headingRowColor: WidgetStateProperty.all(AppTheme.slate100),
      dataRowMaxHeight: 56,
      rows: List.generate(data.length, (index) {
        return _HoverableRow(
          item: data[index],
          index: index,
          rowBuilder: rowBuilder,
        ).build();
      }),
    );
  }
}

class _HoverableRow<T> {
  final T item;
  final int index;
  final DataRow Function(T item, int index, bool isHovered) rowBuilder;
  
  _HoverableRow({
    required this.item,
    required this.index,
    required this.rowBuilder,
  });
  
  DataRow build() {
    // Note: For hover highlighting, wrap in StatefulWidget
    // This is a simplified version - actual hover needs StatefulWidget
    return rowBuilder(item, index, false);
  }
}

/// Action Button for table rows
class TableActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const TableActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  State<TableActionButton> createState() => _TableActionButtonState();
}

class _TableActionButtonState extends State<TableActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.slate500;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isHovered ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered ? color : AppTheme.slate400,
            ),
          ),
        ),
      ),
    );
  }
}
