import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final double elevation;
  final Border? border;
  
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.elevation = 0,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: border ?? Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: elevation > 0 ? [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05 * elevation),
            blurRadius: 10 * elevation,
            offset: Offset(0, 2 * elevation),
          ),
        ] : null,
      ),
      child: child,
    );
    
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: cardContent,
        ),
      );
    }
    
    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }
    
    return cardContent;
  }
}
