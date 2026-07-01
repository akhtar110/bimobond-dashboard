import 'package:flutter/material.dart';

class DashboardStatusChip extends StatelessWidget {
  const DashboardStatusChip({
    super.key,
    required this.label,
    this.tone = DashboardStatusTone.neutral,
  });

  final String label;
  final DashboardStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      DashboardStatusTone.success => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      DashboardStatusTone.warning => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      DashboardStatusTone.danger => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      DashboardStatusTone.neutral => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

enum DashboardStatusTone { success, warning, danger, neutral }
