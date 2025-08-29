import 'package:flutter/material.dart';

/// Standardized button component dengan loading state dan styling yang konsisten
/// Menggunakan prinsip KISS untuk kemudahan penggunaan
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isExpanded;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 8.0,
    this.isExpanded = false,
  });
  
  /// Factory constructor untuk primary button
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
    bool isExpanded = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.primary,
      icon: icon,
      width: width,
      height: height,
      isExpanded: isExpanded,
    );
  }
  
  /// Factory constructor untuk secondary button
  factory AppButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
    bool isExpanded = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.secondary,
      icon: icon,
      width: width,
      height: height,
      isExpanded: isExpanded,
    );
  }
  
  /// Factory constructor untuk danger/delete button
  factory AppButton.danger({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
    bool isExpanded = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.danger,
      icon: icon,
      width: width,
      height: height,
      isExpanded: isExpanded,
    );
  }
  
  /// Factory constructor untuk outline button
  factory AppButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
    bool isExpanded = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.outline,
      icon: icon,
      width: width,
      height: height,
      isExpanded: isExpanded,
    );
  }
  
  /// Factory constructor untuk text button
  factory AppButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
    bool isExpanded = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.text,
      icon: icon,
      width: width,
      height: height,
      isExpanded: isExpanded,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;
    
    Widget button = _buildButton(context, theme, isDisabled);
    
    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    } else if (width != null) {
      button = SizedBox(
        width: width,
        child: button,
      );
    }
    
    if (height != null) {
      button = SizedBox(
        height: height,
        child: button,
      );
    }
    
    return button;
  }
  
  Widget _buildButton(BuildContext context, ThemeData theme, bool isDisabled) {
    final buttonStyle = _getButtonStyle(theme);
    final child = _buildButtonChild();
    
    switch (type) {
      case ButtonType.primary:
      case ButtonType.danger:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
      case ButtonType.secondary:
      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
    }
  }
  
  Widget _buildButtonChild() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    return Text(text);
  }
  
  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseStyle = ButtonStyle(
      padding: WidgetStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
    
    switch (type) {
      case ButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.primary.withValues(alpha: 0.5);
              }
              return theme.colorScheme.primary;
            },
          ),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
        );
        
      case ButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.surface;
              }
              return theme.colorScheme.secondary;
            },
          ),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSecondary),
        );
        
      case ButtonType.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.error.withValues(alpha: 0.5);
              }
              return theme.colorScheme.error;
            },
          ),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onError),
        );
        
      case ButtonType.outline:
        return baseStyle.copyWith(
          side: WidgetStateProperty.resolveWith<BorderSide>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5));
              }
              return BorderSide(color: theme.colorScheme.outline);
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onSurface.withValues(alpha: 0.5);
              }
              return theme.colorScheme.primary;
            },
          ),
        );
        
      case ButtonType.text:
        return baseStyle.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onSurface.withValues(alpha: 0.5);
              }
              return theme.colorScheme.primary;
            },
          ),
        );
    }
  }
}

/// Enum untuk tipe button
enum ButtonType {
  primary,
  secondary,
  danger,
  outline,
  text,
}