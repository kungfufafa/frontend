import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standardized text field component dengan validation dan styling yang konsisten
/// Menggunakan prinsip KISS untuk kemudahan penggunaan
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;
  final String? initialValue;
  final bool isRequired;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final bool filled;
  final Color? fillColor;
  
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
    this.isRequired = false,
    this.contentPadding,
    this.borderRadius = 8.0,
    this.filled = true,
    this.fillColor,
  });
  
  /// Factory constructor untuk email field
  factory AppTextField.email({
    Key? key,
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool isRequired = true,
    Function(String)? onChanged,
    String? hint,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Masukkan email',
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
  
  /// Factory constructor untuk password field
  factory AppTextField.password({
    Key? key,
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool isRequired = true,
    Function(String)? onChanged,
    String? hint,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Masukkan password',
      controller: controller,
      validator: validator,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
  
  /// Factory constructor untuk phone number field
  factory AppTextField.phone({
    Key? key,
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool isRequired = false,
    Function(String)? onChanged,
    String? hint,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Masukkan nomor telepon',
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
      ],
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
  
  /// Factory constructor untuk number field
  factory AppTextField.number({
    Key? key,
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool isRequired = false,
    Function(String)? onChanged,
    String? hint,
    bool allowDecimal = false,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Masukkan angka',
      controller: controller,
      validator: validator,
      keyboardType: allowDecimal ? 
        const TextInputType.numberWithOptions(decimal: true) : 
        TextInputType.number,
      inputFormatters: allowDecimal ? [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ] : [
        FilteringTextInputFormatter.digitsOnly,
      ],
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
  
  /// Factory constructor untuk multiline text area
  factory AppTextField.multiline({
    Key? key,
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    int maxLines = 4,
    int? maxLength,
    bool isRequired = false,
    Function(String)? onChanged,
    String? hint,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      minLines: 2,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
  
  /// Factory constructor untuk date field (read-only dengan onTap)
  factory AppTextField.date({
    Key? key,
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool isRequired = false,
    String? hint,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Pilih tanggal',
      controller: controller,
      validator: validator,
      readOnly: true,
      onTap: onTap,
      suffixIcon: const Icon(Icons.calendar_today),
      isRequired: isRequired,
    );
  }
  
  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool obscureText = false;
  
  @override
  void initState() {
    super.initState();
    obscureText = widget.obscureText;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          _buildLabel(theme),
          const SizedBox(height: 8),
        ],
        _buildTextField(theme),
      ],
    );
  }
  
  Widget _buildLabel(ThemeData theme) {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(ThemeData theme) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      textCapitalization: widget.textCapitalization,
      initialValue: widget.initialValue,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffixIcon(),
        contentPadding: widget.contentPadding ?? 
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: widget.filled,
        fillColor: widget.fillColor ?? 
          (widget.enabled ? 
            theme.colorScheme.surface : 
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
        border: _buildBorder(theme),
        enabledBorder: _buildBorder(theme),
        focusedBorder: _buildBorder(theme, isFocused: true),
        errorBorder: _buildBorder(theme, isError: true),
        focusedErrorBorder: _buildBorder(theme, isError: true, isFocused: true),
        disabledBorder: _buildBorder(theme, isDisabled: true),
        counterText: '', // Hide character counter
        errorMaxLines: 2,
      ),
    );
  }
  
  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
          size: 20,
        ),
        onPressed: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
      );
    }
    
    return widget.suffixIcon;
  }
  
  OutlineInputBorder _buildBorder(
    ThemeData theme, {
    bool isFocused = false,
    bool isError = false,
    bool isDisabled = false,
  }) {
    Color borderColor;
    double borderWidth = 1.0;
    
    if (isError) {
      borderColor = theme.colorScheme.error;
      borderWidth = 2.0;
    } else if (isFocused) {
      borderColor = theme.colorScheme.primary;
      borderWidth = 2.0;
    } else if (isDisabled) {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.5);
    } else {
      borderColor = theme.colorScheme.outline;
    }
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: borderColor,
        width: borderWidth,
      ),
    );
  }
}