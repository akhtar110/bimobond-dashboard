import '../../../../core/localization/localization.dart';

/// Human-readable labels for Moderation status/type filters.
abstract final class ModerationFilterLabels {
  ModerationFilterLabels._();

  static String allStatus(AppLocalizations l10n) =>
      l10n.tOr('allStatus', 'All Status');

  static String allTypes(AppLocalizations l10n) =>
      l10n.tOr('allTypes', 'All Types');

  static String reportTypePost(AppLocalizations l10n) =>
      l10n.tOr('reportTypePost', 'Post');

  static String reportTypeUser(AppLocalizations l10n) =>
      l10n.tOr('reportTypeUser', 'User');

  static String reportTypeComment(AppLocalizations l10n) =>
      l10n.tOr('reportTypeComment', 'Comment');

  static String pending(AppLocalizations l10n) =>
      l10n.tOr('pending', 'Pending');

  static String resolved(AppLocalizations l10n) =>
      l10n.tOr('resolved', 'Resolved');

  static String dismissed(AppLocalizations l10n) =>
      l10n.tOr('dismissed', 'Dismissed');

  static List<({String label, String? value})> statusOptions(
    AppLocalizations l10n,
  ) =>
      [
        (label: allStatus(l10n), value: null),
        (label: pending(l10n), value: 'PENDING'),
        (label: resolved(l10n), value: 'RESOLVED'),
        (label: dismissed(l10n), value: 'DISMISSED'),
      ];

  static List<({String label, String? value})> typeOptions(
    AppLocalizations l10n,
  ) =>
      [
        (label: allTypes(l10n), value: null),
        (label: reportTypePost(l10n), value: 'post'),
        (label: reportTypeUser(l10n), value: 'user'),
        (label: reportTypeComment(l10n), value: 'comment'),
      ];
}
