import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShambaCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasShadow;
  final Color? borderColor;
  final double? borderRadius;

  const ShambaCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.hasShadow = true,
    this.borderColor,
    this.borderRadius,
  });

  @override
  State<ShambaCard> createState() => _ShambaCardState();
}

class _ShambaCardState extends State<ShambaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.lg;
    final card = AnimatedScale(
      scale: widget.onTap != null && _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.borderColor ?? AppColors.divider,
            width: 1,
          ),
          boxShadow: widget.hasShadow ? AppShadow.sm : null,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
