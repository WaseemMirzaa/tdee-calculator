import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// The single primary action per screen: an emerald→lime gradient pill.
class VitaPrimaryButton extends StatelessWidget {
  const VitaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final enabled = onPressed != null && !loading;
    final child = AnimatedOpacity(
      duration: VitaMotion.fast,
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VitaRadius.pill),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: v.brandGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: v.brand.withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                ],
              ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(VitaRadius.pill),
          onTap: enabled ? onPressed : null,
          child: expand ? SizedBox(width: double.infinity, child: child) : child,
        ),
      ),
    );
  }
}

/// Secondary action: a bordered ghost pill.
class VitaGhostButton extends StatelessWidget {
  const VitaGhostButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(VitaRadius.pill),
        onTap: onPressed,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VitaRadius.pill),
            border: Border.all(color: v.line, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 19, color: v.ink), const SizedBox(width: 9)],
              Text(label, style: TextStyle(color: v.ink, fontSize: 15.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular icon button used for back / floating actions.
class VitaCircleButton extends StatelessWidget {
  const VitaCircleButton({super.key, required this.icon, required this.onPressed, this.filled = false});
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Material(
      color: filled ? v.ink : v.card,
      shape: CircleBorder(side: BorderSide(color: v.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 46, height: 46,
          child: Icon(icon, size: 20, color: filled ? v.card : v.ink),
        ),
      ),
    );
  }
}
