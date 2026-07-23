import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

({Color fg, Color bg, String label}) sellerVerificationStatusStyle(
  ColorScheme scheme,
  AppLocalizations l10n,
  String status,
) {
  return switch (status.toUpperCase()) {
    'PENDING' => (
        fg: scheme.primary,
        bg: scheme.primaryContainer,
        label: l10n.tOr('pending', 'Pending'),
      ),
    'APPROVED' => (
        fg: scheme.secondary,
        bg: scheme.secondaryContainer,
        label: l10n.tOr('approved', 'Approved'),
      ),
    'REJECTED' => (
        fg: scheme.error,
        bg: scheme.errorContainer,
        label: l10n.tOr('rejected', 'Rejected'),
      ),
    'REVOKED' => (
        fg: scheme.onErrorContainer,
        bg: scheme.errorContainer.withValues(alpha: 0.7),
        label: l10n.tOr('revoked', 'Revoked'),
      ),
    _ => (
        fg: scheme.onSurfaceVariant,
        bg: scheme.surfaceContainerHigh,
        label: status,
      ),
  };
}
