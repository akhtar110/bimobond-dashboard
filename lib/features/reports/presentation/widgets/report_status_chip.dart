import 'package:flutter/material.dart';

/// Compact status pill for report cards (Stripe / Linear style).
class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'PENDING' => (
          const Color(0xFFF59E0B),
          'Pending',
          Icons.schedule_rounded,
        ),
      'RESOLVED' => (
          const Color(0xFF10B981),
          'Resolved',
          Icons.check_circle_outline_rounded,
        ),
      'DISMISSED' => (
          const Color(0xFF6B7280),
          'Dismissed',
          Icons.remove_circle_outline_rounded,
        ),
      _ => (const Color(0xFF6366F1), status, Icons.flag_outlined),
    };

    return Semantics(
      label: 'Report status: $label',
      child: Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
