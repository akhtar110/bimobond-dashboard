import 'package:flutter/material.dart';

/// A prominent online/offline status point badge (green if online, grey if offline).
class UserOnlinePointIndicator extends StatelessWidget {
  const UserOnlinePointIndicator({
    super.key,
    required this.isOnline,
    this.size = 11.0,
    this.borderWidth = 2.0,
    this.borderColor,
  });

  final bool isOnline;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveBorderColor = borderColor ?? scheme.surface;
    final dotColor = isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
