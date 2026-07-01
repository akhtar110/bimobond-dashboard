import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';

/// Localized copy for auction detail progress and related KPI labels.
abstract final class AuctionDetailLabels {
  static String progressTitle(AppLocalizations l10n) =>
      l10n.tOr('auctionProgress', ReportDetailLabels.auctionProgress(l10n));

  static String raised(AppLocalizations l10n) =>
      l10n.tOr('auctionRaised', ReportDetailLabels.raised(l10n));

  static String remaining(AppLocalizations l10n, BuildContext context) =>
      l10n.tOr(
        'auctionRemaining',
        context.isRtl ? 'المتبقي' : 'Remaining',
      );

  static String goal(AppLocalizations l10n) =>
      l10n.tOr('auctionGoal', ReportDetailLabels.target(l10n));

  static String latestGift(AppLocalizations l10n, String name) {
    final template = l10n.tOr('auctionLatestGift', 'Latest: {name}');
    return template.replaceAll('{name}', name);
  }
}
