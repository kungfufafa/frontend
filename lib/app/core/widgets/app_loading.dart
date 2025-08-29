import 'package:flutter/material.dart';

/// Standardized loading widget dengan berbagai style dan opsi kustomisasi
/// Menggunakan prinsip KISS untuk kemudahan penggunaan
class AppLoading extends StatelessWidget {
  final String? message;
  final bool showBackdrop;
  final Color? backdropColor;
  final Color? indicatorColor;
  final double size;
  final double strokeWidth;
  final LoadingType type;
  final MainAxisAlignment alignment;
  final bool isFullScreen;
  
  const AppLoading({
    super.key,
    this.message,
    this.showBackdrop = false,
    this.backdropColor,
    this.indicatorColor,
    this.size = 32.0,
    this.strokeWidth = 3.0,
    this.type = LoadingType.circular,
    this.alignment = MainAxisAlignment.center,
    this.isFullScreen = false,
  });
  
  /// Factory constructor untuk full screen loading
  factory AppLoading.fullScreen({
    Key? key,
    String? message,
    Color? backdropColor,
    Color? indicatorColor,
    LoadingType type = LoadingType.circular,
  }) {
    return AppLoading(
      key: key,
      message: message,
      showBackdrop: true,
      backdropColor: backdropColor,
      indicatorColor: indicatorColor,
      type: type,
      isFullScreen: true,
    );
  }
  
  /// Factory constructor untuk inline loading (tanpa backdrop)
  factory AppLoading.inline({
    Key? key,
    String? message,
    Color? indicatorColor,
    double size = 24.0,
    LoadingType type = LoadingType.circular,
  }) {
    return AppLoading(
      key: key,
      message: message,
      showBackdrop: false,
      indicatorColor: indicatorColor,
      size: size,
      type: type,
    );
  }
  
  /// Factory constructor untuk small loading indicator
  factory AppLoading.small({
    Key? key,
    Color? indicatorColor,
    LoadingType type = LoadingType.circular,
  }) {
    return AppLoading(
      key: key,
      indicatorColor: indicatorColor,
      size: 16.0,
      strokeWidth: 2.0,
      type: type,
    );
  }
  
  /// Factory constructor untuk button loading
  factory AppLoading.button({
    Key? key,
    Color? indicatorColor,
  }) {
    return AppLoading(
      key: key,
      indicatorColor: indicatorColor ?? Colors.white,
      size: 16.0,
      strokeWidth: 2.0,
      type: LoadingType.circular,
    );
  }
  
  /// Factory constructor untuk shimmer loading effect
  factory AppLoading.shimmer({
    Key? key,
    double? width,
    double? height,
  }) {
    return AppLoading(
      key: key,
      type: LoadingType.shimmer,
      size: height ?? 20.0,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = _buildLoadingContent(theme);
    
    if (showBackdrop) {
      content = Container(
        color: backdropColor ?? Colors.black54,
        child: Center(child: content),
      );
    }
    
    if (isFullScreen) {
      return Positioned.fill(child: content);
    }
    
    return content;
  }
  
  Widget _buildLoadingContent(ThemeData theme) {
    final List<Widget> children = [];
    
    // Add loading indicator
    children.add(_buildLoadingIndicator(theme));
    
    // Add message if provided
    if (message != null && message!.isNotEmpty) {
      children.add(const SizedBox(height: 16));
      children.add(_buildLoadingMessage(theme));
    }
    
    return Column(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
  
  Widget _buildLoadingIndicator(ThemeData theme) {
    final color = indicatorColor ?? theme.colorScheme.primary;
    
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
        
      case LoadingType.linear:
        return SizedBox(
          width: size * 3, // Make linear indicator wider
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        );
        
      case LoadingType.dots:
        return _buildDotsIndicator(color);
        
      case LoadingType.shimmer:
        return _buildShimmerIndicator(theme);
        
      case LoadingType.pulse:
        return _buildPulseIndicator(color);
    }
  }
  
  Widget _buildLoadingMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: showBackdrop ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: showBackdrop ? 
            theme.colorScheme.onSurface : 
            theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildDotsIndicator(Color color) {
    return SizedBox(
      width: size,
      height: size / 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _AnimatedDot(
            color: color,
            size: size / 6,
            delay: Duration(milliseconds: index * 200),
          );
        }),
      ),
    );
  }
  
  Widget _buildShimmerIndicator(ThemeData theme) {
    return Container(
      width: size * 4,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: _ShimmerEffect(
        baseColor: theme.colorScheme.surfaceContainerHighest,
        highlightColor: theme.colorScheme.surface,
      ),
    );
  }
  
  Widget _buildPulseIndicator(Color color) {
    return _PulseIndicator(
      color: color,
      size: size,
    );
  }
}

/// Enum untuk tipe loading indicator
enum LoadingType {
  circular,
  linear,
  dots,
  shimmer,
  pulse,
}

/// Widget untuk animated dot
class _AnimatedDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration delay;
  
  const _AnimatedDot({
    required this.color,
    required this.size,
    required this.delay,
  });
  
  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Widget untuk shimmer effect
class _ShimmerEffect extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;
  
  const _ShimmerEffect({
    required this.baseColor,
    required this.highlightColor,
  });
  
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Widget untuk pulse indicator
class _PulseIndicator extends StatefulWidget {
  final Color color;
  final double size;
  
  const _PulseIndicator({
    required this.color,
    required this.size,
  });
  
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}