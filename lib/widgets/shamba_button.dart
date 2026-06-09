import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }

class ShambaButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final bool isSmall;

  const ShambaButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.isSmall = false,
  });

  @override
  State<ShambaButton> createState() => _ShambaButtonState();
}

class _ShambaButtonState extends State<ShambaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.isSmall ? AppTypography.minTouchTarget : 52.0;
    final fontSize = widget.isSmall ? 13.0 : 15.0;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (widget.variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.white;
        break;
      case ButtonVariant.secondary:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
      case ButtonVariant.danger:
        bg = AppColors.critical;
        fg = AppColors.white;
        break;
    }

    final enabled = widget.onPressed != null && !widget.isLoading;
    if (!enabled) {
      bg = AppColors.divider;
      fg = AppColors.textHint;
      border = null;
    }

    final child = AnimatedScale(
      scale: _pressed && enabled ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        height: height,
        width: widget.fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isSmall ? AppSpacing.md : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: border != null ? Border.fromBorderSide(border) : null,
          boxShadow: widget.variant == ButtonVariant.primary && enabled
              ? AppShadow.green
              : null,
        ),
        child: Row(
          mainAxisSize:
              widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            else if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: child,
    );
  }
}
