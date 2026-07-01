import 'package:flutter/material.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/promotion_analytics_bloc.dart';
import '../pages/promoted_post_analytics_page.dart';
import 'campaign_detail_sheet.dart';
import 'promotion_sheet_frame.dart';

Future<void> showPromotedPostAnalyticsSheet(
  BuildContext context,
  String postId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return PersistentBlocProvider<PromotionAnalyticsBloc>(
        debugLabel: 'PromotedPostAnalyticsSheet',
        create: () => di.sl<PromotionAnalyticsBloc>()
          ..add(LoadPromotionAnalyticsEvent(postId: postId)),
        child: PromotionDetailSheetFrame(
          title: sheetContext.l10n.t('promoPostAnalytics'),
          child: PromotedPostAnalyticsBody(
            postId: postId,
            embedded: true,
            onOpenCampaign: (id) {
              Navigator.of(sheetContext).pop();
              showCampaignDetailSheet(context, id);
            },
          ),
        ),
      );
    },
  );
}
