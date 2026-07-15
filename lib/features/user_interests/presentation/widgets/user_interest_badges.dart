import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_interest_entities.dart';

class UserInterestPreferenceBadge extends StatelessWidget {
  const UserInterestPreferenceBadge({
    super.key,
    required this.preference,
    this.compact = false,
  });

  final UserInterestPreference preference;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isInterested = preference == UserInterestPreference.interested;
    final accent = isInterested ? scheme.primary : scheme.error;
    final label = isInterested
        ? l10n.tOr('userInterestInterested', 'Interested')
        : l10n.tOr('userInterestNotInterested', 'Not Interested');

    return _BadgeChip(
      label: label,
      accent: accent,
      compact: compact,
    );
  }
}

class UserInterestSourceBadge extends StatelessWidget {
  const UserInterestSourceBadge({
    super.key,
    required this.source,
    this.compact = false,
  });

  final UserInterestSource source;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final (label, accent) = switch (source) {
      UserInterestSource.onboarding => (
          l10n.tOr('userInterestSourceOnboarding', 'Onboarding'),
          scheme.primary,
        ),
      UserInterestSource.manual => (
          l10n.tOr('userInterestSourceManual', 'Manual'),
          scheme.secondary,
        ),
      UserInterestSource.like => (
          l10n.tOr('userInterestSourceLike', 'Learned from Like'),
          scheme.tertiary,
        ),
      UserInterestSource.comment => (
          l10n.tOr('userInterestSourceComment', 'Learned from Comment'),
          scheme.error,
        ),
      UserInterestSource.unknown => (
          l10n.tOr('userInterestSourceManual', 'Manual'),
          scheme.onSurfaceVariant,
        ),
    };

    return _BadgeChip(label: label, accent: accent, compact: compact);
  }
}

class UserInterestStatusBadge extends StatelessWidget {
  const UserInterestStatusBadge({
    super.key,
    required this.isActive,
    this.compact = false,
  });

  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return _BadgeChip(
      label: isActive
          ? l10n.tOr('active', 'Active')
          : l10n.tOr('inactive', 'Inactive'),
      accent: isActive ? scheme.tertiary : scheme.onSurfaceVariant,
      compact: compact,
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.accent,
    this.compact = false,
  });

  final String label;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
