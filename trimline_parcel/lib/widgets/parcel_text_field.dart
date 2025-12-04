import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// A reusable text field widget with consistent styling and validation
class ParcelTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final TextInputType keyboardType;
  final bool readOnly;
  final InputDecoration? decoration;
  final IconData? prefixIcon;
  final RxString? error;
  final FocusNode? focusNode;
  final VoidCallback? onNextStep;
  final FocusNode? nextFocus;
  final String? Function(String?)? customValidator;
  final String? helperText;
  final List<TextInputFormatter>? inputFormatters;

  const ParcelTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.decoration,
    this.prefixIcon,
    this.error,
    this.focusNode,
    this.onNextStep,
    this.nextFocus,
    this.customValidator,
    this.helperText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final bool showError = (error?.value.isNotEmpty ?? false);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.black.withOpacity(0.18)),
    );

    // Choose an appropriate action for the keyboard. For multiline fields allow newline,
    // otherwise provide a 'next' action so Enter/Done moves focus to the next field.
    final textInputAction = keyboardType == TextInputType.multiline
        ? TextInputAction.newline
        : TextInputAction.next;

    return TextFormField(
      controller: controller,
      // Avoid automatic scroll padding/scroll animation when focusing the field.
      // This reduces the scroll/animate behavior when the keyboard opens.
      scrollPadding: EdgeInsets.zero,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      cursorColor: Colors.black,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        filled: true,
        fillColor: Colors.black.withOpacity(0.07),
        labelText: label,
        labelStyle: TextStyle(
          // Only show red when the field-specific error is set; otherwise use neutral color
          color: showError ? Colors.redAccent : Colors.black54,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.black54)
            : decoration?.prefixIcon,
        suffixIcon: isRequired
            ? const Icon(
                Icons.star_rounded,
                size: 16,
                color: Colors.redAccent,
              )
            : decoration?.suffixIcon,
        helperText: helperText,
        helperStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
        enabledBorder: baseBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4FB5FF)),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorText: showError ? error?.value : null,
      ),
      onFieldSubmitted: (_) {
        if (readOnly) return;
        // If a specific next focus is provided, focus it; otherwise fall back to default traversal
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).nextFocus();
        }
        onNextStep?.call();
      },
      validator: customValidator,
    );
  }
}
