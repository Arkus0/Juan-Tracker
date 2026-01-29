// ============================================================================
// APP INPUT - Componentes de input reutilizables
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          autofocus: autofocus,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
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

/// Input numérico especializado para pesos, reps, etc.
class AppNumberInput extends StatefulWidget {
  final String? label;
  final double? initialValue;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onSubmitted;
  final String? suffix;
  final double min;
  final double max;
  final int decimalPlaces;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppNumberInput({
    super.key,
    this.label,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.min = 0,
    this.max = 9999,
    this.decimalPlaces = 1,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppNumberInput> createState() => _AppNumberInputState();
}

class _AppNumberInputState extends State<AppNumberInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(widget.decimalPlaces) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(String value) {
    if (value.isEmpty) return;
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number != null) {
      final clamped = number.clamp(widget.min, widget.max);
      widget.onChanged?.call(clamped);
    }
  }

  void _handleSubmit(String value) {
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number != null) {
      widget.onSubmitted?.call(number);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimalPlaces > 0,
      ),
      onChanged: _handleChange,
      onSubmitted: _handleSubmit,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      suffix: widget.suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(
                widget.suffix!,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : null,
    );
  }
}

/// Selector de opciones tipo chip
class AppChoiceChips<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;

  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(labelBuilder(option)),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

/// Barra de búsqueda
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint ?? 'Buscar...',
        prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}
